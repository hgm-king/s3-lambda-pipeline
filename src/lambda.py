import os
import boto3
import pandas as pd

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:            
        bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
        s3_file_name = event["Records"][0]["s3"]["object"]["key"]

        output_bucket_name = os.environ.get('OUTPUT_S3_BUCKET_NAME')
        # This 'magic' needs s3fs (https://pypi.org/project/s3fs/)
        df=pd.read_csv(f's3://{bucket_name}/{s3_file_name}', sep=',')

        description = df.describe()
        
        description.to_csv(f's3://{output_bucket_name}/{s3_file_name}',)

    except Exception as err:
        print(err)