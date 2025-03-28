terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

############################################################
# Read the pre-built Lambda zip file from local disk.
############################################################

data "local_file" "lambda_zip" {
  filename = "${path.module}/${var.zipfile}"
}

############################################################
# Load Gremlin sensitive credentials from local files.
############################################################

data "local_file" "gremlin_team_id" {
  filename = var.gremlin_team_id_path
}

data "local_sensitive_file" "gremlin_team_certificate" {
  filename = var.gremlin_team_certificate_path
}

data "local_sensitive_file" "gremlin_team_private_key" {
  filename = var.gremlin_team_private_key_path
}

############################################################
# Lambda Function and CloudWatch Log Group
############################################################

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.lambda_log_retention
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "app" {
  function_name    = var.lambda_name
  description      = "API Gateway HTTP API integration pattern with Gremlin Failure Flags"
  filename         = "${path.module}/${var.zipfile}"
  source_code_hash = data.local_file.lambda_zip.content_sha256
  runtime          = "python3.9"
  handler          = "LambdaFunction.handler"
  role             = aws_iam_role.lambda_exec.arn

  # Add the Gremlin Failure Flags Lambda layer.
  layers = [var.gremlin_layer_arn]

  # Set environment variables including Gremlin credentials (sourced from sensitive files)
  environment {
    variables = {
      FAILURE_FLAGS_ENABLED    = "true"
      GREMLIN_LAMBDA_ENABLED   = "true"
      GREMLIN_DEBUG            = "true"
      GREMLIN_TEAM_ID          = data.local_file.gremlin_team_id.content
      GREMLIN_TEAM_CERTIFICATE = data.local_sensitive_file.gremlin_team_certificate.content
      GREMLIN_TEAM_PRIVATE_KEY = data.local_sensitive_file.gremlin_team_private_key.content
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log]
}

############################################################
# API Gateway HTTP API and Integrations
############################################################

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = var.apigw_log_retention
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "apigw-http-lambda"
  protocol_type = "HTTP"
  description   = "API Gateway HTTP API and AWS Lambda function integration"

  cors_configuration {
    allow_credentials = false
    allow_headers     = []
    allow_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "POST",
    ]
    allow_origins  = ["*"]
    expose_headers = []
    max_age        = 0
  }
}

resource "aws_apigatewayv2_integration" "app" {
  api_id                 = aws_apigatewayv2_api.lambda.id
  integration_uri        = aws_lambda_function.app.invoke_arn
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "any" {
  api_id             = aws_apigatewayv2_api.lambda.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
  authorization_type = "NONE"
}

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

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

