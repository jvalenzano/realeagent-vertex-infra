"""Intent Processor Service - Natural Language Understanding"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
import vertexai
from vertexai.generative_models import GenerativeModel
import json
import os
import logging
import re

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="RealeAgent Intent Processor")

# Initialize Vertex AI
PROJECT_ID = os.getenv("PROJECT_ID", "realeagent-vertex-ai")
LOCATION = os.getenv("REGION", "us-central1")
vertexai.init(project=PROJECT_ID, location=LOCATION)

# Initialize model
model = GenerativeModel("gemini-2.5-pro")
model_name = "gemini-2.5-pro"
logger.info(f"Successfully initialized model: {model_name}")

class IntentRequest(BaseModel):
    user_input: str
    context: Optional[Dict] = None

class IntentResponse(BaseModel):
    form_type: str
    property_address: Optional[str] = None
    price: Optional[float] = None
    built_year: Optional[int] = None
    escrow_days: Optional[int] = None
    contingencies: List[str] = []
    confidence: float = 0.0

def extract_json_from_response(text: str) -> dict:
    """Extract JSON from response that might be wrapped in markdown"""
    # Try to find JSON in markdown code blocks
    json_match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', text, re.DOTALL)
    if json_match:
        json_str = json_match.group(1).strip()
    else:
        # If no markdown blocks, assume the whole text is JSON
        json_str = text.strip()
    
    return json.loads(json_str)

@app.post("/process")
async def process_intent(request: IntentRequest):
    """Extract intent from natural language input"""
    
    prompt = f"""Extract real estate transaction details from this request:
    "{request.user_input}"
    
    Return a JSON object with these fields:
    - form_type: Type of document needed (use "purchase_agreement" for purchase requests)
    - property_address: Full property address
    - price: Purchase price as number (no formatting, no dollar signs)
    - built_year: Year property was built
    - escrow_days: Number of days for escrow
    - contingencies: Array of contingencies mentioned
    - confidence: Confidence score 0-1
    
    Return ONLY the JSON object, no other text.
    """
    
    try:
        response = model.generate_content(prompt)
        logger.info(f"Model response: {response.text}")
        
        # Parse the response (handling markdown-wrapped JSON)
        result = extract_json_from_response(response.text)
        
        # Ensure all required fields exist
        result.setdefault('form_type', 'purchase_agreement')
        result.setdefault('contingencies', [])
        result.setdefault('confidence', 0.9)
        
        return IntentResponse(**result)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse model response: {e}")
        logger.error(f"Raw response was: {response.text}")
        raise HTTPException(status_code=500, detail=f"Invalid model response format: {str(e)}")
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {
        "status": "healthy", 
        "service": "intent-processor",
        "model": model_name,
        "project": PROJECT_ID,
        "location": LOCATION
    }

@app.get("/")
async def root():
    return {"message": "RealeAgent Intent Processor", "model": model_name}
