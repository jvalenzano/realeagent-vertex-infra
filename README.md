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
