#!/usr/bin/env python3

import os
import sys
import argparse

def create_service(service_name):
    service_dir = f"services/{service_name}"
    os.makedirs(service_dir, exist_ok=True)
    
    # Create requirements.txt
    requirements = """Flask==3.0.0
gunicorn==21.2.0
google-cloud-aiplatform==1.71.1
vertexai==1.71.1"""
    
    with open(f"{service_dir}/requirements.txt", "w") as f:
        f.write(requirements)
    
    # Create main.py with proper Python syntax
    main_py = f"""import os
import json
from flask import Flask, request, jsonify
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

SERVICE_NAME = "{service_name}"

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({{"status": "healthy", "service": SERVICE_NAME}}), 200

@app.route('
