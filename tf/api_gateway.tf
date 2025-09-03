# REST API Gateway
resource "aws_api_gateway_rest_api" "inquiry_api" {
  name        = "${local.name_prefix}-api"
  description = "Inquiry Service REST API"

  tags = local.common_tags
}

# リソース作成 (/upload-inquiry)
resource "aws_api_gateway_resource" "upload_inquiry_resource" {
  rest_api_id = aws_api_gateway_rest_api.inquiry_api.id
  parent_id   = aws_api_gateway_rest_api.inquiry_api.root_resource_id
  path_part   = "upload-inquiry"
}

# POSTメソッド作成
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.inquiry_api.id
  resource_id   = aws_api_gateway_resource.upload_inquiry_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda統合
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.inquiry_api.id
  resource_id = aws_api_gateway_resource.upload_inquiry_resource.id
  http_method = aws_api_gateway_method.post_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.upload_inquiry.invoke_arn
}

# デプロイメント
resource "aws_api_gateway_deployment" "inquiry_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.inquiry_api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload_inquiry_resource.id,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }
}

# ステージ
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.inquiry_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.inquiry_api.id
  stage_name    = "prod"

  tags = local.common_tags
}

# Lambda実行許可
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_inquiry.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.inquiry_api.execution_arn}/*/*"
}