# ============================================================
# IAM role + policy for the visitor-counter Lambda.
# Mirrors what was built by hand: a role Lambda can assume,
# with an inline policy granting ONLY dynamodb:UpdateItem on
# the one table it needs -- least privilege, not full access.
# ============================================================

# The "trust policy" -- says WHO is allowed to assume this role.
# For a Lambda execution role, that's always the Lambda service itself.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The actual role, using the trust policy above.
resource "aws_iam_role" "lambda_exec_role" {
  name               = "visitor-counter-lambda-role-tf"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attach the AWS-managed policy that lets Lambda write its own logs to CloudWatch.
# This is standard/expected for every Lambda, not specific to DynamoDB access.
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The least-privilege policy: ONLY dynamodb:UpdateItem, ONLY on this one table.
# This is the Terraform version of the inline JSON policy you wrote by hand.
data "aws_iam_policy_document" "dynamodb_update_only" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.visitor_count.arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_update_policy" {
  name   = "dynamodb-update-only-tf"
  role   = aws_iam_role.lambda_exec_role.id
  policy = data.aws_iam_policy_document.dynamodb_update_only.json
}
