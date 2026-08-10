"""
Unit tests for the visitor counter Lambda function.
 
Uses moto to mock DynamoDB entirely in-memory
"""
 
import boto3
import pytest
from moto import mock_aws
 
# Import the actual Lambda handler we're testing.
# Assumes lambda_function.py lives in the same folder as this test file.
from lambda_function import lambda_handler
 
 
TABLE_NAME = "visitor-count"
 
 
@pytest.fixture
def dynamodb_table():
    """
    Spins up a fake in-memory DynamoDB table before each test,
    seeded with the same starting item your real table has
    (id='count', visits=0), and tears it down after.
    """
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
 
        table = dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        table.wait_until_exists()
 
        # Seed the starting item, matching your real table's initial state.
        table.put_item(Item={"id": "count", "visits": 0})
 
        yield table
        # mock_aws() context manager tears everything down automatically on exit
 
 
def test_increments_count_by_one(dynamodb_table):
    """Calling the Lambda once should bump visits from 0 to 1."""
    response = lambda_handler({}, {})
 
    assert response["statusCode"] == 200
 
    import json
    body = json.loads(response["body"])
    assert body["count"] == 1
 
 
def test_increments_count_across_multiple_calls(dynamodb_table):
    """Calling the Lambda three times in a row should land on 3."""
    import json
 
    lambda_handler({}, {})
    lambda_handler({}, {})
    third_response = lambda_handler({}, {})
 
    body = json.loads(third_response["body"])
    assert body["count"] == 3
 
 
def test_response_body_is_valid_json(dynamodb_table):
    """The response body should be a JSON string, not a raw Decimal or int."""
    import json
 
    response = lambda_handler({}, {})
 
    # This will raise if body isn't valid JSON -- e.g. if the Decimal
    # serialization bug ever crept back in, this test would catch it.
    body = json.loads(response["body"])
    assert isinstance(body, dict)
    assert "count" in body
    assert isinstance(body["count"], int)  # not a Decimal, not a string
 
 
def test_status_code_is_200(dynamodb_table):
    """Sanity check: a successful call always returns HTTP 200."""
    response = lambda_handler({}, {})
    assert response["statusCode"] == 200