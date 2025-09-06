resource "aws_secretsmanager_secret" "oura_pat" {
  name = "OURA_PAT"
}

resource "aws_secretsmanager_secret_version" "oura_pat_ver" {
  secret_id     = aws_secretsmanager_secret.oura_pat.id
  secret_string = var.oura_pat_initial
}

resource "aws_secretsmanager_secret" "aurora_pg_url" {
  name = "AURORA_PG_URL"
}

resource "aws_secretsmanager_secret_version" "aurora_pg_url_ver" {
  secret_id     = aws_secretsmanager_secret.aurora_pg_url.id
  secret_string = "postgresql://${local.db_user}:${random_password.db_password.result}@${aws_rds_cluster.aurora.endpoint}:5432/${local.db_name}"
}

output "oura_pat_secret_arn" {
  value = aws_secretsmanager_secret.oura_pat.arn
}

output "aurora_pg_secret_arn" {
  value = aws_secretsmanager_secret.aurora_pg_url.arn
}
