# RealeAgent Vertex AI Infrastructure

AI-powered real estate document intelligence system using Google Cloud Vertex AI, Document AI, and ADK framework.

## 🚀 Overview

This repository contains the microservices infrastructure for RealeAgent's intelligent document processing pipeline. It processes natural language queries about California real estate transactions and automatically determines required forms and compliance requirements.

## 🏗️ Architecture

```
User Query → Orchestrator → Intent Processor (Gemini 2.5 Pro)
                         ↓
                    Document Extractor (Document AI)
                         ↓
                    Compliance Validator (Business Rules)
                         ↓
                    Complete Response
```

## ✅ Services Status

| Service | Purpose | URL |
|---------|---------|-----|
| **intent-processor** | Natural language → structured data | [Live](https://intent-processor-209579160014.us-central1.run.app/health) |
| **document-extractor** | Document AI form processing | [Live](https://document-extractor-209579160014.us-central1.run.app/health) |
| **compliance-validator** | CA real estate compliance rules | [Live](https://compliance-validator-209579160014.us-central1.run.app/health) |
| **orchestrator** | Pipeline coordination | [Live](https://orchestrator-209579160014.us-central1.run.app/health) |

## 🧪 Example

```bash
curl -X POST https://orchestrator-209579160014.us-central1.run.app/process \
  -H "Content-Type: application/json" \
  -d '{"query": "Create purchase agreement for 789 Ocean View Drive, $1.2M, built 1975, 30-day escrow"}'
```

**Result**: Correctly identifies need for Lead Paint Disclosure (pre-1978 property) + all CA requirements

## 📊 Performance

- End-to-end processing: <10 seconds
- Gemini 2.5 Pro for intent extraction
- 99.9% accuracy target for financial data
- Automatic compliance validation

## 🔧 Tech Stack

- Google Cloud Run (serverless deployment)
- Vertex AI (Gemini models)
- Document AI (form processing)
- Python + Flask (microservices)
- ADK Framework (coming soon)

## 📝 Documentation

See `_docs/` folder for:
- [PROGRESS_LOG.md](_docs/PROGRESS_LOG.md) - Development history
- [DEPLOYMENT_PATTERNS.md](_docs/DEPLOYMENT_PATTERNS.md) - Deployment guide
- [SETUP_GUIDE.md](_docs/SETUP_GUIDE.md) - Initial setup

Built with ❤️ for California real estate professionals