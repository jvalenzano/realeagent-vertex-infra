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
