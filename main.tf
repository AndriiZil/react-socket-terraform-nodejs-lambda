provider "aws" {
  region = var.aws_region
}

# API Gateway v2 (WebSocket)
resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.project_name}-${var.environment}"
  protocol_type             = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "websocket" {
  api_id = aws_apigatewayv2_api.websocket.id
  name   = var.environment
  auto_deploy = true
}

# Lambda Functions
resource "aws_lambda_function" "connect" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-connect-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda/websocket.connect"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      STAGE = var.environment
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }
}

resource "aws_lambda_function" "disconnect" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-disconnect-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda/websocket.disconnect"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      STAGE = var.environment
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }
}

resource "aws_lambda_function" "message" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-message-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda/websocket.message"
  runtime         = "nodejs18.x"

  environment {
    variables = {
      STAGE = var.environment
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }
}

# API Gateway Routes
resource "aws_apigatewayv2_integration" "connect" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.connect.invoke_arn
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.disconnect.invoke_arn
}

resource "aws_apigatewayv2_integration" "message" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.message.invoke_arn
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "message" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "message"
  target    = "integrations/${aws_apigatewayv2_integration.message.id}"
}

# DynamoDB Table
resource "aws_dynamodb_table" "connections" {
  name           = "${var.project_name}-connections-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }
}

# Lambda permissions
resource "aws_lambda_permission" "connect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "disconnect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disconnect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "message" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.message.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.connections.arn
      },
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "${aws_apigatewayv2_api.websocket.execution_arn}/${var.environment}/POST/@connections/*"
      }
    ]
  })
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
} 