# Terraform Deployment of Flask and Express Applications on AWS

## Overview

You are required to deploy a **Flask backend** and an **Express frontend** application using **AWS** and **Terraform**.  
Follow the steps below to deploy the applications in different configurations.

---

## Part 1: Deploy Both Flask and Express on a Single EC2 Instance

### Objective
Deploy both the Flask backend and the Express frontend on a single EC2 instance using Terraform.

### Steps
1. Provision the EC2 instance with Terraform.
2. Configure the instance with:
   - A user data script or configuration management tool (e.g., Ansible or Cloud-Init) to install dependencies (Python, Node.js).
   - Scripts to start the Flask backend and the Express frontend.
3. Ensure both applications are running on different ports (e.g., Flask on port `5000` and Express on port `3000`).

### Expected Deliverables
- Terraform configuration files (`main.tf`, `variables.tf`, etc.).
- A working EC2 instance with Flask and Express running and accessible via the instance’s public IP.

### Implementation Details
For this Part-1, I have used the same frontend and backend files from form submission and created a folder named **`tf`**.  
In that folder:
- `main.tf` includes provider details and EC2 instance creation along with security group configuration and port access.
- `user_data.sh` includes commands to:
  - Install dependencies.
  - Clone the GitHub repository containing the frontend and backend code.
  - Create a Python virtual environment and install `requirements.txt`.
  - Create and enable system services for backend and frontend to run in the background.
- `outputs.tf` provides the access URL and instance IP address.

Finally, I ran the following command:

```bash
terraform apply
Access Link:
👉 http://3.111.57.104:3000/


Part 2: Deploy Flask and Express on Separate EC2 Instances
Objective

Deploy the Flask backend and the Express frontend on two separate EC2 instances using Terraform.

Steps

Provision two EC2 instances using Terraform:

One for Flask backend.

One for Express frontend.

Configure security groups to:

Allow communication between the two instances.

Expose both applications to the internet on their respective ports.

Define networking resources such as VPC, subnets, and route tables.

Use user data scripts to automate installation and startup of both applications.

Expected Deliverables

Terraform configuration files.

Two working EC2 instances: one running Flask and one running Express.

Properly configured security groups and networking.

Implementation Details

For this Part-2, I reused the same frontend and backend files and created:

main.tf with:

Provider details.

EC2 instance creation for backend and frontend.

VPC, subnet, internet gateway, and route table resources.

Security groups for frontend and backend with appropriate port access.

Two user data scripts:

user_data_backend.sh – installs dependencies, sets up Python virtual environment, installs requirements, and runs Flask as a background service.

user_data_frontend.sh – installs dependencies, sets up the frontend, and runs it as a background service.

In main.tf, the backend’s private IP and URL are passed to the frontend using Terraform variables.

In backend security group inbound rules, port 5000 access is restricted to the frontend subnet.

Finally, executed:

terraform apply

Access Link:
👉 http://65.0.94.244:3000/

Part 3: Deploy Flask and Express Using Docker and AWS Services
Objective

Deploy Flask and Express as Docker containers using AWS ECR, ECS, and VPC with Terraform.

Steps
1. ECR

Create two Elastic Container Registry (ECR) repositories using Terraform (one for Flask and one for Express).

Build Docker images for both applications and push them to their respective repositories.

2. VPC

Create a VPC with subnets, route tables, and security groups using Terraform.

3. ECS

Create an ECS cluster using Terraform.

Define two ECS services:

Flask backend service.

Express frontend service.

Use ECS Fargate or EC2 launch type for deployment.

4. Load Balancer

Provision an Application Load Balancer (ALB) using Terraform.

Configure ALB listeners to route requests to the correct ECS service.

Expected Deliverables

Terraform configuration files for ECR, ECS, VPC, and ALB setup.

Docker images pushed to ECR.

ECS services running and accessible via ALB DNS.

Implementation Details

For Part-3:

Built and pushed Docker images to ECR repositories.

Imported the ECR repositories into Terraform state for use in main.tf.

Created main.tf containing:

ECR repositories

ECS cluster

VPC setup

Target groups (frontend & backend)

Subnets

Task definitions

ECS services for frontend and backend

Application Load Balancer (ALB)

ALB listeners

IAM role with ECS task execution policy

Used variables.tf for configurable parameters.

Used outputs.tf to display the ALB DNS name.

Accessing the ALB DNS name provides the running application, with:

ALB forwarding port 80 → 3000 for frontend.

ALB forwarding port 80 → 5000 for backend.

Access Link:
👉 http://multi-tier-alb-tf-279949273.ap-south-1.elb.amazonaws.com/

terraform plan
terraform apply

