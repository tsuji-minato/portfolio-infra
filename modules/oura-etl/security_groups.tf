resource "aws_security_group" "aurora_sg" {
  name        = "aurora-pg-sg"
  description = "Aurora PostgreSQL"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-aurora-client-sg"
  description = "lambda-aurora-client-sg"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "aurora_ingress_from_lambda" {
  type                     = "ingress"
  security_group_id        = aws_security_group.aurora_sg.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
}
