# Create an IAM policy document - assume role policy - for the lambda IAM role
data "aws_iam_policy_document" "assume_role_lambda" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create a lambda IAM role and define the assume role policy
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

# Create a custom managed IAM policy
resource "aws_iam_policy" "AWSLambdaLoggingPolicy" {
  name        = "AWSLambdaLoggingPolicy"
  description = "Custom managed AWS Lambda logging policy for ${var.account_id}."
  # jsonencode function converts a Terraform expression result to valid JSON syntax
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # {
      #   Effect   = "Allow",
      #   Action   = "logs:CreateLogGroup",
      #   Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      # },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"
        ]
      }
    ]
  })
}

# Attach the custom managed IAM role policy to the lambda IAM role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.AWSLambdaLoggingPolicy.arn
}

# Create a custom managed IAM policy
resource "aws_iam_policy" "AWSCodebuildStartBuildPolicy" {
  name        = "AWSCodebuildStartBuildPolicy"
  description = "Custom managed AWS CodeBuild basic execution role policy for ${var.account_id}."
  # jsonencode function converts a Terraform expression result to valid JSON syntax
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "codebuild:StartBuild",
        Resource = "arn:aws:codebuild:${var.region}:${var.account_id}:project/menudeploy-demo"
      }
    ]
  })
}

# Attach the CodeBuildBasicExecutionRole policy to the lambda IAM role
resource "aws_iam_role_policy_attachment" "AWSCodeBuildDeveloperAccess" {
  role      = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.AWSCodebuildStartBuildPolicy.arn
}

# Upload python script to Lambda by creating a zip
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "codebuild-trigger-demo" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/lambda_function.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"

  # source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.8"

  # CloudWatch Logging Permissions for Lambda
  logging_config {
    log_format = "Text"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.cloudwatch-log-group,
  ]
}

# Create a CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codebuild-trigger-demo.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.menu-admin-demo.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.menu-admin-demo.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.codebuild-trigger-demo.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "menu"
    filter_suffix       = ".js"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# # See also the following AWS managed policy: AWSLambdaBasicExecutionRole
# data "aws_iam_policy_document" "lambda_logging" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#     ]

#     resources = ["arn:aws:logs:*:*:*"]
#   }
# }
# #CloudWatch Logging Permissions for Lambda
# resource "aws_iam_policy" "lambda_logging" {
#   name        = "lambda_logging"
#   path        = "/"
#   description = "IAM policy for logging from a lambda"
#   policy      = data.aws_iam_policy_document.lambda_logging.json
# }

# resource "aws_iam_role_policy_attachment" "lambda_logs" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = aws_iam_policy.lambda_logging.arn
# }
