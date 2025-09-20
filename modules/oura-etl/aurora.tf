resource "random_password" "db_password" {
  length  = 24
  special = true
}

locals {
  db_name     = "ouradb"
  db_user     = "ourapguser"
  min_acu     = 0.5
  max_acu     = 1.0
}

resource "aws_rds_cluster" "aurora" {
  engine                 = "aurora-postgresql"
  engine_version         = "15.4"
  database_name          = local.db_name
  master_username        = local.db_user
  master_password        = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnets.name
  vpc_security_group_ids = [var.aurora_sg_id]
  serverlessv2_scaling_configuration {
    min_capacity = local.min_acu
    max_capacity = local.max_acu
  }
  enable_http_endpoint = true
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "aurora-pg-slv2-1"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  publicly_accessible = false
}

resource "aws_secretsmanager_secret" "aurora_db_secret" {
  name = "aurora/db-credentials"
}

resource "aws_secretsmanager_secret_version" "aurora_db_secret_v" {
  secret_id     = aws_secretsmanager_secret.aurora_db_secret.id
  secret_string = jsonencode({
    username = local.db_user
    password = random_password.db_password.result
  })
}
