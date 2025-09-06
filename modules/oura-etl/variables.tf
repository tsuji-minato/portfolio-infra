variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "Aurora用のプライベートサブネットID配列"
  type        = list(string)
}

variable "lambda_subnet_ids" {
  description = "Lambda配置サブネットID配列"
  type        = list(string)
}

variable "oura_pat_initial" {
  description = "Oura Personal Access Token"
  type        = string
  sensitive   = true
}

variable "aurora_sg_id" {
  description = "Security Group ID for Aurora"
  type = string
}
