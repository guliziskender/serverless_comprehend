import boto3
import base64

def lambda_handler(event, context):

    output = []

    for record in event['records']:
        data = base64.b64decode(record['data']).decode('utf-8')

        comprehend_client = boto3.client('comprehend')

        response = comprehend_client.batch_detect_dominant_language(
            TextList=[data, ]
        )
        print("result is:")
        print(response['ResultList'][0]['Languages'][0]['LanguageCode'])

    return response

