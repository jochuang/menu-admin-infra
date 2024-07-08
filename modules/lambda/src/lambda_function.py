import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('codebuild', region_name='us-east-1')
    response = client.start_build(
        projectName = 'menudeploy-demo'    
    )
    print(response)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
