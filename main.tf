provider "aws" {
  region = "us-east-1"  # Define your AWS region
}

# Create IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Define Lambda Function
resource "aws_lambda_function" "user_registration" {
  function_name = "user_registration"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"  # Points to the handler function
  runtime       = "python3.8"

  # Package your Lambda code and dependencies into a .zip file
  filename      = "lambda_function.zip"  # This will be the zipped code
}

# Create API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "UserRegistrationAPI"
}

# Create API Gateway Resource
resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "register"
}

# Define POST method on the API Gateway Resource
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"  # No authorization for simplicity
}

# Integrate API Gateway with Lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  # Use AWS Proxy integration
  uri                     = aws_lambda_function.user_registration.invoke_arn
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_registration.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"  # Source ARN
}
# Deploy API Gateway Stage
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}
# Output API Gateway Endpoint
output "api_gateway_endpoint" {
  description = "The URL for the API Gateway"
  value       = "${aws_api_gateway_rest_api.api.execution_arn}/dev/register"
}
# Output the API Gateway URL
output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
  description = "API Gateway URL to trigger the Lambda function"
}
