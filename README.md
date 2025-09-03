# Inquiry Service

お問い合わせフォーム用のサーバーレス API

## 構成

- API Gateway (REST) + Lambda + DynamoDB

## セットアップ

```bash
# 1. terraform.tfvarsを作成
cp tf/terraform.tfvars.example tf/terraform.tfvars

# 2. デプロイ
cd tf/
terraform init
terraform apply
```

## 使用方法

```bash
# API URL取得
terraform output api_invoke_url

# テスト実行
curl -X POST $(terraform output -raw api_invoke_url) \
  -H "Content-Type: application/json" \
  -d '{
    "mailAddress": "test@example.com",
    "userName": "テストユーザー",
    "reviewText": "テスト"
  }'
```

## 設定変数

| 変数 | デフォルト |
|------|-----------|
| project_name | inquiry |
| environment | dev |
| region | ap-northeast-1 |