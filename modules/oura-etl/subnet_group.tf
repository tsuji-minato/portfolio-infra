resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "aurora-pg-subnets"
  subnet_ids = var.db_subnet_ids
}
