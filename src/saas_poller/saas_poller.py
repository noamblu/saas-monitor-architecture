import os
import json
import boto3
import requests

def handler(event, context):
    # Initialize clients
    eb_client = boto3.client('events')
    
    api_destination_name = os.environ['API_DESTINATION_NAME']
    connection_name = os.environ['CONNECTION_NAME']
    event_bus_name = os.environ['EVENT_BUS_NAME']
    
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
        # We assume the provider accepts Basic Auth for client_id:client_secret
        # and grant_type=client_credentials in the body.
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
    
    # 3. Invoke the API
    response = requests.get(endpoint, headers=headers)
    response.raise_for_status()
    
    data = response.json()
    
    # 4. Split response into individual events
    entries = []
    if isinstance(data, list):
        for item in data:
            entries.append({
                "Source": "com.saas.monitor",
                "DetailType": "ApiItem",
                "Detail": json.dumps(item),
                "EventBusName": event_bus_name
            })
    else:
        # If response is a single object, wrap it
        entries.append({
            "Source": "com.saas.monitor",
            "DetailType": "ApiItem",
            "Detail": json.dumps(data),
            "EventBusName": event_bus_name
        })
    
    # 5. Publish events to EventBridge
    # Batch in chunks of 10 (EventBridge limit)
    for i in range(0, len(entries), 10):
        batch = entries[i:i+10]
        eb_client.put_events(Entries=batch)
    
    return {
        "statusCode": 200,
        "body": f"Published {len(entries)} events to {event_bus_name}"
    }
