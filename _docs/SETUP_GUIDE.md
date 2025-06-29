[Paste the guide# RealeAgent Vertex AI - Setup Guide

## Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and configured
- Python 3.11 or higher
- Git

## Quick Setup

### 1. Clone the Repository
```bash
git clone https://github.com/jvalenzano/realeagent-vertex-infra.git
cd realeagent-vertex-infra
```

### 2. Run Authentication Setup
```bash
# Run the authentication script
./auth_setup.sh

# This will:
# - Set up gcloud CLI authentication
# - Configure Application Default Credentials (ADC)
# - Set the default project and region
```

### 3. Initialize the Project
```bash
# Run the initialization script
./init-project.sh

# This will:
# - Enable required Google Cloud APIs
# - Create service accounts
# - Set up IAM permissions
# - Create Artifact Registry
```

### 4. Create Document AI Processors
```bash
# Create the Document AI processors
cd processors
python3 create_processors.py

# This creates 4 processors:
# - Lead Paint Disclosure processor
# - CA RPA (Purchase Agreement) processor
# - BIA (Buyer's Inspection Advisory) processor
# - General Form Parser
```

### 5. Deploy Services
```bash
# Deploy all services (from root directory)
cd ..

# Deploy each service
for service in intent-processor document-extractor compliance-validator orchestrator; do
  cd services/$service
  gcloud run deploy $service \
    --source . \
    --region us-central1 \
    --allow-unauthenticated \
    --set-env-vars "PROJECT_ID=realeagent-vertex-ai"
  cd ../..
done
```

## Verify Deployment

### Check Service Health
```bash
# Test all services are healthy
for service in intent-processor document-extractor compliance-validator orchestrator; do
  echo "Checking $service..."
  curl https://$service-209579160014.us-central1.run.app/health
  echo
done
```

### Run Complete Pipeline Test
```bash
curl -X POST https://orchestrator-209579160014.us-central1.run.app/process \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Create purchase agreement for 789 Ocean View Drive, $1.2M, built 1975, 30-day escrow"
  }' | python3 -m json.tool
```

## Expected Results

The pipeline should:
1. Extract structured data from the natural language query
2. Identify property built in 1975 (pre-1978)
3. Require Lead Paint Disclosure
4. List all California compliance requirements
5. Complete in <10 seconds

## Service URLs

- **Intent Processor**: https://intent-processor-209579160014.us-central1.run.app
- **Document Extractor**: https://document-extractor-209579160014.us-central1.run.app
- **Compliance Validator**: https://compliance-validator-209579160014.us-central1.run.app
- **Orchestrator**: https://orchestrator-209579160014.us-central1.run.app

## Troubleshooting

### Authentication Issues
```bash
# Re-run authentication
gcloud auth login
gcloud auth application-default login
```

### Service Deployment Issues
```bash
# Check logs for a specific service
gcloud run services logs read [service-name] --region us-central1

# Check service status
gcloud run services describe [service-name] --region us-central1
```

### Common Issues

1. **Model Name Errors**: Use `gemini-1.5-pro-002` not `gemini-2.5-pro`
2. **File Corruption**: If `__name__` becomes `**name**`, fix with:
   ```bash
   sed -i '' 's/\*\*name\*\*/\__name__/' main.py
   ```
3. **Field Name Mismatches**: Ensure services agree on JSON field names

## Environment Variables

Required environment variables (set automatically during deployment):
- `PROJECT_ID`: Your Google Cloud project ID
- `GOOGLE_CLOUD_PROJECT`: Same as PROJECT_ID
- `PORT`: Set by Cloud Run (usually 8080)

## Next Steps

1. **Test with Different Queries**: Try various property scenarios
2. **Monitor Performance**: Use Cloud Monitoring dashboards
3. **Integrate with ADK**: Connect to DocumentAgent
4. **Add Caching**: Implement Redis for common queries

## Resources

- [Google Cloud Console](https://console.cloud.google.com)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Document AI Documentation](https://cloud.google.com/document-ai/docs)

---

*For detailed development history, see [PROGRESS_LOG.md](_docs/PROGRESS_LOG.md)* content here]
