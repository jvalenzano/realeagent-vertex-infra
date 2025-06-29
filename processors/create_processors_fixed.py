#!/usr/bin/env python3
"""Create Document AI processors for RealeAgent forms - Fixed version"""

import os
import json
import sys
from google.cloud import documentai_v1 as documentai
from google.api_core.client_options import ClientOptions
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
        
    def list_existing_processors(self):
        """List all existing processors"""
        try:
            processors = self.client.list_processors(parent=self.parent)
            existing = {}
            for processor in processors:
                existing[processor.display_name] = processor.name
            return existing
        except Exception as e:
            print(f"Error listing processors: {e}")
            return {}
        
    def create_processor(self, display_name: str, processor_type: str) -> str:
        """Create a Document AI processor - fixed version"""
        
        # First check if it already exists
        existing = self.list_existing_processors()
        if display_name in existing:
            print(f"✓ Processor '{display_name}' already exists")
            return existing[display_name]
        
        # Create new processor
        processor = documentai.Processor(
            display_name=display_name,
            type_=processor_type
        )
        
        try:
            print(f"Creating processor: {display_name}")
            # Create the processor
            operation = self.client.create_processor(
                parent=self.parent,
                processor=processor
            )
            
            print(f"Waiting for operation to complete...")
            # Wait for the operation to complete
            result = operation.result(timeout=300)
            
            print(f"✓ Created processor: {result.name}")
            return result.name
            
        except Exception as e:
            print(f"✗ Error creating {display_name}: {e}")
            # If it's an "already exists" error, try to find it
            if "already exists" in str(e).lower():
                existing = self.list_existing_processors()
                if display_name in existing:
                    print(f"✓ Found existing processor: {existing[display_name]}")
                    return existing[display_name]
            return None

def main():
    """Create all required processors"""
    manager = ProcessorManager()
    
    # First, list what we have
    print("\nChecking existing processors...")
    existing = manager.list_existing_processors()
    if existing:
        print(f"Found {len(existing)} existing processors:")
        for name in existing:
            print(f"  - {name}")
    else:
        print("No existing processors found.")
    
    print("\nCreating/verifying processors...")
    
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
            proc_id_only = processor_id.split('/')[-1] if processor_id else None
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
    
    # Show what was saved
    print("\nProcessor IDs:")
    for name, info in processor_ids.items():
        if info.get("id"):
            print(f"  {name}: {info['id']}")
    
    print("\nNext steps:")
    print("1. Upload training documents to processors/training-data/")
    print("2. Define extraction schemas for each processor")
    print("3. Run training jobs for the processors")

if __name__ == "__main__":
    main()
