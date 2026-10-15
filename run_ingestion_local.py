"""
Local stand-in for the AWS Lambda ingestion pipeline.
Runs the ordering API's test-batch generator, then reuses the exact same
ingestion logic that lambda_Function.py would run inside real AWS Lambda --
just pointed at my local API and my own S3 bucket instead of ngrok. 
"""

import json

import boto3
import urllib3

import lambda_Function as lf

# ============================================================
# POINT THE INGESTION LOGIC AT *MY* BUCKET AND THE LOCAL API
# ============================================================

BUCKET = "yassin-s3-bucket-161828268081-eu-north-1-an"
REGION = "eu-north-1"
LOCAL_API = "http://127.0.0.1:8000"

lf.BUCKET = BUCKET
lf.API_URL = f"{LOCAL_API}/api/orders"
lf.s3 = boto3.client("s3", region_name=REGION)

http = urllib3.PoolManager()


def generate_test_orders(n=100):
    """Ask the local ordering API to create n random orders (max 100/call)."""
    resp = http.request("POST", f"{LOCAL_API}/orders/test-batch/{n}")
    print(f"Generated batch of {n}: HTTP {resp.status}")
    return resp.status == 200


if __name__ == "__main__":

    for _ in range(3):
        generate_test_orders(100)

    result = lf.lambda_handler({}, None)
    print(json.dumps(result, indent=2))
