# Gremlin Failure Flags Demo for AWS Lambda

This demo application showcases how to integrate Gremlin Failure Flags into an AWS Lambda function. The function measures its processing latency and returns information about any simulated faults (such as injected latency or exceptions) that the Gremlin Failure Flags agent applies.

## Overview

- **Lambda Function:**  
  A Python 3.9 Lambda function that measures how long it takes to process a request. It demonstrates Gremlin Failure Flags by invoking a flag named `http-ingress`, which can inject simulated latency or errors.
  
- **Failure Injection:**  
  The function is instrumented with the Gremlin Failure Flags SDK to allow you to simulate network or processing failures. You can observe these effects in the returned JSON payload.

- **Deployment:**  
  Terraform is used to deploy the Lambda function along with an API Gateway HTTP API. The Lambda function is packaged externally and sensitive Gremlin credentials are loaded from local files.

## Prerequisites

- Docker (for building the Lambda package)
- Terraform (version ≥ 1.0 recommended)
- AWS CLI configured with appropriate permissions
- Gremlin account with access to your Gremlin Team credentials (Team ID, Certificate, Private Key)

## Build the Lambda Package

Use Docker to package your Lambda function and its Python dependencies. Run:

```sh
export DOCKER_SCAN_SUGGEST=false
docker build -t lambda-packager . && \
  docker run --rm lambda-packager cat /LambdaFunction.zip > LambdaFunction.zip
```

This command builds the container image and extracts the generated `LambdaFunction.zip` from it.

## Prepare Gremlin Credentials

Gremlin credentials must be sanitized by removing any whitespace and newlines to avoid configuration issues.

### Process the Gremlin Team Certificate and Private Key

Run these commands to remove newlines from the downloaded certificate files:

```sh
tr -d "\n\r" < ~/Downloads/<YOUR TEAM NAME>/<YOUR TEAM NAME>.pub_cert.pem > gremlin_team_certificate.pem
tr -d "\n\r" < ~/Downloads/<YOUR TEAM NAME>/<YOUR TEAM NAME>.priv_key.pem > gremlin_team_private_key.pem
```

### Process the Gremlin Team ID

Copy the Gremlin Team ID from the Gremlin UI (usually in the lower right-hand corner), and remove any newlines:

```sh
pbpaste | tr -d "\n\r" > gremlin_team_id.txt
```

## Terraform Deployment

The Terraform configuration reads the pre-built Lambda zip file and loads your Gremlin credentials as sensitive data. Ensure the following files exist in your project directory:

- `LambdaFunction.zip` – the packaged Lambda function
- `gremlin_team_id.txt` – the sanitized Gremlin Team ID
- `gremlin_team_certificate.pem` – the sanitized certificate
- `gremlin_team_private_key.pem` – the sanitized private key

### Variables Overview

In `variables.tf`, key variables include:

- **zipfile:** The path to the Lambda zip file.
- **gremlin_team_id_path:** The path to your `gremlin_team_id.txt`.
- **gremlin_team_certificate_path:** The path to your certificate file.
- **gremlin_team_private_key_path:** The path to your private key file.
- **gremlin_layer_arn:** ARN for the Gremlin Failure Flags Lambda layer (adjust for your region and architecture).

### Deploy with Terraform

Run the following commands to deploy the demo:

```sh
terraform init
terraform apply --auto-approve
```

Terraform will upload your Lambda package, configure the Lambda function with the necessary environment variables (including the Gremlin credentials), and deploy the API Gateway integration.

## Terraform Configuration (Excerpt)

Below is an excerpt showing how the Gremlin credentials are loaded and applied to the Lambda function:

```hcl
# Load Gremlin sensitive credentials from local files.
data "local_file" "gremlin_team_id" {
  filename = var.gremlin_team_id_path
}

data "local_sensitive_file" "gremlin_team_certificate" {
  filename = var.gremlin_team_certificate_path
}

data "local_sensitive_file" "gremlin_team_private_key" {
  filename = var.gremlin_team_private_key_path
}

# Lambda Function with Gremlin Failure Flags Layer and Environment Variables
resource "aws_lambda_function" "app" {
  function_name    = var.lambda_name
  description      = "API Gateway HTTP API integration pattern with Gremlin Failure Flags"
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

- **Lambda Function:**  
  The function records the start time, invokes the Gremlin Failure Flags SDK (to simulate injected latency or errors), and then calculates the processing time. It returns a JSON payload containing the processing time, failure flag status, and a timestamp.

- **Gremlin Failure Flags Integration:**  
  The function uses the Gremlin Failure Flags SDK to invoke a flag named `http-ingress`. The results (whether any experiments are active) are included in the response so you can see the effect of any fault injection.

- **X-Ray Instrumentation:**  
  AWS X-Ray is automatically enabled to trace supported libraries, helping you monitor and diagnose the function's performance.

## Usage

Once deployed, invoke your API Gateway endpoint. The response JSON includes:

- **processingTime:** Total execution time in milliseconds.
- **isActive / isImpacted:** Flags indicating whether Gremlin failure injections were active.
- **timestamp:** The time the function started processing.

## Fault Injection Examples

Below are a few example payloads that Gremlin Failure Flags can return when injecting faults into your application:

| Fault Type              | Effect Example                                                                                                                                         |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Latency Injection**   | `{ "latency": { "ms": 1000, "jitter": 0 } }`                                                                                                            |
| **Built-in Exception**  | `{ "exception": { "className": "ValueError", "message": "Injected ValueError", "module": "builtins" } }`                                                |
| **S3 Connection Error** | `{ "exception": { "className": "S3TransferFailedError", "message": "Simulated connection error during S3 transfer", "module": "boto3.exceptions" } }` |
| **Socket Timeout**      | `{ "exception": { "className": "TimeoutError", "message": "Socket operation timed out", "module": "socket" } }`                                            |

You can use these examples to configure your experiments in the Gremlin UI and simulate various faults in your AWS Lambda functions.

## Cleanup

To remove the deployed resources, run:

```sh
terraform destroy --auto-approve
```

## Additional Resources

- [Gremlin Failure Flags Documentation](https://www.gremlin.com/docs/failure-flags-overview)
- [Deploying Failure Flags on AWS Lambda](https://www.gremlin.com/docs/failure-flags-lambda)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

