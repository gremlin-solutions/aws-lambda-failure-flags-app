// AWS region for all resources.
variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

// Lambda function package (ZIP file) name.
variable "zipfile" {
  description = "The file name of the Lambda function package (ZIP file)."
  type        = string
  default     = "LambdaFunction.zip"
}

// Lambda function name.
variable "lambda_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "gremlin_apigw_lambda"
}

// CloudWatch log retention (in days) for the Lambda function.
variable "lambda_log_retention" {
  description = "The number of days to retain Lambda log data in CloudWatch."
  type        = number
  default     = 7
}

// CloudWatch log retention (in days) for API Gateway logs.
variable "apigw_log_retention" {
  description = "The number of days to retain API Gateway log data in CloudWatch."
  type        = number
  default     = 7
}

##############################################################################
# Gremlin Failure Flags and Lambda Integration Settings
##############################################################################

// Enable or disable Gremlin Failure Flags functionality.
variable "gremlin_failure_flags_enabled" {
  description = "Enable or disable Gremlin Failure Flags functionality."
  type        = bool
  default     = true
}

// Enable or disable Gremlin Lambda integration features.
variable "gremlin_lambda_enabled" {
  description = "Enable or disable Gremlin Lambda integration."
  type        = bool
  default     = true
}

// Enable or disable debug logging for Gremlin integration.
variable "gremlin_debug" {
  description = "Enable or disable debug logging for Gremlin integration."
  type        = bool
  default     = true
}

// Timeout (in seconds) for Gremlin API requests from the Lambda.
variable "gremlin_request_timeout" {
  description = "Timeout in seconds for Gremlin API requests."
  type        = string
  default     = "5s"
}


##############################################################################
# Local file paths for Gremlin sensitive credentials
##############################################################################

// Path to the file that contains the Gremlin Team ID.
variable "gremlin_team_id_path" {
  description = "Path to the file that contains the Gremlin Team ID."
  type        = string
  default     = "gremlin_team_id.txt"
}

// Path to the file that contains the Gremlin Team Certificate.
variable "gremlin_team_certificate_path" {
  description = "Path to the file that contains the Gremlin Team Certificate."
  type        = string
  default     = "gremlin_team_certificate.pem"
}

// Path to the file that contains the Gremlin Team Private Key.
variable "gremlin_team_private_key_path" {
  description = "Path to the file that contains the Gremlin Team Private Key."
  type        = string
  default     = "gremlin_team_private_key.pem"
}

##############################################################################
// Gremlin Lambda Layer ARN
##############################################################################

// ARN for the public Gremlin Failure Flags Lambda layer.
variable "gremlin_layer_arn" {
  description = "ARN for the public Gremlin Failure Flags Lambda layer."
  type        = string
  default     = "arn:aws:lambda:us-east-1:044815399860:layer:gremlin-lambda-x86_64:17"
}

