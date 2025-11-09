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
  access_key = var.access_key
  secret_key = var.secret_key
}


# Create a security group to allow access to the EC2 instance
resource "aws_security_group" "app_sg" {
  name_prefix = "form-sg-"

  # Allow SSH access
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to Express Frontend (Port 3000)
  ingress {
    from_port   = var.access_port
    to_port     = var.access_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to Flask Backend (Port 5000) - For direct testing
  ingress {
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# creating an ec2 instance
resource "aws_instance" "Ec2" {
  ami           = "ami-02b8269d5e85954ef"
  instance_type = "t3.micro"
  key_name      = "course-alluri-tutedude"
  security_groups = [aws_security_group.app_sg.name]
  user_data = templatefile("${path.module}/user_data.sh", {
    # Flask app will run on 0.0.0.0:5000
    # Express app will run on 0.0.0.0:3000 (and proxy to Flask)
  })

  tags = {
    Name = "form-Server"
  }

}


