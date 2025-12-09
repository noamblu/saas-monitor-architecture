import os
import json
import boto3
import requests
import time
import logging
import urllib3
from datetime import datetime, timezone
from response_processor import process_response

# Configure Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Disable SSL Warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_auth_headers(connection, auth_secret):
    """Generates authentication headers based on the connection type."""
    headers = {}
    auth_type = connection['AuthorizationType']
    
    if 'API_KEY' in auth_type:
        api_key_params = connection['AuthParameters']['ApiKeyAuthParameters']
        headers[api_key_params['ApiKeyName']] = auth_secret
        
    elif 'BASIC' in auth_type:
        basic_params = connection['AuthParameters']['BasicAuthParameters']
        headers['Authorization'] = f"Basic {basic_params['Username']}:{auth_secret}"
        
    elif 'OAUTH' in auth_type:
        oauth_params = connection['AuthParameters']['OAuthParameters']
        client_id = oauth_params['ClientParameters']['ClientID']
        auth_endpoint = oauth_params['AuthorizationEndpoint']
        http_method = oauth_params['HttpMethod']
        
        # Prepare data with standard grant_type
        data = {'grant_type': 'client_credentials'}
        
        # Add additional body parameters if configured
        http_params = oauth_params.get('OAuthHttpParameters', {})
        body_params = http_params.get('BodyParameters', [])
        
        for param in body_params:
            key = param.get('Key') or param.get('key')
            value = param.get('Value') or param.get('value')
            if key and value:
                data[key] = value
        
        # Fetch OAuth Token (Standard Client Credentials Flow)
        token_response = requests.request(
            method=http_method,
            url=auth_endpoint,
            auth=(client_id, auth_secret),
            data=data,
            verify=False # Disable SSL Verification
        )
        token_response.raise_for_status()
        access_token = token_response.json()['access_token']
        
        headers['Authorization'] = f"Bearer {access_token}"
        
    elif auth_type == 'NONE':
        pass
        
    return headers

def invoke_api(endpoint, headers):
    """Invokes the SaaS API and processes the response."""
    start_time = time.time()
    status = "ERROR"
    processed_items = []
    
    try:
        logger.info(f"Invoking endpoint: {endpoint}")
        response = requests.get(endpoint, headers=headers, verify=False) # Disable SSL Verification
        response.raise_for_status()
        status = "OK"
        logger.info("SaaS Health Check: OK")
        
        try:
            response_json = response.json()
            processed_items = process_response(response_json)
            logger.debug(f"Processed {len(processed_items)} items")
        except ValueError:
            logger.warning("Response was not JSON")
            processed_items = [{"text": response.text}]
            
    except Exception as e:
        status = "ERROR"
        logger.error(f"SaaS Health Check FAILED: {str(e)}")
        processed_items = [{"error": str(e)}]
        # We don't raise here, we want to publish the failure event
        
    latency_ms = (time.time() - start_time) * 1000
    return status, latency_ms, processed_items

def create_event_entries(saas_name, status, latency_ms, processed_items, event_bus_name):
    """Formats the processed items into EventBridge entries."""
    entries = []
    
    for item in processed_items:
        detail = {
            "saasName": saas_name,
            "status": status,
            "latencyMs": latency_ms,
            "checkedAt": datetime.now(timezone.utc).isoformat(),
            "rawResponse": item
        }
        
        entry = {
            "Source": f"com.saas.monitor.{saas_name}",
            "DetailType": "SaaSHealthCheckResult",
            "Detail": json.dumps(detail),
            "EventBusName": event_bus_name
        }
        entries.append(entry)
        
    return entries

def publish_events(eb_client, entries, event_bus_name):
    """Publishes events to EventBridge in batches."""
    logger.info(f"Publishing {len(entries)} events to bus: {event_bus_name}")
    
    # Chunk entries into batches of 10
    batch_size = 10
    for i in range(0, len(entries), batch_size):
        batch = entries[i:i + batch_size]
        eb_client.put_events(Entries=batch)

def handler(event, context):
    try:
        # Initialize clients
        eb_client = boto3.client('events')
        
        api_destination_name = os.environ['API_DESTINATION_NAME']
        connection_name = os.environ['CONNECTION_NAME']
        event_bus_name = os.environ['EVENT_BUS_NAME']
        saas_name = os.environ['SAAS_NAME']
        
        logger.info(f"Starting poll for SaaS: {saas_name}")
        
        # 1. Get API Destination and Connection details
        api_dest = eb_client.describe_api_destination(Name=api_destination_name)
        endpoint = api_dest['InvocationEndpoint']
        connection = eb_client.describe_connection(Name=connection_name)
        
        # 2. Get Secret
        auth_secret = os.environ.get('AUTH_SECRET')
        
        # 3. Get Auth Headers
        headers = get_auth_headers(connection, auth_secret)
        
        # 4. Invoke API
        status, latency_ms, processed_items = invoke_api(endpoint, headers)
        
        # 5. Create Events
        entries = create_event_entries(saas_name, status, latency_ms, processed_items, event_bus_name)
        
        # 6. Publish Events
        publish_events(eb_client, entries, event_bus_name)
        
        return {
            "statusCode": 200,
            "body": f"Published {len(entries)} events for {saas_name}: {status}"
        }

    except Exception as e:
        logger.critical(f"Critical Lambda Error: {str(e)}")
        raise e
