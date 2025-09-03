# Lambda関数
resource "aws_lambda_function" "upload_inquiry" {
  function_name    = "${local.name_prefix}-upload"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  filename        = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inquiry.name
    }
  }

  tags = local.common_tags
}