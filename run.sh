#!/bin/bash

# Define the script folder as the working directory using absolute path for systemd safety
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

SERVICE_NAME="klipper-tuya"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Check for installation argument to setup systemd service automatically
if [ "$1" == "install" ]; then
    echo "========================================="
    echo "📦 Configuring Automatic Startup (systemd)..."
    echo "========================================="
    
    # Create systemd service file dynamically
    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Tuya Klipper Bridge API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/run.sh
Restart=always
RestartSec=5
StandardOutput=append:$SCRIPT_DIR/vbridge.log
StandardError=append:$SCRIPT_DIR/vbridge.log

[Install]
WantedBy=multi-user.target
EOF"

    echo "🔄 Reloading system daemons..."
    sudo systemctl daemon-reload
    
    echo "🔓 Enabling service on Armbian boot..."
    sudo systemctl enable $SERVICE_NAME
    
    echo "🚀 Starting the service now..."
    sudo systemctl start $SERVICE_NAME
    
    echo "========================================="
    echo "✅ Automation completed successfully!"
    echo "📊 Check service status: sudo systemctl status $SERVICE_NAME"
    echo "📝 View real-time logs: tail -f vbridge.log"
    echo "========================================="
    exit 0
fi

# ========================================================
# STANDARD EXECUTION FLOW
# ========================================================

echo "========================================="
echo "⚙️  Starting Local Tuya-Klipper Bridge"
echo "========================================="

# 1. Check if the virtual environment exists, if not, create it
if [ ! -d "venv" ]; then
    echo "📦 Virtual environment not found. Creating venv..."
    python3 -m venv venv
fi

# 2. Activate the virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# 3. Install/Update dependencies in an isolated way
echo "📥 Checking and installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# 4. Manage the .env file
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not configured!"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "📝 Generated '.env' file from the template."
        echo "🛑 Edit the '.env' file with your Tuya credentials before running again."
        exit 0
    else
        echo "❌ Fatal error: .env.example was not found."
        exit 1
    fi
fi

# 5. Run the Flask application with gunicorn for production
echo "🚀 Flask server is up and running!"
echo "========================================="

# Load the port from the .env file, default to 5000 if not found
source .env
PORT=${FLASK_PORT:-5000}

exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 4 app:app