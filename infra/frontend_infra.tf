# ============================================================
# S3 + CloudFront + OAC for the resume website.
# Mirrors the manual setup: private S3 bucket, served only
# through CloudFront via Origin Access Control, HTTPS enforced.
# ============================================================

# --- S3 bucket ---
resource "aws_s3_bucket" "website" {
  bucket = "nthnz-cloud-resume-tf"  # must be globally unique -- change if taken
}

# Block ALL public access from the start -- unlike the manual build,
# we never need a "public first, then lock down" step here, since
# OAC + bucket policy handle access from day one.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload the three website files. (In Phase 6/CI-CD, this manual
# upload gets replaced by a GitHub Actions "aws s3 sync" step --
# for now, Terraform pushes them directly.)
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../frontend/index.html")
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  source       = "${path.module}/../frontend/styles.css"
  content_type = "text/css"
  etag         = filemd5("${path.module}/../frontend/styles.css")
}

resource "aws_s3_object" "counter_js" {
  bucket       = aws_s3_bucket.website.id
  key          = "counter.js"
  source       = "${path.module}/../frontend/counter.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/../frontend/counter.js")
}

# --- Origin Access Control ---
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-site-oac-tf"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- CloudFront distribution ---
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-resume-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "s3-resume-origin"
    viewer_protocol_policy  = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # using the *.cloudfront.net cert -- no custom domain yet
  }
}

# --- Bucket policy: only CloudFront (via OAC) can read the bucket ---
data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

# Print the live CloudFront URL after apply.
output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.website.domain_name}"
}
