# S3 -> Lambda Pipeline

#### A simple event-driven pipeline that allows for processing on S3 files after upload

We are using Python+Pandas to do some basic data stuff.

## Quickstart
1. `cd src` and `pip3 install --target ./packages -r requirements.txt`
1. `cd ../terraform` and `terraform init`
1. `terraform apply`

![Arch Diagram](./resources/s3-lambda-pipeline.png)