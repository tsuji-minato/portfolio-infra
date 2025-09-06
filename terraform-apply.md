Remove-Item -Recurse -Force .terraform

terraform init
terraform plan

# ログ出力用のapply

```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
terraform apply -auto-approve 2>&1 | Tee-Object -FilePath "../../logs/apply-$timestamp.log"
```

# Lambda関数のZIP化

```bash
Compress-Archive -Path * -DestinationPath ../../dist/oura_daily.zip -Force
Compress-Archive -Path * -DestinationPath ../../dist/aurora_select.zip -Force
```