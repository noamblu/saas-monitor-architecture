from datetime import datetime, timezone

def process_response(response_json):
    """
    Process the generic SaaS API response.
    
    Args:
        response_json (dict): The JSON response from the SaaS API.
        
    Returns:
        dict: Processed response data.
    """
    # Ensure we always return a list of dictionaries.
    # Each item in the list will become a separate EventBridge event.
    
    if isinstance(response_json, list):
        # If it's already a list, return it as is (assuming items are dicts)
        # We can add metadata to each item if needed
        return [
            {"raw": item, "processed_at": datetime.now(timezone.utc).isoformat()} 
            if isinstance(item, dict) else {"raw": item, "type": str(type(item))}
            for item in response_json
        ]
        
    elif isinstance(response_json, dict):
        result = {
            "raw": response_json,
            "processed_at": str(response_json.get("timestamp", datetime.now(timezone.utc).isoformat()))
        }
        return [result]
        
    else:
        # Handle primitives
        return [{"raw": response_json, "type": str(type(response_json))}]
