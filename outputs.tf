output "websocket_url" {
  description = "WebSocket URL"
  value       = "${aws_apigatewayv2_api.websocket.api_endpoint}/${var.environment}"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.connections.name
} 