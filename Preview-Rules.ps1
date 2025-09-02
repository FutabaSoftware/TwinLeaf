# Preview-Rules.ps1 — 差分だけを表示（保存しない）
# Set this to your project root if different
Set-Location "C:\Users\hiroy\Desktop\project-root"

$summary = "Preview only"
$details = ""

python ".\scripts\update_rules.py" --summary $summary --details $details --diff-only
if ($LASTEXITCODE -ne 0) { Write-Error "Preview でエラーが発生しました。"; exit 1 }
Write-Host "`n[PREVIEW DONE] 差分のみを表示しました。保存は行っていません。" -ForegroundColor Yellow
