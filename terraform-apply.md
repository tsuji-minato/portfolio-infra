# ログ出力用のapply

```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
terraform apply -auto-approve | Tee-Object -FilePath "logs/apply-$timestamp.log"
```