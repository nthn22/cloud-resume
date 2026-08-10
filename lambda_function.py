import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitor-count')

def lambda_handler(event, context):
    response = table.update_item(
        Key={'id': 'count'},
        UpdateExpression='SET visits = visits + :val',
        ExpressionAttributeValues={':val': 1},
        ReturnValues='UPDATED_NEW'
    )

    new_count = response['Attributes']['visits']

    return {
        'statusCode': 200,
        'body': json.dumps({'count': int(new_count)})
    }