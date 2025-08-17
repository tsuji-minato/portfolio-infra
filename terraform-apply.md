# ログ出力用のapply

```powershell
terraform apply -auto-approve | tee logs/apply-$(date +%Y%m%d-%H%M%S).log
```