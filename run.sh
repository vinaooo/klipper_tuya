#!/bin/bash

# Define the script folder as the working directory
cd "$(dirname "$0")"

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