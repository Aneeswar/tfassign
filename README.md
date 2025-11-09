# Terraform Deployment of Flask and Express Applications on AWS

## Part 1: Deploy Both Flask and Express on a Single EC2 Instance

### Objective
Deploy both the Flask backend and the Express frontend on a single EC2 instance using Terraform.

### Steps
1. Provision the EC2 instance with Terraform.
2. Configure the instance with:
   - A user data script or a configuration management tool (e.g., Ansible or Cloud-Init) to install dependencies (Python, Node.js).
   - Scripts to start the Flask backend and the Express frontend.
3. Ensure both applications are running on different ports (e.g., Flask on port `5000` and Express on port `3000`).

### Expected Deliverables
- Terraform configuration files (`main.tf`, `variables.tf`, etc.).
- A working EC2 instance with Flask and Express running and accessible via the instance's public IP.

### Implementation Details
For this Part-1, I have used the same frontend and backend files from form submission, and created a folder named **tf**. In that folder:
- Created **main.tf** with provider details and EC2 instance creation along with security group resource creation and port access configuration.
- Created **user_data.sh** file that contains commands to:
  - Install dependencies.
  - Clone the GitHub repo containing the frontend and backend code.
  - Create a Python virtual environment and install dependencies from `requirements.txt`.
  - Create a service for the backend to run in the background.
  - Install Node.js and required dependencies for the frontend.
  - Create a service for the frontend to run in the background.
- **outputs.tf** provides access port URL and instance IP address.
- Finally enabled and started the services using `daemon`.

Executed the command:
terraform apply
### 🌐 Application Link:
**http://3.111.57.104:3000/**

## Part 2: Deploy Flask and Express on Separate EC2 Instances

### Objective
Deploy the Flask backend and the Express frontend on two separate EC2 instances using Terraform.

### Steps
1. Provision **two EC2 instances** using Terraform:
   - One for the Flask backend.
   - One for the Express frontend.
2. Configure security groups to:
   - Allow communication between the two instances.
   - Expose both applications to the internet on their respective ports.
3. Use Terraform to define networking resources such as:
   - VPC
   - Subnets
   - Internet Gateway
   - Route Tables
   - Security Groups
4. Use **user data scripts** to automate installation and startup of both applications.

### Expected Deliverables
- Terraform configuration files for both backend and frontend instances.
- Two working EC2 instances:
  - One running the Flask backend.
  - One running the Express frontend.
- Security groups configured to allow communication and public access.

### Implementation Details
For this Part-2, I used the same frontend and backend files from form submission and created a folder named **tf**. In that folder:
- Created **main.tf** with provider details and EC2 instances creation.
- Defined **VPC**, **subnets**, **internet gateway**, and **route tables**.
- Created **individual security groups** for frontend and backend, each with appropriate port access.
- Created two user data scripts:
  - **user_data_backend.sh** — installs dependencies, sets up a Python virtual environment, installs `requirements.txt`, and creates a backend service to run in the background.
  - **user_data_frontend.sh** — installs Node.js dependencies, sets up the environment, and creates a frontend service to run in the background.
- In `main.tf`, the backend’s private IP and URL were passed as variables to the frontend instance so it can communicate with the backend.
- In the backend’s security group, inbound rules allow access to **port 5000 only** from the frontend’s subnet for secure communication.

Finally, executed:
terraform apply

### 🌐 Application Link:
**👉 http://65.0.94.244:3000/**

## Part 3: Deploy Flask and Express Using Docker and AWS Services

### 🎯 Objective:
Deploy Flask and Express as Docker containers using **AWS ECR**, **ECS**, and **VPC** with **Terraform**.

---

### 🧩 Steps:

#### **ECR:**
- Use Terraform to create two Elastic Container Registry (ECR) repositories: one for the Flask backend and one for the Express frontend.  
- Build Docker images for both applications and push them to their respective ECR repositories.

#### **VPC:**
- Use Terraform to create a VPC with subnets, route tables, and security groups.

#### **ECS:**
- Use Terraform to set up an ECS cluster.  
- Create two ECS services:
  - One for the Flask backend.  
  - One for the Express frontend.  
- Use ECS Fargate or EC2 launch type to deploy the containers.

#### **Load Balancer:**
- Use Terraform to provision an Application Load Balancer (ALB).  
- Configure ALB listeners to route requests to the appropriate ECS service.

---

### 📦 Expected Deliverables:
- Terraform configuration files for **ECR**, **ECS**, **VPC**, and **ALB** setup.  
- Docker images pushed to ECR.  
- ECS services running and accessible via the ALB.

---

### ⚙️ My Implementation:
For **Part 3**,  
- I have first built the Docker images and pushed them into **ECR** repositories.  
- I imported the ECR repositories into **Terraform state** to access them in `main.tf`.  
- Then, I created the `main.tf` file with all required resources:
  - ECR repositories  
  - ECS Cluster  
  - Application Load Balancer (ALB)  
  - VPC  
  - Target Groups for both frontend and backend  
  - Subnets  
  - Task Definitions for both services  
  - ECS Services (frontend and backend)  
  - ALB Listener  
  - IAM Role for ECS Task Execution policy  
- I created a `variables.tf` file to store configurable variables.  
- I created an `outputs.tf` file to display the ALB DNS name as output.  

By accessing that ALB DNS name, we can reach the application — since we are using the Application Load Balancer to direct traffic.  
The ALB routes:
- Port **80** → **3000** for frontend  
- Port **80** → **5000** for backend  

---

### 🌐 Application Link:
**http://multi-tier-alb-tf-279949273.ap-south-1.elb.amazonaws.com/**
