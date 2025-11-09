#!/bin/bash
set -e

# Define directories and executables
APP_DIR="/home/ubuntu/form-app"
NODE_BIN="/usr/bin/node" # Verified path for Node.js
REPO="https://github.com/Aneeswar/form1" 

# --- 1. Install Dependencies ---
echo "Installing base dependencies..."
sudo apt update -y

# Install git, Python, pip, and ensure venv package is installed for isolation
sudo apt install -y git python3 python3-pip python3-venv

# Install Node.js and npm (assuming this successfully put 'node' at /usr/bin)
sudo apt install -y nodejs npm 

# --- 2. Clone Application Code ---
echo "Cloning application code..."
git clone $REPO $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR
cd $APP_DIR

# --- 3. Setup Flask Backend (VENV FIX) ---
echo "Setting up Flask backend with VENV..."
cd backend

# FIX: Create and activate a virtual environment to bypass 'externally-managed-environment' error
python3 -m venv venv
source venv/bin/activate 

# Install dependencies into the isolated environment
pip install -r requirements.txt


# Create Flask service file
cat <<EOF > /etc/systemd/system/flask-backend.service
[Unit]
Description=Flask Backend Service
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/backend
# FIX: Use Python from the VENV to run the app
ExecStart=$APP_DIR/backend/venv/bin/python app.py 
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cd .. # <-- FIX 1: Move back to the root application directory ($APP_DIR)

# --- 4. Setup Express Frontend ---
echo "Setting up Express frontend..."
cd frontend # <-- FIX 1: Now safely move into the frontend directory
npm install

# Create Express service file, setting ENV VAR and using correct path
cat <<EOF > /etc/systemd/system/express-frontend.service
[Unit]
Description=Express Frontend Service
After=network.target flask-backend.service

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/frontend
# Set the environment variable directly for reliability
Environment="BACKEND_URL=http://localhost:5000"
# FIX: Use the verified Node.js path
ExecStart=$NODE_BIN server.js 
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- 5. Start Services ---
echo "Starting services..."
systemctl daemon-reload
systemctl enable flask-backend
systemctl enable express-frontend
systemctl start flask-backend
systemctl start express-frontend