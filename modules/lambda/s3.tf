resource "aws_s3_bucket" "menu-admin-demo" {
  bucket = "menu-admin-demo"

  tags = {
    Name = "menu-admin-demo"
  }

}

resource "aws_s3_bucket_ownership_controls" "menu-admin-bucket-ownership-controls" {
  bucket = aws_s3_bucket.menu-admin-demo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "menu-admin-bucket-access-block" {
  bucket = aws_s3_bucket.menu-admin-demo.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "menu-admin-bucket-acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.menu-admin-bucket-ownership-controls,
    aws_s3_bucket_public_access_block.menu-admin-bucket-access-block,
  ]

  bucket = aws_s3_bucket.menu-admin-demo.id
  acl    = "public-read"
}

// Bucket Policy
resource "aws_s3_bucket_policy" "menu-admin-bucket-policy" {
  bucket = aws_s3_bucket.menu-admin-demo.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id = "PolicyForPublicWebsiteContent"
    Statement = [
      {
        Sid = "PublicREadGetObject"
        Effect = "Allow"
        Principal = {
          "AWS" = "*"
        }
        Action = "s3:GetObject"
        Resource = [
          aws_s3_bucket.menu-admin-demo.arn,
          "${aws_s3_bucket.menu-admin-demo.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = [
           aws_s3_bucket.menu-admin-demo.arn,
          "${aws_s3_bucket.menu-admin-demo.arn}/*"
        ]
      }
    ]
  })
}

# Permissions - Cross-origin resource sharing (CORS)
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.menu-admin-demo.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}