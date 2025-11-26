import json
import logging
import boto3
import datetime
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

events_client = boto3.client('events')
cloudwatch_client = boto3.client('cloudwatch')

def lambda_handler(event, context):
    # The event received here is the output from the Pipe's enrichment step (the API response)
    # or the final payload sent to the target.
    
    logger.info("Received event from EventBridge Pipe:")
    logger.info(json.dumps(event, indent=2))
    
    bus_name = os.environ.get('EVENT_BUS_NAME', 'default')

    # 1. Send event to EventBridge Custom Bus
    try:
        events_response = events_client.put_events(
            Entries=[
                {
                    'Source': 'com.saas.monitor',
                    'DetailType': 'SaaS Health Check',
                    'Detail': json.dumps(event),
                    'EventBusName': bus_name
                }
            ]
        )
        logger.info(f"Event sent to EventBridge: {events_response['Entries']}")
    except Exception as e:
        logger.error(f"Failed to send event to EventBridge: {e}")

    # 2. Push metric to CloudWatch
    # We'll assume if we got here, the check was successful (1). 
    # In a real app, you'd parse 'event' to determine success/failure.
    try:
        cloudwatch_client.put_metric_data(
            Namespace='SaaSMonitor',
            MetricData=[
                {
                    'MetricName': 'SaaSHealthCheck',
                    'Dimensions': [
                        {
                            'Name': 'Service',
                            'Value': 'MockSaaS'
                        },
                    ],
                    'Timestamp': datetime.datetime.now(),
                    'Value': 1.0,
                    'Unit': 'Count'
                },
            ]
        )
        logger.info("Metric sent to CloudWatch")
    except Exception as e:
        logger.error(f"Failed to send metric to CloudWatch: {e}")
    
    return {
        "status": "processed",
        "event_received": True
    }
