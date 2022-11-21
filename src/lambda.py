import os
import boto3
import pandas as pd

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:            
        bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
        s3_file_name = event["Records"][0]["s3"]["object"]["key"]

        output_bucket_name = os.environ.get('OUTPUT_S3_BUCKET_NAME')

        # read the csv file down
        df=pd.read_csv(f's3://{bucket_name}/{s3_file_name}', sep=',')

        # here we do our processing
        description = df.describe()
        
        # write the csv up
        description.to_csv(f's3://{output_bucket_name}/{s3_file_name}',)

    except Exception as err:
        print(err)