import os
import json
import requests
from flask import Flask, request, jsonify
import logging
from typing import Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Service URLs - will be set from environment or defaults
INTENT_PROCESSOR_URL = os.environ.get('INTENT_PROCESSOR_URL', 
    'https://intent-processor-209579160014.us-central1.run.app')
DOCUMENT_EXTRACTOR_URL = os.environ.get('DOCUMENT_EXTRACTOR_URL', 
    'https://document-extractor-209579160014.us-central1.run.app')
COMPLIANCE_VALIDATOR_URL = os.environ.get('COMPLIANCE_VALIDATOR_URL', 
    'https://compliance-validator-209579160014.us-central1.run.app')

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy", 
        "service": "orchestrator",
        "dependencies": {
            "intent_processor": INTENT_PROCESSOR_URL,
            "document_extractor": DOCUMENT_EXTRACTOR_URL,
            "compliance_validator": COMPLIANCE_VALIDATOR_URL
        }
    }), 200

@app.route('/process', methods=['POST'])
def process_request():
    """Main orchestration endpoint"""
    try:
        data = request.get_json()
        query = data.get('query', '')
        
        logger.info(f"Processing query: {query}")
        
        # Step 1: Process intent
        intent_response = requests.post(
            f"{INTENT_PROCESSOR_URL}/process",
            json={"user_input": query},
            timeout=10
        )
        intent_data = intent_response.json()
        logger.info(f"Intent processed: {intent_data}")
        
        # Step 2: Extract document data (if needed)
        extraction_data = None
        if intent_data.get('success'):
            extraction_response = requests.post(
                f"{DOCUMENT_EXTRACTOR_URL}/extract_from_intent",
                json={"intent_data": intent_data},
                timeout=10
            )
            extraction_data = extraction_response.json()
            logger.info(f"Extraction completed: {extraction_data}")
        
        # Step 3: Validate compliance
        compliance_response = requests.post(
            f"{COMPLIANCE_VALIDATOR_URL}/validate",
            json={
                "property_details": {
                    "built_year": intent_data.get('built_year'),
                    "price": intent_data.get('price'),
                    "address": intent_data.get('property_address')
                },
                "transaction_type": "purchase"
            },
            timeout=10
        )
        compliance_data = compliance_response.json()
        logger.info(f"Compliance validated: {compliance_data}")
        
        # Build final response
        response = {
            "success": True,
            "query": query,
            "intent": intent_data,
            "extraction": extraction_data,
            "compliance": compliance_data,
            "summary": {
                "property_address": intent_data.get('property_address'),
                "price": intent_data.get('price'),
                "built_year": intent_data.get('built_year'),
                "requires_lead_paint": intent_data.get('built_year', 2000) < 1978,
                "required_forms": compliance_data.get('required_forms', []),
                "recommendations": compliance_data.get('recommendations', [])
            }
        }
        
        return jsonify(response), 200
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Service communication error: {str(e)}")
        return jsonify({"error": f"Service error: {str(e)}"}), 503
    except Exception as e:
        logger.error(f"Orchestration error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/pipeline', methods=['POST'])
def pipeline():
    """Simplified pipeline endpoint"""
    try:
        data = request.get_json()
        query = data.get('query', '')
        
        # Call main process endpoint
        return process_request()
        
    except Exception as e:
        logger.error(f"Pipeline error: {str(e)}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
