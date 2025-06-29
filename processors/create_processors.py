#!/usr/bin/env python3
"""Create Document AI processors for RealeAgent forms"""

import os
import json
import sys
from google.cloud import documentai_v1 as documentai
from google.api_core.client_options import ClientOptions
from google.oauth2 import service_account
from google.auth.exceptions import DefaultCredentialsError
import google.auth

PROJECT_ID = "realeagent-vertex-ai"
PROJECT_NUMBER = "209579160014"
LOCATION = "us"  # Document AI only supports 'us' for custom processors

class ProcessorManager:
    def __init__(self):
        """Initialize Document AI client with proper authentication"""
        try:
            # Try to use Application Default Credentials
            credentials, project = google.auth.default()
            print(f"✓ Using Application Default Credentials for project: {project or PROJECT_ID}")
        except DefaultCredentialsError:
            print("❌ No Application Default Credentials found!")
            print("Please run: gcloud auth application-default login")
            sys.exit(1)
            
        # Use Application Default Credentials
        self.client = documentai.DocumentProcessorServiceClient(
            client_options=ClientOptions(
                api_endpoint=f"{LOCATION}-documentai.googleapis.com"
            ),
            credentials=credentials
        )
        self.parent = f"projects/{PROJECT_ID}/locations/{LOCATION}"
        
    def create_processor(self, display_name: str, processor_type: str) -> str:
        """Create a Document AI processor"""
        processor = documentai.Processor(
            display_name=display_name,
            type_=processor_type
        )
        
        try:
            print(f"Creating processor: {display_name}")
            operation = self.client.create_processor(
                parent=self.parent, 
                processor=processor
            )
            print(f"Waiting for operation to complete...")
            response = operation.result()
            print(f"✓ Created: {response.name}")
            return response.name
        except Exception as e:
            if "already exists" in str(e):
                print(f"⚠️  Processor '{display_name}' already exists")
                # List processors to find existing one
                processors = self.client.list_processors(parent=self.parent)
                for p in processors:
                    if p.display_name == display_name:
                        return p.name
            else:
                print(f"✗ Error creating {display_name}: {e}")
                return None

def main():
    """Create all required processors"""
    manager = ProcessorManager()
    
    # Define processors to create
    processors = [
        {
            "name": "RealeAgent Lead Paint Disclosure",
            "type": "CUSTOM_EXTRACTION_PROCESSOR",
            "description": "Extract fields from Lead-Based Paint Disclosure forms"
        },
        {
            "name": "RealeAgent CA RPA",
            "type": "CUSTOM_EXTRACTION_PROCESSOR", 
            "description": "Extract fields from California Residential Purchase Agreement"
        },
        {
            "name": "RealeAgent BIA",
            "type": "CUSTOM_EXTRACTION_PROCESSOR",
            "description": "Extract fields from Buyer's Inspection Advisory"
        },
        {
            "name": "RealeAgent Form Parser",
            "type": "FORM_PARSER_PROCESSOR",
            "description": "General form parsing for other CAR forms"
        }
    ]
    
    # Create processors and save IDs
    processor_ids = {}
    
    for proc in processors:
        processor_id = manager.create_processor(proc["name"], proc["type"])
        if processor_id:
            # Extract just the processor ID from the full name
            # Format: projects/{project}/locations/{location}/processors/{id}
            proc_id_only = processor_id.split('/')[-1]
            processor_ids[proc["name"]] = {
                "id": proc_id_only,
                "full_name": processor_id,
                "type": proc["type"],
                "description": proc["description"]
            }
    
    # Save processor IDs
    output_file = "processor_ids.json"
    with open(output_file, 'w') as f:
        json.dump(processor_ids, f, indent=2)
    
    print(f"\n✅ Processor configuration saved to {output_file}")
    print("\nNext steps:")
    print("1. Upload training documents to processors/training-data/")
    print("2. Run 'make train' to train the processors")

if __name__ == "__main__":
    main()
