variable "lambda_function_name" {
  default = "codebuild-trigger-demo"
}

variable "region" {
  description = "The AWS region where resources reside"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}