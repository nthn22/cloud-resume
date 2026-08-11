# ============================================================
# GitHub Actions OIDC setup.
# This lets GitHub Actions assume an AWS IAM role using short-
# lived tokens -- no long-lived access keys stored as secrets.
# ============================================================

# Register GitHub's OIDC provider with AWS (one-time trust setup).
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's OIDC thumbprint -- this is a well-known, stable value
  # published by GitHub/AWS for this exact purpose.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# The trust policy: only allow GitHub Actions workflows running
# from repo to assume this role
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:nthn22/cloud-resume:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Permissions the deploy role needs: S3 sync, CloudFront invalidation,
# and enough to run terraform apply
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.website.arn,
      "${aws_s3_bucket.website.arn}/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.website.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction"
    ]
    resources = [aws_lambda_function.visitor_counter.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy_policy" {
  name   = "github-actions-deploy-permissions"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}
