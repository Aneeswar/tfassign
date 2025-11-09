terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  # Assuming var.access_key and var.secret_key are defined in variables.tf
  access_key = var.access_key
  secret_key = var.secret_key
}


# --- 1. ELASTIC CONTAINER REGISTRY (ECR) ---
resource "aws_ecr_repository" "backend" {
  name                 = "flask-backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "frontend" {
  name                 = "express-frontend"
  image_tag_mutability = "MUTABLE"
}

# --- 2. VPC AND NETWORKING ---
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "ECS-MultiTier-VPC" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# --- 3. SECURITY GROUPS (SG) ---

# SG for the Load Balancer (Public Access)
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg-tf"
  vpc_id = aws_vpc.main.id
  ingress {
    protocol    = "tcp"
    from_port   = var.alb_port
    to_port     = var.alb_port
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG for the ECS Services (Internal Access)
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg-tf"
  vpc_id = aws_vpc.main.id
  # Allow traffic from the ALB
  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535 # Allows all ports to be hit by the ALB
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    description     = "Allow ALB access to frontend service on port 3000"
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow ALB access to backend service on port 5000"
    protocol        = "tcp"
    from_port       = 5000
    to_port         = 5000
    security_groups = [aws_security_group.alb_sg.id]
  }
  # Allow egress for ECR pull, backend-frontend communication, and internet
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 4. ECS CLUSTER AND ROLES ---
resource "aws_ecs_cluster" "main" {
  name = "form-cluster-tf"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 5. APPLICATION LOAD BALANCER (ALB) ---
resource "aws_lb" "main" {
  name               = "multi-tier-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# Target Group for Frontend Service
resource "aws_lb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate

  health_check {
    path     = "/"
    protocol = "HTTP"
  }
}

# Target Group for Backend Service
resource "aws_lb_target_group" "backend" {
  name        = "backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path     = "/health" # Assume Flask has a health check route
    protocol = "HTTP"
  }
}

# ALB Listener (Listens on port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ALB Listener Rule (Routes /api traffic to the backend)
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# --- 6. ECS TASK DEFINITIONS (FARGATE) ---
locals {
  backend_image  = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.backend.name}:latest"
  frontend_image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.frontend.name}:latest"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "flask-backend"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "flask-backend"
      image     = local.backend_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        containerPort = var.backend_port
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/flask-backend"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

    }
  ])

  depends_on = [aws_cloudwatch_log_group.frontend]
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "express-frontend"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "express-frontend"
      image     = local.frontend_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        containerPort = var.frontend_port
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/express-frontend"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  # ✅ This belongs here (Terraform meta-argument)
  depends_on = [aws_cloudwatch_log_group.frontend]
}


resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/flask-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/express-frontend"
  retention_in_days = 7
}


# --- 7. ECS SERVICES (Deployment) ---
resource "aws_ecs_service" "backend" {
  name            = "flask-backend"
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "flask-backend"
    container_port   = var.backend_port
  }

  depends_on = [
    aws_lb_listener_rule.backend_rule,
    aws_iam_role_policy_attachment.ecs_task_execution_policy
  ]
}

resource "aws_ecs_service" "frontend" {
  name            = "express-frontend"
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "express-frontend"
    container_port   = var.frontend_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution_policy
  ]
}

