import json

def lambda_handler(event, context):
    """
    Simple Lambda function that returns a greeting.
    Designed to work with API Gateway proxy integration.
    """
    # Log the incoming event
    print(f"Received event: {json.dumps(event, indent=2)}")

    # Extract query parameters if present
    query_params = event.get('queryStringParameters', {})
    name = query_params.get('name', 'World') if query_params else 'World'

    # Construct response
    response = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': f'Hello, {name}!',
            'timestamp': context.aws_request_id,
            'method': event.get('httpMethod', 'UNKNOWN')
        })
    }

    return response
