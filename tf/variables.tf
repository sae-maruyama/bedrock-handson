variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "inquiry"
}

variable "environment" {
  description = "環境名 (dev, prod など)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}