import os
import logging
from typing import Tuple, Dict, Any
import tinytuya
from flask import Flask, jsonify
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = app.logger

# Configuration extracted from environment variables
DEVICE_ID = os.getenv('DEVICE_ID')
DEVICE_IP = os.getenv('DEVICE_IP')
LOCAL_KEY = os.getenv('LOCAL_KEY')
VERSION = float(os.getenv('VERSION', '3.5'))
DP_SWITCH = int(os.getenv('DP_SWITCH', '1'))
FLASK_PORT = int(os.getenv('FLASK_PORT', '5000'))

if not all([DEVICE_ID, DEVICE_IP, LOCAL_KEY]):
    logger.warning("Tuya device credentials are not fully configured in the .env file.")

def get_device() -> tinytuya.OutletDevice:
    """Initialize and return the Tuya device connection."""
    device = tinytuya.OutletDevice(DEVICE_ID, DEVICE_IP, LOCAL_KEY)
    device.set_version(VERSION)
    return device

@app.route('/light/status', methods=['GET'])
def get_status() -> Tuple[Any, int]:
    """Retrieve the current status of the device."""
    try:
        device = get_device()
        data = device.status()
        if 'dps' in data:
            state = data['dps'].get(str(DP_SWITCH))
            return jsonify({"status": "success", "on": state}), 200
        
        logger.error(f"Failed to read DPS. Raw response: {data}")
        return jsonify({"status": "error", "message": "Failed to read DPS", "raw": data}), 500
    except Exception as e:
        logger.error(f"Error fetching status: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/light/on', methods=['GET', 'POST'])
def turn_on() -> Tuple[Any, int]:
    """Turn the Tuya device on."""
    try:
        device = get_device()
        device.turn_on(switch=DP_SWITCH)
        logger.info("Device turned ON")
        return jsonify({"status": "success", "action": "on"}), 200
    except Exception as e:
        logger.error(f"Error turning on the device: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/light/off', methods=['GET', 'POST'])
def turn_off() -> Tuple[Any, int]:
    """Turn the Tuya device off."""
    try:
        device = get_device()
        device.turn_off(switch=DP_SWITCH)
        logger.info("Device turned OFF")
        return jsonify({"status": "success", "action": "off"}), 200
    except Exception as e:
        logger.error(f"Error turning off the device: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    # Host 0.0.0.0 ensures Moonraker can reach the API
    app.run(host='0.0.0.0', port=FLASK_PORT)
