variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "zipfile" {
  description = "Lambda Function Zip File"
  type        = string
  default     = "LambdaFunction.zip"
}

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "gremlin_apigw_lambda"
}

variable "lambda_log_retention" {
  description = "Lambda log retention in days"
  type        = number
  default     = 7
}

variable "apigw_log_retention" {
  description = "API Gateway log retention in days"
  type        = number
  default     = 7
}

# New variables to specify the file paths for sensitive Gremlin credentials
variable "gremlin_team_id_path" {
  description = "Path to file containing the Gremlin Team ID"
  type        = string
  default     = "gremlin_team_id.txt"
}

variable "gremlin_team_certificate_path" {
  description = "Path to file containing the Gremlin Team Certificate"
  type        = string
  default     = "gremlin_team_certificate.pem"
}

variable "gremlin_team_private_key_path" {
  description = "Path to file containing the Gremlin Team Private Key"
  type        = string
  default     = "gremlin_team_private_key.pem"
}

# ARN for the public Gremlin Failure Flags Lambda layer.
variable "gremlin_layer_arn" {
  description = "ARN for the public Gremlin Failure Flags Lambda layer"
  type        = string
  default     = "arn:aws:lambda:us-east-1:044815399860:layer:gremlin-lambda-x86_64:17"
}

