#!/bin/bash

SERVICE_NAME=$1

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: ./tools/create_service.sh <service-name>"
    exit 1
fi

SERVICE_DIR="services/$SERVICE_NAME"
mkdir -p "$SERVICE_DIR"

echo "Creating $SERVICE_NAME service..."

# Create requirements.txt
cat > "$SERVICE_DIR/requirements.txt" << 'REQEOF'
Flask==3.0.0
gunicorn==21.2.0
google-cloud-aiplatform==1.71.1
vertexai==1.71.1
REQEOF

# Create main.py using printf to avoid corruption
cat > "$SERVICE_DIR/main.py" << 'PYEOF'
import os
import json
from flask import Flask, request, jsonify
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

SERVICE_NAME = "SERVICE_NAME_PLACEHOLDER"

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": SERVICE_NAME}), 200

@app.route('/process', methods=['POST'])
def process():
    try:
        data = request.get_json()
        response = {
            "success": True,
            "service": SERVICE_NAME,
            "data": data
        }
        return jsonify(response), 200
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return jsonify({"error": str(e)}), 500

PYEOF

# Add the main block using printf to avoid corruption
printf '\nif __name__ == "__main__":\n' >> "$SERVICE_DIR/main.py"
printf '    port = int(os.environ.get("PORT", 8080))\n' >> "$SERVICE_DIR/main.py"
printf '    app.run(host="0.0.0.0", port=port)\n' >> "$SERVICE_DIR/main.py"

# Replace placeholder
sed -i '' "s/SERVICE_NAME_PLACEHOLDER/$SERVICE_NAME/g" "$SERVICE_DIR/main.py"

echo "✅ Service $SERVICE_NAME created at $SERVICE_DIR"
echo ""
echo "Deploy with:"
echo "cd $SERVICE_DIR"
echo "gcloud run deploy $SERVICE_NAME --source . --region us-central1 --allow-unauthenticated --set-env-vars \"PROJECT_ID=realeagent-vertex-ai\""
