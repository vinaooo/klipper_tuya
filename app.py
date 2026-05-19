import os
import tinytuya
from flask import Flask, jsonify
from dotenv import load_dotenv

# Carrega as variáveis de ambiente do arquivo .env
load_dotenv()

app = Flask(__name__)

# Configurações extraídas dinamicamente do ambiente
DEVICE_ID = os.getenv('DEVICE_ID')
DEVICE_IP = os.getenv('DEVICE_IP')
LOCAL_KEY = os.getenv('LOCAL_KEY')
VERSION = float(os.getenv('VERSION', '3.5'))
DP_SWITCH = int(os.getenv('DP_SWITCH', '1'))
FLASK_PORT = int(os.getenv('FLASK_PORT', '5000'))

def obter_dispositivo():
    d = tinytuya.OutletDevice(DEVICE_ID, DEVICE_IP, LOCAL_KEY)
    d.set_version(VERSION)
    return d

@app.route('/luz/status', methods=['GET'])
def status():
    try:
        d = obter_dispositivo()
        data = d.status()
        if 'dps' in data:
            estado = data['dps'].get(str(DP_SWITCH))
            return jsonify({"status": "success", "on": estado})
        return jsonify({"status": "error", "message": "Falha ao ler DPS", "raw": data}), 500
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/luz/on', methods=['GET', 'POST'])
def ligar():
    try:
        d = obter_dispositivo()
        d.turn_on(switch=DP_SWITCH)
        return jsonify({"status": "success", "action": "on"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/luz/off', methods=['GET', 'POST'])
def desligar():
    try:
        d = obter_dispositivo()
        d.turn_off(switch=DP_SWITCH)
        return jsonify({"status": "success", "action": "off"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    # O host 0.0.0.0 garante que o Moonraker consiga bater na API sem problemas
    app.run(host='0.0.0.0', port=FLASK_PORT)
