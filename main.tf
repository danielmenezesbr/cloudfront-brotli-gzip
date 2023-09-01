provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "bucket_suffix" {
  length = 4
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "myprivatebucket-${random_pet.bucket_suffix.id}"
}

resource "aws_cloudfront_origin_access_identity" "example_access_identity" {
  comment = "CloudFront access identity for private bucket"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.private_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.example_access_identity.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.private_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.private_bucket.id
  key    = "index.html"
  source = "content/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "style_css" {
  bucket = aws_s3_bucket.private_bucket.id
  key    = "style.css"
  source = "content/style.css"
  content_type = "text/css"
}

resource "aws_s3_object" "style_min_css" {
  bucket = aws_s3_bucket.private_bucket.id
  key    = "style.min.css"
  source = "content/style.min.css"
  content_type = "text/css"
}

# AWS Cloudfront for caching
data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized" # gzip and brotli
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.private_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Managed by Terraform"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"
    compress = true
    cache_policy_id = data.aws_cloudfront_cache_policy.this.id

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}