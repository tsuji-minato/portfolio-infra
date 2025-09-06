provider "aws" {
  region = "us-east-1"
}

# Aurora用のセキュリティグループ
resource "aws_security_group" "aurora_sg" {
  name        = "oura-aurora-sg"
  description = "Aurora SG for Oura ETL"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # ← あなたのVPC CIDRに合わせて変更してOK
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "oura_etl" {
  source            = "../../modules/oura-etl"
  vpc_id            = var.vpc_id
  db_subnet_ids     = var.db_subnet_ids
  lambda_subnet_ids = var.lambda_subnet_ids
  oura_pat_initial  = var.oura_pat_initial
  aurora_sg_id      = aws_security_group.aurora_sg.id
}
