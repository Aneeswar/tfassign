#!/bin/bash
set -e

# Define directories
APP_DIR="/home/ubuntu/form-app"
PYTHON_BIN="/usr/bin/python3" # Verified python path

echo "Starting Flask Backend setup..."
sudo apt update -y
sudo apt install -y git python3 python3-pip python3-venv

REPO="https://github.com/Aneeswar/form1" # !! VERIFY REPO URL !!

# Clone and setup
git clone $REPO $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR
cd $APP_DIR/backend

# VENV FIX: Install dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt


# Create Flask service file
cat <<EOF > /etc/systemd/system/flask-backend.service
[Unit]
Description=Flask Backend Service
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/backend
# Use python from VENV
ExecStart=$APP_DIR/backend/venv/bin/python app.py 
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start services
systemctl daemon-reload
systemctl enable flask-backend
systemctl start flask-backend