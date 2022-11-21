//
// Policies
//

resource "aws_iam_role" "lambda_role" {
  name               = "s3-lambda-pipeline-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "s3-lambda-pipeline-lambda-role-policy"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   },
   {
        "Effect": "Allow",
        "Action": [
            "s3:*"
        ],
        "Resource": "arn:aws:s3:::*"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

// this lets our lambda get invoked by S3
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

//
// Buckets
//

resource "aws_s3_bucket" "output" {
  bucket = "s3-lambda-pipeline-output"
}

resource "aws_s3_bucket" "lambda" {
  bucket = "s3-lambda-pipeline-lambda"
}

resource "aws_s3_object" "file_upload" {
  bucket = aws_s3_bucket.lambda.id
  key    = "s3-lambda-pipeline.zip"
  source = "${path.module}/../s3-lambda-pipeline.zip" # its mean it depended on zip
  // this makes TF recognize that the zip has changed
  source_hash = data.archive_file.zip_the_python_code.output_base64sha256
}

// this is how you zip code and use it in other resources
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/../package/code"
  output_path = "${path.module}/../s3-lambda-pipeline.zip"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-lambda-pipeline-source"
}

//
// Lambda
//

resource "aws_lambda_function" "terraform_lambda_func" {
  function_name = "s3-lambda-pipeline-lambda"
  s3_bucket     = aws_s3_bucket.lambda.bucket
  s3_key        = aws_s3_object.file_upload.key
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"
  timeout = 60
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  // this makes TF recognize that the zip has changed
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  environment {
    variables = {
      OUTPUT_S3_BUCKET_NAME = "${aws_s3_bucket.output.bucket}"
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.terraform_lambda_func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}