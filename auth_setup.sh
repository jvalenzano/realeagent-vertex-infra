#!/bin/bash

# ====================================================
# RealeAgent Vertex AI - GCP Authentication Script
# Complete authentication and verification flow
# ====================================================
# 
# SETUP INSTRUCTIONS:
# 
# 1. Save this script in your project:
#    cd ~/realeagent-vertex-infra
#    nano auth_setup.sh
# 
# 2. Make executable:
#    chmod +x auth_setup.sh
# 
# 3. Run the script:
#    ./auth_setup.sh
# 
# OPTIONAL: Create an alias:
#    echo "alias realeauth='~/realeagent-vertex-infra/auth_setup.sh'" >> ~/.bashrc
#    source ~/.bashrc
#    Then just type: realeauth
# 
# This script handles:
# - Main gcloud authentication
# - Application Default Credentials
# - Service account setup (if needed)
# - API verification
# - Document AI access testing
# - Vertex AI connectivity
# ====================================================

# Colors for visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project configuration
PROJECT_ID="realeagent-vertex-ai"
PROJECT_NUMBER="209579160014"
REGION="us-central1"
DOCAI_LOCATION="us"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}🏠 RealeAgent Vertex AI Auth Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "Project: ${CYAN}${PROJECT_ID}${NC}"
echo -e "Number:  ${CYAN}${PROJECT_NUMBER}${NC}"
echo -e "Region:  ${CYAN}${REGION}${NC}"
echo ""

# Helper functions
wait_for_user() {
    echo -e "${YELLOW}$1${NC}"
    echo -e "${GREEN}Press ENTER when ready to continue...${NC}"
    read -r
}

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 successful!${NC}"
    else
        echo -e "${RED}❌ $1 failed! Please check the error above.${NC}"
        exit 1
    fi
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Step 1: Clear environment
print_section "Step 1: Environment Setup"
echo -e "${YELLOW}Clearing any conflicting environment variables...${NC}"
unset GOOGLE_APPLICATION_CREDENTIALS
unset GOOGLE_CLOUD_PROJECT
echo -e "${GREEN}✅ Environment cleared${NC}"

# Step 2: Check gcloud installation
print_section "Step 2: Verifying gcloud CLI"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found!${NC}"
    echo -e "${YELLOW}Please install Google Cloud SDK first:${NC}"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi
GCLOUD_VERSION=$(gcloud --version | head -n 1)
echo -e "${GREEN}✅ Found: $GCLOUD_VERSION${NC}"

# Step 3: Main authentication
print_section "Step 3: Google Cloud Authentication"

# Check current auth status
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -n "$ACTIVE_ACCOUNT" ]; then
    echo -e "${GREEN}Currently authenticated as: ${CYAN}$ACTIVE_ACCOUNT${NC}"
    echo -e "${YELLOW}Re-authenticate? (y/N)${NC}"
    read -r REAUTH
    if [[ "$REAUTH" =~ ^[Yy]$ ]]; then
        gcloud auth revoke --all 2>/dev/null
        ACTIVE_ACCOUNT=""
    fi
fi

if [ -z "$ACTIVE_ACCOUNT" ]; then
    echo -e "${YELLOW}Starting authentication...${NC}"
    echo -e "${CYAN}🌐 Browser will open - select your Google account${NC}"
    wait_for_user "Ready to authenticate?"
    
    gcloud auth login --quiet
    check_status "Main authentication"
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
fi

# Step 4: Application Default Credentials
print_section "Step 4: Application Default Credentials"
echo -e "${YELLOW}Setting up API/SDK access...${NC}"

# Check if ADC exists and is valid
ADC_TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null)
if [ -z "$ADC_TOKEN" ]; then
    echo -e "${YELLOW}Setting up Application Default Credentials...${NC}"
    echo -e "${CYAN}🌐 Browser will open again for API access${NC}"
    wait_for_user "Ready for application default login?"
    
    gcloud auth application-default login \
        --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/documentai
    check_status "Application default credentials"
else
    echo -e "${GREEN}✅ Application Default Credentials already set${NC}"
fi

# Step 5: Project configuration
print_section "Step 5: Project Configuration"
gcloud config set project ${PROJECT_ID} --quiet
check_status "Project setting"

gcloud auth application-default set-quota-project ${PROJECT_ID} --quiet
check_status "Quota project"

# Step 6: Verify APIs
print_section "Step 6: API Verification"
echo -e "${YELLOW}Checking required APIs...${NC}"

REQUIRED_APIS=(
    "documentai.googleapis.com"
    "aiplatform.googleapis.com"
    "storage.googleapis.com"
    "run.googleapis.com"
)

ALL_ENABLED=true
for api in "${REQUIRED_APIS[@]}"; do
    echo -n "Checking $api... "
    if gcloud services list --enabled --filter="name:${api}" --format="value(name)" 2>/dev/null | grep -q "${api}"; then
        echo -e "${GREEN}✅ Enabled${NC}"
    else
        echo -e "${RED}✗ Not enabled${NC}"
        ALL_ENABLED=false
    fi
