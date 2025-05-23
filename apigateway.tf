############################################################
# CloudWatch Log Group for API Gateway.
############################################################

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = var.apigw_log_retention
}

############################################################
# API Gateway HTTP API.
############################################################

resource "aws_apigatewayv2_api" "lambda" {
  name          = "apigw-http-lambda"
  protocol_type = "HTTP"
  description   = "API Gateway HTTP API integrated with AWS Lambda for Gremlin Failure Flags demo"

  cors_configuration {
    allow_credentials = false
    allow_headers     = []
    allow_methods     = ["GET", "HEAD", "OPTIONS", "POST"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 0
  }
}

############################################################
# Integration between API Gateway and Lambda.
############################################################

resource "aws_apigatewayv2_integration" "app" {
  api_id                 = aws_apigatewayv2_api.lambda.id
  integration_uri        = aws_lambda_function.app.invoke_arn
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  payload_format_version = "1.0"
}

############################################################
# Default Route for API Gateway.
############################################################

resource "aws_apigatewayv2_route" "any" {
  api_id             = aws_apigatewayv2_api.lambda.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
  authorization_type = "NONE"
}

############################################################
# Stage for API Gateway with access logging.
############################################################

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  depends_on = [aws_cloudwatch_log_group.api_gw]
}

############################################################
# Lambda Permission for API Gateway invocation.
############################################################

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

