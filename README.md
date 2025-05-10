# Gremlin Failure Flags AWS Lambda Demo

This demo illustrates how to integrate **Gremlin Failure Flags** into an **AWS Lambda** function. It demonstrates fault injection scenarios, including latency and exceptions, helping developers, DevOps engineers, and Site Reliability Engineers (SREs) validate and improve resilience in serverless applications.

## Overview

* **AWS Lambda Function**:

  * Python 3.9 function measuring request processing latency.
  * Demonstrates fault injection via Gremlin Failure Flags (`http-ingress`).

* **Fault Injection Capabilities**:

  * Simulate network latency, exceptions, and errors.
  * Results are visible in the returned JSON response.

* **Infrastructure Deployment**:

  * Uses Terraform for deployment.
  * Integrates Lambda function with AWS API Gateway (HTTP API).
  * Loads sensitive Gremlin credentials securely from local files.

## Prerequisites

Ensure the following prerequisites are met:

| Requirement         | Description                                               |
| ------------------- | --------------------------------------------------------- |
| **Docker**          | For packaging the Lambda function                         |
| **Terraform**       | Version ≥ 1.0 recommended                                 |
| **AWS CLI**         | Configured with appropriate permissions                   |
| **Gremlin Account** | Credentials (Team ID, Certificate, Private Key) available |

## Getting Started

### Build Lambda Function

Build your Lambda function package using Docker:

```sh
export DOCKER_SCAN_SUGGEST=false
docker build -t lambda-packager . && \
  docker run --rm lambda-packager cat /LambdaFunction.zip > LambdaFunction.zip
```

### Prepare Gremlin Credentials

Remove whitespace and newlines from downloaded credentials:

```sh
tr -d "\n\r" < ~/Downloads/<YOUR_TEAM_NAME>/<YOUR_TEAM_NAME>.pub_cert.pem > gremlin_team_certificate.pem
tr -d "\n\r" < ~/Downloads/<YOUR_TEAM_NAME>/<YOUR_TEAM_NAME>.priv_key.pem > gremlin_team_private_key.pem
```

Copy and sanitize Gremlin Team ID:

```sh
pbpaste | tr -d "\n\r" > gremlin_team_id.txt
```

### Terraform Deployment

Your project directory should contain:

* `LambdaFunction.zip`
* `gremlin_team_id.txt`
* `gremlin_team_certificate.pem`
* `gremlin_team_private_key.pem`

**Deploy using Terraform:**

```sh
terraform init
terraform apply --auto-approve
```

## Terraform Configuration

Sample Terraform setup for AWS Lambda and Gremlin integration:

```hcl
data "local_file" "gremlin_team_id" {
  filename = var.gremlin_team_id_path
}

data "local_sensitive_file" "gremlin_team_certificate" {
  filename = var.gremlin_team_certificate_path
}

data "local_sensitive_file" "gremlin_team_private_key" {
  filename = var.gremlin_team_private_key_path
}

resource "aws_lambda_function" "app" {
  function_name    = var.lambda_name
  description      = "AWS Lambda with Gremlin Failure Flags"
  filename         = "${path.module}/${var.zipfile}"
  source_code_hash = data.local_file.lambda_zip.content_sha256
  runtime          = "python3.9"
  handler          = "LambdaFunction.handler"
  role             = aws_iam_role.lambda_exec.arn

  layers = [var.gremlin_layer_arn]

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
```

## How It Works

* **Lambda Function Execution:**

  * Captures start time.
  * Invokes Gremlin Failure Flags SDK.
  * Calculates total processing time.
  * Returns JSON with details of fault injection status and latency.

* **Gremlin Integration:**

  * Invokes `http-ingress` failure flag.
  * Displays injected faults in the function response.

* **AWS X-Ray:**

  * Enabled automatically for enhanced tracing and monitoring.

## Usage

Invoke your API Gateway endpoint. Response includes:

* **processingTime**: Execution duration (ms).
* **isActive / isImpacted**: Status of Gremlin fault injection.
* **timestamp**: Invocation timestamp.

## Fault Injection Examples

| Fault Type              | Effect Example                                                                                                                                        |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Latency Injection**   | `{ "latency": { "ms": 1000, "jitter": 0 } }`                                                                                                          |
| **Built-in Exception**  | `{ "exception": { "className": "ValueError", "message": "Injected ValueError", "module": "builtins" } }`                                              |
| **S3 Connection Error** | `{ "exception": { "className": "S3TransferFailedError", "message": "Simulated connection error during S3 transfer", "module": "boto3.exceptions" } }` |
| **Socket Timeout**      | `{ "exception": { "className": "TimeoutError", "message": "Socket operation timed out", "module": "socket" } }`                                       |

## Cleanup

Remove deployed resources using Terraform:

```sh
terraform destroy --auto-approve
```

## Additional Resources

* [Gremlin Failure Flags Docs](https://www.gremlin.com/docs/failure-flags-overview)
* [Gremlin AWS Lambda Deployment](https://www.gremlin.com/docs/failure-flags-lambda)
* [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
* [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

