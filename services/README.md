# RealeAgent Vertex AI Services

## Overview
These microservices power the RealeAgent AI document intelligence system, processing natural language queries into completed California real estate forms.

## Services

| Service | Purpose | Status | Endpoint |
|---------|---------|--------|----------|
| **intent-processor** | Extracts structured data from natural language using Gemini 2.5 Pro | ✅ Live | [Health Check](https://intent-processor-209579160014.us-central1.run.app/health) |
| **document-extractor** | Processes forms using Document AI, extracts fields and entities | ✅ Live | [Health Check](https://document-extractor-209579160014.us-central1.run.app/health) |
| **compliance-validator** | Enforces California real estate rules (e.g., pre-1978 → Lead Paint) | ✅ Live | [Health Check](https://compliance-validator-209579160014.us-central1.run.app/health) |
| **orchestrator** | Coordinates all services to handle complete document workflows | 🚀 Deploying | - |

## Flow Diagram
```
User Query → Orchestrator → Intent Processor (Gemini AI)
                         ↓
                    Document Extractor (Document AI)
                         ↓
                    Compliance Validator (Business Rules)
                         ↓
                    Complete Response
```

## Example Query
```bash
"Create purchase agreement for 789 Ocean View Drive, $1.2M, built 1975, 30-day escrow"
```

**Expected Result:**
- Extracts: address, price ($1.2M), year (1975), escrow period (30 days)
- Identifies: CA_RPA form needed
- Triggers: Lead Paint Disclosure (pre-1978 property)
- Returns: Complete form package with compliance

## Quick Test
```bash
# Test the complete pipeline (once orchestrator is deployed)
curl -X POST https://orchestrator-209579160014.us-central1.run.app/process \
  -H "Content-Type: application/json" \
  -d '{"query": "Create purchase agreement for 789 Ocean View Drive, $1.2M, built 1975, 30-day escrow"}'
```

## Service Details

### Intent Processor
- **Model**: Gemini 2.5 Pro
- **Function**: Natural language → structured data
- **Endpoint**: `/process`

### Document Extractor  
- **Processors**: 4 Document AI processors (Lead Paint, CA RPA, BIA, Form Parser)
- **Function**: Extract fields from PDFs
- **Endpoints**: `/extract`, `/extract_from_intent`

### Compliance Validator
- **Rules**: California real estate regulations
- **Function**: Validate requirements and trigger mandatory forms
- **Endpoints**: `/validate`, `/check_triggers`

### Orchestrator
- **Function**: Pipeline coordination
- **Endpoints**: `/process`, `/pipeline`
- **Integrates**: All services into unified workflow

The README provides a quick reference for what each service does and how they work together. Perfect for when you're navigating the codebase later!