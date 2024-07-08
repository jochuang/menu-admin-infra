resource "aws_s3_bucket" "menuadmin-script" {
  bucket = "menuadmin-script"

  tags = {
    Name = "menuadmin-script"
  }
}

// Update Object Ownership of the S3 bucket to Object Writer
resource "aws_s3_bucket_ownership_controls" "menuadmin_script_ownership_controls" {
  bucket = aws_s3_bucket.menuadmin-script.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

data "aws_iam_policy_document" "assume_role_codebuild" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "menudeploy-demo-service-role" {
  name               = "menudeploy-demo-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}

data "aws_iam_policy_document" "iam-policy-data" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/*"]
  }

  // Enable CodeBuild to access s3
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.menuadmin-script.arn,
      "arn:aws:s3:::menuadmin-script/*",
    ]
  }

  // Authorize Codebuild to perform action GetParameter on BitbucketPass and FirebasePass
  statement {
    effect = "Allow"
    actions = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:us-east-1:730335529715:parameter/BitbucketPass",
                "arn:aws:ssm:us-east-1:730335529715:parameter/FirebasePass"]
  }

}

resource "aws_iam_role_policy" "iam-role-policy" {
  name = "AWSCodeBuildBasicExecutionPolicy"
  role   = aws_iam_role.menudeploy-demo-service-role.name
  policy = data.aws_iam_policy_document.iam-policy-data.json
}

resource "aws_codebuild_project" "menudeploy-demo" {
  name           = "menudeploy-demo"
  description    = "(demo) deploys updated menu.js to firebase hosted restaurant webapp and updates restaurant webapp code source"
  build_timeout  = 5
  queued_timeout = 5

  service_role = aws_iam_role.menudeploy-demo-service-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  // Specify source to s3 bucket menuadmin-script 
  source {
    type      = "S3"
    location  = "menuadmin-script/"
    buildspec = file("${path.module}/buildspec.yml")
  }
}