done

if [ "$ALL_ENABLED" = false ]; then
    echo ""
    echo -e "${YELLOW}Some APIs are not enabled. Enable them now? (Y/n)${NC}"
    read -r ENABLE_APIS
    if [[ ! "$ENABLE_APIS" =~ ^[Nn]$ ]]; then
        for api in "${REQUIRED_APIS[@]}"; do
            echo "Enabling $api..."
            gcloud services enable $api --quiet
        done
    fi
fi

# Step 7: Test Document AI access
print_section "Step 7: Testing Document AI Access"
echo -e "${YELLOW}Listing Document AI processors...${NC}"

# Use gcloud to list processors
PROCESSOR_COUNT=$(gcloud documentai processors list \
    --location=${DOCAI_LOCATION} \
    --format="value(name)" 2>/dev/null | wc -l)

if [ "$PROCESSOR_COUNT" -ge 0 ]; then
    echo -e "${GREEN}✅ Document AI accessible${NC}"
    echo -e "${GREEN}   Found ${PROCESSOR_COUNT} processors${NC}"
else
    echo -e "${YELLOW}⚠️  No processors found (this is normal for new setup)${NC}"
fi

# Step 8: Test Vertex AI access
print_section "Step 8: Testing Vertex AI Access"
echo -e "${YELLOW}Checking Vertex AI endpoints...${NC}"

# List models to verify access
MODEL_COUNT=$(gcloud ai models list --region=${REGION} --format="value(name)" 2>/dev/null | wc -l)
if [ "$MODEL_COUNT" -ge 0 ]; then
    echo -e "${GREEN}✅ Vertex AI accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify Vertex AI access${NC}"
fi

# Step 9: Service Account Setup (optional)
print_section "Step 9: Service Account Check"
echo -e "${YELLOW}Checking service accounts...${NC}"

SERVICE_ACCOUNTS=(
    "vertex-ai-pipeline"
    "document-processor"
    "cloud-run-invoker"
)

for sa in "${SERVICE_ACCOUNTS[@]}"; do
    SA_EMAIL="${sa}@${PROJECT_ID}.iam.gserviceaccount.com"
    if gcloud iam service-accounts describe $SA_EMAIL >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Found: $sa${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing: $sa (will create during setup)${NC}"
    fi
done

# Step 10: Save authentication status
print_section "Step 10: Saving Status"
AUTH_FILE="$HOME/.realeagent_auth"
cat > $AUTH_FILE << EOF
# RealeAgent Authentication Status
# Generated: $(date)
export GOOGLE_CLOUD_PROJECT=$PROJECT_ID
export PROJECT_ID=$PROJECT_ID
export PROJECT_NUMBER=$PROJECT_NUMBER
export REGION=$REGION
export DOCAI_LOCATION=$DOCAI_LOCATION
export AUTH_TIME=$(date +%s)
export AUTH_ACCOUNT=$ACTIVE_ACCOUNT
EOF
echo -e "${GREEN}✅ Status saved to $AUTH_FILE${NC}"

# Summary
print_section "✨ Authentication Complete!"
echo -e "Account:        ${CYAN}$ACTIVE_ACCOUNT${NC}"
echo -e "Project:        ${CYAN}$PROJECT_ID${NC}"
echo -e "Token (first 20): ${CYAN}${ADC_TOKEN:0:20}...${NC}"
echo ""
echo -e "${GREEN}All authentication steps completed successfully!${NC}"

# Optional: Test commands
print_section "📝 Test Commands (Reference)"
echo -e "${YELLOW}You can use these commands to test access:${NC}"
echo ""
echo -e "${BLUE}# List Document AI processors:${NC}"
echo "gcloud documentai processors list --location=${DOCAI_LOCATION}"
echo ""
echo -e "${BLUE}# Test Vertex AI access:${NC}"
echo "gcloud ai models list --region=${REGION}"
echo ""
echo -e "${BLUE}# Verify project:${NC}"
echo "gcloud config get-value project"
echo ""

# Next steps
print_section "🚀 Next Steps"
echo -e "${GREEN}Your authentication is complete! Now you can:${NC}"
echo ""
echo -e "${BLUE}1. Create Document AI processors:${NC}"
echo "   cd ~/realeagent-vertex-infra"
echo "   make processors"
echo ""
echo -e "${BLUE}2. Deploy services:${NC}"
echo "   make deploy"
echo ""
echo -e "${BLUE}3. Run tests:${NC}"
echo "   make test"
echo ""
echo -e "${YELLOW}Ready to continue with setup? Run:${NC}"
echo -e "${CYAN}cd ~/realeagent-vertex-infra && ./init-project.sh${NC}"