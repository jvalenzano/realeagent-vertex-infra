# This is just the updated prompt section
    prompt = f"""Extract real estate transaction details from this request:
    "{request.user_input}"
    
    You MUST return ONLY a valid JSON object with NO additional text, markdown, or explanation.
    
    Example format:
    {{
        "form_type": "purchase_agreement",
        "property_address": "789 Ocean View Drive",
        "price": 1200000,
        "built_year": 1975,
        "escrow_days": 30,
        "contingencies": ["inspection", "loan"],
        "confidence": 0.95
    }}
    
    Extract only what is explicitly mentioned. Use null for missing values.
    """
