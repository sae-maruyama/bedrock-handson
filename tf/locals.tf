locals {
  # リソース名のプレフィックス
  name_prefix = "${var.project_name}-${var.environment}"
  
  # 共通タグ
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}