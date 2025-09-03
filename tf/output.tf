output "api_endpoint" {
  description = "API GatewayのエンドポイントURL"
  value       = "https://${aws_api_gateway_rest_api.inquiry_api.id}.execute-api.${var.region}.amazonaws.com/prod"
}

output "api_invoke_url" {
  description = "完全なAPI呼び出しURL"
  value       = "https://${aws_api_gateway_rest_api.inquiry_api.id}.execute-api.${var.region}.amazonaws.com/prod/upload-inquiry"
}

output "table_name" {
  description = "DynamoDBテーブル名"
  value       = aws_dynamodb_table.inquiry.name
}

output "lambda_name" {
  description = "Lambda関数名"
  value       = aws_lambda_function.upload_inquiry.function_name
}