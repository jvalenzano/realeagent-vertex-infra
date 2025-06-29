# RealeAgent Vertex AI - Deployment Patterns & Gotchas

## 🚀 Proven Deployment Method

### Cloud Run Source Deployment (USE THIS)
```bash
# Standard deployment command for all services
gcloud run deploy [service-name] \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "PROJECT_ID=realeagent-vertex-ai"
```

**Why this works:**
- Cloud Run automatically detects Python
- Uses Google Cloud Buildpacks
- No Dockerfile needed
- Handles all containerization automatically

### Service File Structure
```
service-name/
├── main.py           # Entry point (NOT app.py)
├── requirements.txt  # Python dependencies
└── [NO Dockerfile]   # Let Cloud Run handle it
```

## ✅ Successfully Deployed Services

| Service | URL | Status | Session |
|---------|-----|--------|---------|
| intent-processor | https://intent-processor-209579160014.us-central1.run.app | ✅ Live | Session 1 |
| document-extractor | https://document-extractor-209579160014.us-central1.run.app | ✅ Live | Session 2 |
| compliance-validator | Pending | ⏳ | Session 2 |
| orchestrator | Pending | ⏳ | Session 2 |

## ❌ Patterns to Avoid

### 1. Manual Dockerfile Creation
- **Issue**: Attempted in Session 1, caused deployment problems
- **Solution**: Use `--source .` flag instead
- **Why**: Cloud Run's buildpacks handle Python detection and container creation

### 2. Using app.py as entry point
- **Issue**: Inconsistent with working services
- **Solution**: Always use `main.py`
- **Pattern**: All services should follow the same naming convention

## 🐛 Common Gotchas & Solutions

### 1. Markdown Corruption in File Creation
**Problem**: Using cat with EOF can corrupt special characters
- `__name__` becomes `**name**`
- `__main__` becomes `**main**`

**Solution**: Always verify after creation
```bash
tail -5 main.py  # Check for corrupted underscores
# If corrupted, fix with:
sed -i '' 's/\*\*name\*\*/\__name__/' main.py
```

### 2. Model Name Issues (Vertex AI)
**Problem**: Vertex AI model names differ from AI Studio
- **Wrong**: "gemini-2.0-flash-exp", "gemini-2.5-pro"
- **Right**: "gemini-1.5-pro-002", "gemini-1.5-flash-002"

**Working Configuration**:
```python
model = GenerativeModel("gemini-1.5-pro-002")  # This works!
```

### 3. JSON Response Parsing
**Problem**: Gemini may wrap JSON responses in markdown code blocks

**Solution**: Extract JSON from markdown
```python
def extract_json_from_response(response_text):
    if "```json" in response_text:
        json_start = response_text.find("```json") + 7
        json_end = response_text.find("```", json_start)
        json_str = response_text[json_start:json_end].strip()
    else:
        json_str = response_text.strip()
    return json.loads(json_str)
```

### 4. Package Version Conflicts
**Problem**: vertexai and google-cloud-aiplatform version mismatch
**Solution**: Use matching versions
```txt
vertexai==1.71.1
google-cloud-aiplatform==1.71.1
```

## ✅ Pre-Deployment Checklist

Before deploying any service:
- [ ] File is named `main.py` (not app.py)
- [ ] No Dockerfile in directory
- [ ] requirements.txt is present
- [ ] Verify no corrupted underscores in Python files
- [ ] Test locally if possible
- [ ] Use proven deployment command above

## 📊 Testing Endpoints

### Intent Processor Test
```bash
curl -X POST https://intent-processor-209579160014.us-central1.run.app/process \
  -H "Content-Type: application/json" \
  -d '{"query": "Create purchase agreement for 789 Ocean View Drive, $1.2M, built 1975, 30-day escrow"}'
```

### Document Extractor Test
```bash
curl https://document-extractor-209579160014.us-central1.run.app/health
```

## 🔧 Debugging Commands

```bash
# View service logs
gcloud run services logs read [service-name] --region us-central1

# List all services
gcloud run services list --region us-central1

# Get service details
gcloud run services describe [service-name] --region us-central1
```

## 🛠️ Service Creation Helper

To avoid the `__name__` corruption issue, use the helper script:

```bash
# Create a new service
./tools/create_service.sh <service-name>

# Example:
./tools/create_service.sh form-generator

## 📝 Session History

### Session 1 Achievements
- Set up authentication and project
- Created Document AI processors
- Deployed intent-processor with Gemini 1.5 Pro
- Discovered Dockerfile issues, switched to --source deployment

### Session 2 Progress
- Documented deployment patterns
- Fixed main.py naming convention
- Deployed document-extractor service
- Ready for compliance-validator and orchestrator

---

*Last Updated: Session 2 - Document Extractor Deployed*