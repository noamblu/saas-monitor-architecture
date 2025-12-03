import os
import json
import boto3
import requests
import time
from datetime import datetime, timezone

def handler(event, context):
    # Initialize clients
    eb_client = boto3.client('events')
    
    api_destination_name = os.environ['API_DESTINATION_NAME']
    connection_name = os.environ['CONNECTION_NAME']
    event_bus_name = os.environ['EVENT_BUS_NAME']
    saas_name = os.environ['SAAS_NAME']
    
    # 1. Get API Destination details
    api_dest = eb_client.describe_api_destination(Name=api_destination_name)
    endpoint = api_dest['InvocationEndpoint']
    
    # 2. Get Connection details for authentication
    connection = eb_client.describe_connection(Name=connection_name)
    auth_type = connection['AuthorizationType']
    
    # 3. Get Secret from Env (DescribeConnection does not return secrets)
    auth_secret = os.environ.get('AUTH_SECRET')

    headers = {}
    if auth_type == 'API_KEY':
        api_key_params = connection['AuthParameters']['ApiKeyAuthParameters']
        headers[api_key_params['ApiKeyName']] = auth_secret
    elif auth_type == 'BASIC':
        basic_params = connection['AuthParameters']['BasicAuthParameters']
        headers['Authorization'] = f"Basic {basic_params['Username']}:{auth_secret}"
    elif auth_type == 'OAUTH':
        oauth_params = connection['AuthParameters']['OAuthParameters']
        client_id = oauth_params['ClientParameters']['ClientID']
        auth_endpoint = oauth_params['AuthorizationEndpoint']
        http_method = oauth_params['HttpMethod']
        
        # Fetch OAuth Token (Standard Client Credentials Flow)
        token_response = requests.request(
            method=http_method,
            url=auth_endpoint,
            auth=(client_id, auth_secret),
            data={'grant_type': 'client_credentials'}
        )
        token_response.raise_for_status()
        access_token = token_response.json()['access_token']
        
        headers['Authorization'] = f"Bearer {access_token}"
    elif auth_type == 'NONE':
        pass
    
    # 4. Invoke the API and measure latency
    start_time = time.time()
    status = "ERROR"
    raw_response = {}
    
    try:
        response = requests.get(endpoint, headers=headers)
        response.raise_for_status()
        status = "OK"
        try:
            raw_response = response.json()
        except ValueError:
            raw_response = {"text": response.text}
            
    except Exception as e:
        status = "ERROR"
        raw_response = {"error": str(e)}
        # We don't raise here, we want to publish the failure event
        
    latency_ms = (time.time() - start_time) * 1000
    
    # 5. Construct Event
    detail = {
        "saasName": saas_name,
        "status": status,
        "latencyMs": latency_ms,
        "checkedAt": datetime.now(timezone.utc).isoformat(),
        "rawResponse": raw_response
    }
    
    entry = {
        "Source": f"saas.{saas_name}",
        "DetailType": "SaaSHealthCheckResult",
        "Detail": json.dumps(detail),
        "EventBusName": event_bus_name
    }
    
    # 6. Publish event to EventBridge
    eb_client.put_events(Entries=[entry])
    
    return {
        "statusCode": 200,
        "body": f"Published health check for {saas_name}: {status}"
    }
