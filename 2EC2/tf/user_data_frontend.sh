#!/bin/bash
set -e

# Define directories and executables
APP_DIR="/home/ubuntu/form-app"
NODE_BIN="/usr/bin/node" # Path should be correct after NodeSource install
BACKEND_HOST="${backend_ip}" # Injected by Terraform
BACKEND_PORT="${backend_port}" # Injected by Terraform

echo "Starting Express Frontend setup..."
sudo apt update -y


echo "Installing modern Node.js v20..."
sudo apt install -y git curl

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

sudo apt install -y nodejs 


REPO="https://github.com/Aneeswar/form1" 

# Clone and setup
echo "Cloning application code and installing npm dependencies..."
git clone $REPO $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR
cd $APP_DIR/frontend
npm install

# Create Express service file, passing ENV VAR directly
cat <<EOF > /etc/systemd/system/express-frontend.service
[Unit]
Description=Express Frontend Service
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/frontend
# FIX: Set the environment variable to the BACKEND'S PRIVATE IP
Environment="BACKEND_URL=http://$BACKEND_HOST:$BACKEND_PORT"
ExecStart=$NODE_BIN server.js 
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start services
echo "Starting Express service..."
systemctl daemon-reload
systemctl enable express-frontend
systemctl start express-frontend