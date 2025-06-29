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
