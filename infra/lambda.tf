# ============================================================
# The visitor-counter Lambda function.
# Terraform's archive_file data source auto-zips the Python
# code from ../backend/lambda_function.py -- no manual zipping.
# ============================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = "visitor-counter-tf"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"  # file_name.function_name
  runtime       = "python3.13"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  # source_code_hash tells Terraform "redeploy if the code changed"
}
