output "aurora_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

# output "aurora_pg_secret_arn" {
#   value = aws_secretsmanager_secret.aurora_pg_url.arn
# }

# output "oura_pat_secret_arn" {
#   value = aws_secretsmanager_secret.oura_pat.arn
# }
