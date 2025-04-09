############################################################
# CloudWatch Log Group for the Lambda function.
############################################################

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.lambda_log_retention
}

############################################################
# IAM Role for the Lambda function.
############################################################

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

############################################################
# AWS Lambda Function
############################################################

resource "aws_lambda_function" "app" {
  function_name    = var.lambda_name
  description      = "API Gateway HTTP API integration pattern with Gremlin Failure Flags"
  filename         = "${path.module}/${var.zipfile}"
  source_code_hash = data.local_file.lambda_zip.content_sha256
  runtime          = "python3.9"
  handler          = "LambdaFunction.handler"
  role             = aws_iam_role.lambda_exec.arn

  # Uncomment and adjust the timeout if needed (default is 3 seconds).
  # timeout = 5

  # Add the Gremlin Failure Flags Lambda layer.
  layers = [var.gremlin_layer_arn]

  # Set environment variables including Gremlin credentials from local files.
  environment {
    variables = {
      FAILURE_FLAGS_ENABLED    = var.gremlin_failure_flags_enabled
      GREMLIN_LAMBDA_ENABLED   = var.gremlin_lambda_enabled
      GREMLIN_DEBUG            = var.gremlin_debug
      GREMLIN_REQUEST_TIMEOUT  = var.gremlin_request_timeout
      GREMLIN_TEAM_ID          = data.local_file.gremlin_team_id.content
      GREMLIN_TEAM_CERTIFICATE = data.local_sensitive_file.gremlin_team_certificate.content
      GREMLIN_TEAM_PRIVATE_KEY = data.local_sensitive_file.gremlin_team_private_key.content
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log]
}

