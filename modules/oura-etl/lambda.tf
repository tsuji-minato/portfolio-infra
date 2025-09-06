resource "aws_lambda_function" "oura_daily" {
  function_name = "oura_daily"
  filename      = "${path.module}/../../dist/oura_daily.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30
  memory_size   = 128
  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment {
    variables = {
      OURA_PAT_SECRET_NAME     = aws_secretsmanager_secret.oura_pat.name
      AURORA_PG_URL_SECRET_NAME = aws_secretsmanager_secret.aurora_pg_url.name
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "oura_lambda_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy" "lambda_vpc_permissions" {
  name   = "lambda-vpc-permissions"
  role   = aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

# EventBridge ルール（毎日 UTC 0時 = JST 9時）
resource "aws_cloudwatch_event_rule" "oura_daily_schedule" {
  name                = "oura_daily_schedule"
  schedule_expression = "cron(0 0 * * ? *)" # 毎日 UTC 0時 → JST 9時
}

# EventBridge → Lambda のターゲット設定
resource "aws_cloudwatch_event_target" "oura_daily_target" {
  rule      = aws_cloudwatch_event_rule.oura_daily_schedule.name
  target_id = "oura_daily_lambda"
  arn       = aws_lambda_function.oura_daily.arn
}

# Lambda が EventBridge から呼び出されるための権限付与
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.oura_daily.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.oura_daily_schedule.arn
}

resource "aws_lambda_function" "aurora_select" {
  function_name = "aurora_select"
  filename      = "${path.module}/../../dist/aurora_select.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 30
  memory_size   = 128

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      AURORA_PG_URL_SECRET_NAME = aws_secretsmanager_secret.aurora_pg_url.name
    }
  }
}
