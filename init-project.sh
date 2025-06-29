#!/bin/bash
# init-project.sh - Initialize existing realeagent-vertex-ai project

set -euo pipefail

# Project Configuration
PROJECT_ID="realeagent-vertex-ai"
PROJECT_NUMBER="209579160014"
REGION="us-central1"
DOCAI_LOCATION="us"  # Document AI only supports 'us' location

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 RealeAgent Vertex AI Project Initialization${NC}"
echo -e "${BLUE}Project: ${PROJECT_ID} (${PROJECT_NUMBER})${NC}"
echo "================================================"
echo ""

# Function to wait for user confirmation
wait_for_user() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${GREEN}Press ENTER when ready to continue...${NC}"
    read -r
}

# Function to check command success
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 successful!${NC}"
    else
        echo -e "${RED}❌ $1 failed! Please check the error above.${NC}"
        exit 1
    fi
}

# Step 1: Authentication Setup
echo -e "${BLUE}Step 1: Google Cloud Authentication${NC}"
echo -e "${YELLOW}Checking authentication status...${NC}"

# Clear potentially conflicting environment variables
unset GOOGLE_APPLICATION_CREDENTIALS

# Check if already authenticated
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -n "$ACTIVE_ACCOUNT" ]; then
    echo -e "${GREEN}✅ Already authenticated as: $ACTIVE_ACCOUNT${NC}"
    echo -e "${YELLOW}Do you want to re-authenticate? (y/N)${NC}"
    read -r REAUTH
    if [[ ! "$REAUTH" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Using existing authentication${NC}"
    else
        echo -e "${YELLOW}Re-authenticating...${NC}"
        gcloud auth login
        check_status "Re-authentication"
    fi
else
    echo -e "${YELLOW}Not authenticated. Starting login process...${NC}"
    echo -e "${YELLOW}🌐 A browser window will open${NC}"
    echo -e "${YELLOW}   1. Select your Google account${NC}"
    echo -e "${YELLOW}   2. Click 'Allow' for permissions${NC}"
    wait_for_user "Ready to authenticate?"
    
    gcloud auth login
    check_status "Authentication"
fi

# Application Default Credentials (for APIs)
echo -e "\n${BLUE}Setting up Application Default Credentials...${NC}"
echo -e "${YELLOW}This is required for Vertex AI and Document AI APIs${NC}"

# Check if ADC exists
if gcloud auth application-default print-access-token >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Application Default Credentials already set${NC}"
else
    echo -e "${YELLOW}Setting up Application Default Credentials...${NC}"
    echo -e "${YELLOW}🌐 Another browser window will open${NC}"
    wait_for_user "Ready for application default login?"
    
    gcloud auth application-default login \
        --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/documentai
    check_status "Application default credentials"
fi

# Set quota project
gcloud auth application-default set-quota-project ${PROJECT_ID}
check_status "Quota project setup"
echo ""

# Change to project directory
cd /Users/jasonvalenzano/realeagent-vertex-infra

# Step 2: Project Configuration
echo -e "\n${BLUE}Step 2: Configuring Google Cloud Project...${NC}"
gcloud config set project ${PROJECT_ID}
check_status "Project configuration"
gcloud config set compute/region ${REGION}
gcloud config list

# Step 3: Directory Structure
echo -e "\n${BLUE}Step 3: Creating project structure...${NC}"
mkdir -p {infrastructure/{environments/{dev,staging,prod},modules/{document-ai,vertex-ai,cloud-run,networking},scripts},services/{intent-processor,document-extractor,compliance-validator,orchestrator},pipelines/{training,inference,batch-processing},processors/{schemas,training-data,validation-sets},shared/{models,utils,clients},tests,scripts}

# Ensure we're using the correct project
echo -e "\n${YELLOW}Configuring gcloud for project...${NC}"
gcloud config set project ${PROJECT_ID}
gcloud config set compute/region ${REGION}
gcloud config list

# Step 4: API Enablement
echo -e "\n${BLUE}Step 4: Checking and enabling required APIs...${NC}"
REQUIRED_APIS=(
    "documentai.googleapis.com"
    "aiplatform.googleapis.com"
    "cloudbuild.googleapis.com"
    "run.googleapis.com"
    "artifactregistry.googleapis.com"
    "storage.googleapis.com"
    "firestore.googleapis.com"
    "redis.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:${api}" --format="value(name)" | grep -q "${api}"; then
        echo -e "✓ ${api} already enabled"
    else
        echo -e "✗ ${api} not enabled - enabling now..."
        gcloud services enable ${api} --quiet
    fi
done

# Create .env file for local development
echo -e "\n${YELLOW}Creating environment configuration...${NC}"
cat > .env << EOF
# RealeAgent Vertex AI Configuration
PROJECT_ID=${PROJECT_ID}
PROJECT_NUMBER=${PROJECT_NUMBER}
REGION=${REGION}
DOCAI_LOCATION=${DOCAI_LOCATION}

# Service URLs (will be populated after deployment)
INTENT_PROCESSOR_URL=
DOCUMENT_EXTRACTOR_URL=
COMPLIANCE_VALIDATOR_URL=
ORCHESTRATOR_URL=

# Integration endpoints
NEXTJS_API_URL=https://api.realeagent.com
ARIA_WEBHOOK_URL=

# Feature flags
USE_CACHING=true
ENABLE_MONITORING=true
DEBUG_MODE=false
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Environment variables
.env
.env.local
.env.*.local

# Google Cloud
*.json
!schemas/*.json
!package.json
!tsconfig.json
service-account-key.json
processor_ids.json

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Test coverage
coverage/
.coverage
htmlcov/
EOF

# Create Python requirements
echo -e "\n${YELLOW}Creating Python requirements...${NC}"
cat > requirements.txt << 'EOF'
# Google Cloud AI Platform
google-cloud-aiplatform==1.38.0
google-cloud-documentai==2.20.0
google-cloud-storage==2.10.0
google-cloud-firestore==2.13.0
google-cloud-logging==3.8.0
google-cloud-monitoring==2.16.0

# Vertex AI
vertexai==1.38.0

# Framework
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0

# Utilities
python-dotenv==1.0.0
httpx==0.25.0
tenacity==8.2.3

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0

# Development
black==23.11.0
flake8==6.1.0
mypy==1.7.0
EOF

# Create Makefile
echo -e "\n${YELLOW}Creating Makefile...${NC}"
cat > Makefile << 'EOF'
.PHONY: help setup deploy test validate clean

PROJECT_ID = realeagent-vertex-ai
PROJECT_NUMBER = 209579160014
REGION = us-central1
DOCAI_LOCATION = us

help:
	@echo "RealeAgent Vertex AI Infrastructure"
	@echo "=================================="
	@echo "Project: $(PROJECT_ID) ($(PROJECT_NUMBER))"
	@echo ""
	@echo "make setup     - Initial project setup"
	@echo "make deploy    - Deploy all services"
	@echo "make test      - Run integration tests"
	@echo "make validate  - Validate infrastructure"
	@echo "make processors - Create Document AI processors"
	@echo "make train     - Train Document AI models"
	@echo "make clean     - Clean up resources"

setup:
	@echo "Setting up project..."
	./scripts/init-project.sh

processors:
	@echo "Creating Document AI processors..."
	cd processors && python3 create_processors.py

train:
	@echo "Training Document AI processors..."
	cd processors && python3 train_processors.py

deploy-services:
	@echo "Building and deploying services..."
	./scripts/deploy-services.sh

deploy-infra:
	@echo "Deploying infrastructure with Terraform..."
	cd infrastructure/environments/$(ENV) && terraform apply

deploy: deploy-infra deploy-services
	@echo "✅ Full deployment complete"

test:
	@echo "Running tests..."
	python -m pytest tests/ -v --cov=services --cov-report=html

validate:
	@echo "Validating deployment..."
	./scripts/validate-deployment.sh

monitor:
	@echo "Opening monitoring dashboards..."
	@echo "https://console.cloud.google.com/monitoring/dashboards?project=$(PROJECT_ID)"
	
logs:
	@echo "Tailing service logs..."
	gcloud logging tail "resource.type=cloud_run_revision" --project=$(PROJECT_ID)

clean:
	@echo "⚠️  WARNING: This will delete all resources!"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	./scripts/cleanup.sh
EOF

# Create processor creation script
echo -e "\n${YELLOW}Creating Document AI processor setup...${NC}"
mkdir -p processors
cat > processors/create_processors.py << 'EOF'
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
EOF

# Create README for the project
echo -e "\n${YELLOW}Creating project README...${NC}"
cat > README.md << 'EOF'
# RealeAgent Vertex AI Infrastructure

Production AI infrastructure for RealeAgent document intelligence system.

## Project Details
- **Project ID**: `realeagent-vertex-ai`
- **Project Number**: `209579160014`
- **Region**: `us-central1`
- **Document AI Location**: `us`

## Quick Start

```bash
# Initial setup
make setup

# Create Document AI processors
make processors

# Train processors with sample data
make train

# Deploy all services
make deploy

# Run tests
make test
```

## Architecture

```
├── infrastructure/     # Terraform IaC
├── services/          # Cloud Run microservices
├── processors/        # Document AI configurations
├── pipelines/         # Vertex AI pipelines
└── shared/           # Shared libraries
```

## Services

1. **Intent Processor**: Natural language understanding (Gemini Pro)
2. **Document Extractor**: Form data extraction (Document AI)
3. **Compliance Validator**: California real estate rules engine
4. **Orchestrator**: Pipeline coordination service

## Integration

This infrastructure integrates with:
- **realeagent-nextjs**: Frontend application
- **realeagent-ai-aria**: ADK agent orchestration

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn services.intent_processor.main:app --reload

# Run tests
pytest tests/ -v
```

## Monitoring

View dashboards: https://console.cloud.google.com/monitoring?project=realeagent-vertex-ai
EOF

# Create initial service stubs
echo -e "\n${YELLOW}Creating service stubs...${NC}"

# Intent Processor Service
cat > services/intent-processor/main.py << 'EOF'
"""Intent Processor Service - Natural Language Understanding"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
import vertexai
from vertexai.generative_models import GenerativeModel
import json
import os

app = FastAPI(title="RealeAgent Intent Processor")

# Initialize Vertex AI
PROJECT_ID = os.getenv("PROJECT_ID", "realeagent-vertex-ai")
LOCATION = os.getenv("REGION", "us-central1")
vertexai.init(project=PROJECT_ID, location=LOCATION)

# Initialize Gemini 2.5 Pro (same as AI Studio testing)
model = GenerativeModel("gemini-2.5-pro")

class IntentRequest(BaseModel):
    user_input: str
    context: Optional[Dict] = None

class IntentResponse(BaseModel):
    form_type: str
    property_address: Optional[str]
    price: Optional[float]
    built_year: Optional[int]
    escrow_days: Optional[int]
    contingencies: List[str]
    confidence: float

@app.post("/process", response_model=IntentResponse)
async def process_intent(request: IntentRequest):
    """Extract intent from natural language input"""
    
    prompt = f"""Extract real estate transaction details from this request:
    {request.user_input}
    
    Return a JSON object with these fields:
    - form_type: Type of document needed
    - property_address: Full property address
    - price: Purchase price as number (no formatting)
    - built_year: Year property was built
    - escrow_days: Number of days for escrow
    - contingencies: Array of contingencies mentioned
    - confidence: Confidence score 0-1
    
    Be precise and extract only what is explicitly mentioned.
    """
    
    try:
        response = model.generate_content(prompt)
        result = json.loads(response.text)
        return IntentResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "intent-processor"}
EOF

# Create Dockerfile for Intent Processor
cat > services/intent-processor/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
EOF

# Create deployment script
mkdir -p scripts
cat > scripts/deploy-services.sh << 'EOF'
#!/bin/bash
set -euo pipefail

PROJECT_ID="realeagent-vertex-ai"
REGION="us-central1"

echo "🚀 Deploying RealeAgent services to Cloud Run"

# Services to deploy
SERVICES=("intent-processor" "document-extractor" "compliance-validator" "orchestrator")

for service in "${SERVICES[@]}"; do
    if [ -d "services/$service" ]; then
        echo "Building $service..."
        cd services/$service
        
        # Build and push to Artifact Registry
        gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/realeagent-containers/$service
        
        # Deploy to Cloud Run
        echo "Deploying $service..."
        gcloud run deploy $service \
            --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/realeagent-containers/$service \
            --platform managed \
            --region ${REGION} \
            --allow-unauthenticated \
            --set-env-vars PROJECT_ID=${PROJECT_ID},REGION=${REGION}
            
        cd ../..
    else
        echo "⚠️  Service directory not found: services/$service"
    fi
done

echo "✅ Service deployment complete!"
EOF

chmod +x scripts/deploy-services.sh

echo -e "\n${GREEN}✅ Project initialization complete!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo "1. Review the created structure"
echo "2. Run: ${YELLOW}make processors${NC} to create Document AI processors"
echo "3. Add training documents to processors/training-data/"
echo "4. Run: ${YELLOW}make train${NC} to train the processors"
echo "5. Run: ${YELLOW}make deploy${NC} to deploy services"