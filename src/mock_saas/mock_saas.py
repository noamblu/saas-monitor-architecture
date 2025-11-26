import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Log incoming headers to verify API Key presence
    headers = event.get('headers', {})
    logger.info(f"Received headers: {json.dumps(headers)}")
    
    # Check for the expected API key header (case-insensitive)
    # Note: EventBridge Connection sends the key as configured.
    # We just log it for verification in this mock.
    
    response_body = {
        "status": "ok",
        "users": [
            {"id": 1, "name": "Alice", "role": "admin"},
            {"id": 2, "name": "Bob", "role": "user"},
            {"id": 3, "name": "Charlie", "role": "viewer"}
        ],
        "message": "Data retrieved from Mock SaaS"
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
