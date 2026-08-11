# ============================================================
# API Gateway (HTTP API) for the visitor counter.
# Mirrors the manual setup: POST /count route, integrated with
# the Lambda, CORS configured, auto-deploying $default stage.
# ============================================================

resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "ccAPI-tf"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]  # tighten to domain once I get one
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
  }
}

# The integration -- tells API Gateway HOW to talk to the Lambda.
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

# The route -- tells API Gateway WHICH path/method triggers the integration above.
resource "aws_apigatewayv2_route" "count_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "POST /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# The stage -- $default, auto-deploying, matching manual setup.
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true
}

# Permission for API Gateway to actually invoke the Lambda.
# Without this, the integration exists but calls will fail with
# a permissions error -- API Gateway needs explicit invoke rights.
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}

# Print the invoke URL after apply
output "api_invoke_url" {
  value = "${aws_apigatewayv2_api.visitor_api.api_endpoint}/count"
}
