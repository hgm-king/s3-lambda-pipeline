import boto3
import pandas as pd

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print("Starting S3 loader Lambda!")
    try:            
        bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
        s3_file_name = event["Records"][0]["s3"]["object"]["key"]
        print("Starting S3 loader Lambda!")
        # This 'magic' needs s3fs (https://pypi.org/project/s3fs/)
        df=pd.read_csv(f's3://{bucket_name}/{s3_file_name}', sep=',')

        print (df.head())

    except Exception as err:
        print(err)