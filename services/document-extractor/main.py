import os
import json
from flask import Flask, request, jsonify
from google.cloud import documentai_v1 as documentai
from google.api_core.client_options import ClientOptions
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize Document AI client
PROJECT_ID = os.environ.get('PROJECT_ID', 'realeagent-vertex-ai')
LOCATION = 'us'  # Document AI uses 'us' not 'us-central1'

# Load processor IDs
processor_ids = {
    "lead_paint": "9de800b942d80f79",
    "ca_rpa": "2d7566c3aec1205f",
    "bia": "65fb7aab83dd5495",
    "form_parser": "9de800b942d80ad1"
}

# Initialize Document AI client
opts = ClientOptions(api_endpoint=f"{LOCATION}-documentai.googleapis.com")
client = documentai.DocumentProcessorServiceClient(client_options=opts)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "document-extractor"}), 200

@app.route('/extract', methods=['POST'])
def extract_document():
    try:
        data = request.get_json()
        
        # Get parameters
        document_content = data.get('document_content')  # Base64 encoded
        document_type = data.get('document_type', 'form_parser')
        mime_type = data.get('mime_type', 'application/pdf')
        
        if not document_content:
            return jsonify({"error": "No document content provided"}), 400
        
        # Get processor ID
        processor_id = processor_ids.get(document_type, processor_ids['form_parser'])
        processor_name = f"projects/{PROJECT_ID}/locations/{LOCATION}/processors/{processor_id}"
        
        logger.info(f"Processing document with processor: {processor_name}")
        
        # Create document object
        document = documentai.Document(
            content=document_content,
            mime_type=mime_type
        )
        
        # Create request
        request_obj = documentai.ProcessRequest(
            name=processor_name,
            raw_document=documentai.RawDocument(
                content=document_content,
                mime_type=mime_type
            )
        )
        
        # Process document
        result = client.process_document(request=request_obj)
        
        # Extract entities
        entities = []
        for entity in result.document.entities:
            entities.append({
                "type": entity.type_,
                "text": entity.mention_text,
                "confidence": entity.confidence,
                "normalized_value": entity.normalized_value.text if entity.normalized_value else None
            })
        
        # Extract form fields
        form_fields = []
        for page in result.document.pages:
            for form_field in page.form_fields:
                field_name = form_field.field_name.text_anchor.content if form_field.field_name else ""
                field_value = form_field.field_value.text_anchor.content if form_field.field_value else ""
                form_fields.append({
                    "name": field_name,
                    "value": field_value,
                    "confidence": form_field.field_name.confidence if form_field.field_name else 0
                })
        
        # Extract text
        text = result.document.text
        
        response = {
            "success": True,
            "processor_used": processor_id,
            "text": text,
            "entities": entities,
            "form_fields": form_fields,
            "page_count": len(result.document.pages)
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Error processing document: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/extract_from_intent', methods=['POST'])
def extract_from_intent():
    """Extract data based on intent processor output"""
    try:
        data = request.get_json()
        intent_data = data.get('intent_data', {})
        
        # Map form types to processor types
        form_type_mapping = {
            "purchase_agreement": "ca_rpa",
            "lead_paint_disclosure": "lead_paint",
            "inspection_advisory": "bia"
        }
        
        form_type = intent_data.get('form_type', 'purchase_agreement')
        document_type = form_type_mapping.get(form_type, 'form_parser')
        
        # For now, return structured data based on intent
        # In production, this would process actual documents
        response = {
            "success": True,
            "form_type": form_type,
            "processor_type": document_type,
            "extracted_data": {
                "property_address": intent_data.get('property_address'),
                "price": intent_data.get('price'),
                "built_year": intent_data.get('built_year'),
                "escrow_days": intent_data.get('escrow_days'),
                "contingencies": intent_data.get('contingencies', [])
            },
            "requires_lead_paint": intent_data.get('built_year', 2000) < 1978
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Error in extract_from_intent: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
