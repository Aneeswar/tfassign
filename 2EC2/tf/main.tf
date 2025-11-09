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
  region     = "ap-south-1"
  # Assuming var.access_key and var.secret_key are defined in variables.tf
  access_key = var.access_key 
  secret_key = var.secret_key
}

# Data source for latest AMI (Recommended)
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# --- VPC and Subnet (Basic Setup) ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "form-VPC" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  # FIX: Use a specific availability zone name
  availability_zone       = "ap-south-1a" 
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "form-IGW" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "form-RT" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.rt.id
}



# Backend Security Group (SG)
resource "aws_security_group" "backend_sg" {
  name_prefix = "backend-sg-"
  vpc_id = aws_vpc.main.id

  # Allow SSH (from anywhere)
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow traffic on port 5000 ONLY from the Frontend instance's Security Group
  ingress {
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    description     = "Allow traffic from Frontend SG"
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Frontend Security Group (SG)
resource "aws_security_group" "frontend_sg" {
  name_prefix = "frontend-sg-"
  vpc_id = aws_vpc.main.id
  
  # Allow SSH (from anywhere)
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow public access to the Express Frontend (Port 3000)
  ingress {
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Backend Instance (Flask) ---
resource "aws_instance" "backend" {
  ami           = data.aws_ami.ubuntu.id # FIX: Use data source
  instance_type = "t3.micro"
  key_name      = "course-alluri-tutedude"
  subnet_id     = aws_subnet.public_a.id
  
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  
  user_data = file("${path.module}/user_data_backend.sh")

  tags = {
    Name = "Flask-Backend"
  }
}

# --- Frontend Instance (Express) ---
resource "aws_instance" "frontend" {
  ami           = data.aws_ami.ubuntu.id # FIX: Use data source
  instance_type = "t3.micro"
  key_name      = "course-alluri-tutedude"
  # FIX: Add subnet_id for a Public IP
  subnet_id     = aws_subnet.public_a.id 
  
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  
  user_data = templatefile("${path.module}/user_data_frontend.sh", {
    backend_ip = aws_instance.backend.private_ip
    backend_port = var.backend_port
  })

  tags = {
    Name = "Express-Frontend"
  }

}