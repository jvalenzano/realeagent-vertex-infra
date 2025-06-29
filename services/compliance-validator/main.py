import os
import json
from flask import Flask, request, jsonify
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# California Real Estate Compliance Rules
COMPLIANCE_RULES = {
    "lead_paint": {
        "trigger": "built_before_1978",
        "description": "Federal law requires Lead-Based Paint Disclosure for properties built before 1978",
        "form_required": "lead_paint_disclosure"
    },
    "natural_hazard": {
        "trigger": "california_property",
        "description": "California requires Natural Hazard Disclosure Statement",
        "form_required": "natural_hazard_disclosure"
    },
    "earthquake": {
        "trigger": "seismic_zone",
        "description": "Properties in seismic zones require earthquake disclosure",
        "form_required": "earthquake_disclosure"
    },
    "smoke_detector": {
        "trigger": "all_properties",
        "description": "California requires smoke detector compliance statement",
        "form_required": "smoke_detector_statement"
    },
    "water_heater": {
        "trigger": "all_properties",
        "description": "Water heater bracing compliance required",
        "form_required": "water_heater_statement"
    }
}

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "compliance-validator"}), 200

@app.route('/validate', methods=['POST'])
def validate_compliance():
    try:
        data = request.get_json()
        
        # Extract property details
        property_details = data.get('property_details', {})
        transaction_type = data.get('transaction_type', 'purchase')
        
        # Initialize response
        compliance_response = {
            "compliant": True,
            "required_forms": [],
            "warnings": [],
            "recommendations": []
        }
        
        # Check Lead Paint requirement
        built_year = property_details.get('built_year')
        if built_year and int(built_year) < 1978:
            compliance_response["required_forms"].append({
                "form": "lead_paint_disclosure",
                "reason": "Property built before 1978 - Federal requirement",
                "priority": "mandatory"
            })
            logger.info(f"Lead paint disclosure required for property built in {built_year}")
        
        # Check price-based requirements
        price = property_details.get('price')
        if price and float(price) > 1000000:
            compliance_response["recommendations"].append({
                "form": "luxury_property_addendum",
                "reason": "High-value property may benefit from additional protections"
            })
        
        # Natural hazard disclosure (all CA properties)
        compliance_response["required_forms"].append({
            "form": "natural_hazard_disclosure",
            "reason": "Required for all California properties",
            "priority": "mandatory"
        })
        
        # Add standard California disclosures
        standard_forms = [
            "transfer_disclosure_statement",
            "water_heater_compliance",
            "smoke_detector_compliance"
        ]
        
        for form in standard_forms:
            compliance_response["required_forms"].append({
                "form": form,
                "reason": "Standard California requirement",
                "priority": "mandatory"
            })
        
        # Check transaction-specific requirements
        if transaction_type == "purchase":
            compliance_response["recommendations"].append({
                "form": "buyers_inspection_advisory",
                "reason": "Recommended to inform buyer of inspection rights"
            })
        
        # Validate form completeness
        submitted_forms = data.get('submitted_forms', [])
        missing_forms = []
        
        for required in compliance_response["required_forms"]:
            if required["form"] not in submitted_forms and required["priority"] == "mandatory":
                missing_forms.append(required["form"])
        
        if missing_forms:
            compliance_response["compliant"] = False
            compliance_response["warnings"].append({
                "type": "missing_forms",
                "message": f"Missing mandatory forms: {', '.join(missing_forms)}",
                "forms": missing_forms
            })
        
        # Add compliance summary
        compliance_response["summary"] = {
            "total_required": len(compliance_response["required_forms"]),
            "total_recommendations": len(compliance_response["recommendations"]),
            "is_compliant": compliance_response["compliant"],
            "checked_at": datetime.utcnow().isoformat()
        }
        
        return jsonify(compliance_response), 200
        
    except Exception as e:
        logger.error(f"Error in compliance validation: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/check_triggers', methods=['POST'])
def check_triggers():
    """Check which compliance triggers apply to a property"""
    try:
        data = request.get_json()
        property_details = data.get('property_details', {})
        
        triggered_rules = []
        
        # Check each rule
        built_year = property_details.get('built_year')
        if built_year and int(built_year) < 1978:
            triggered_rules.append({
                "rule": "lead_paint",
                "triggered": True,
                "details": COMPLIANCE_RULES["lead_paint"]
            })
        
        # All California properties trigger certain rules
        triggered_rules.extend([
            {
                "rule": "natural_hazard",
                "triggered": True,
                "details": COMPLIANCE_RULES["natural_hazard"]
            },
            {
                "rule": "smoke_detector",
                "triggered": True,
                "details": COMPLIANCE_RULES["smoke_detector"]
            },
            {
                "rule": "water_heater",
                "triggered": True,
                "details": COMPLIANCE_RULES["water_heater"]
            }
        ])
        
        return jsonify({
            "property_details": property_details,
            "triggered_rules": triggered_rules,
            "total_triggers": len(triggered_rules)
        }), 200
        
    except Exception as e:
        logger.error(f"Error checking triggers: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
