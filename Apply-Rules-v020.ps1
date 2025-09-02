# Apply-Rules-v020.ps1 — fixed (no Bash-style heredoc)
# Save + 保存時刻刻印 + ログ出力（刻印は update_rules.py 側で実施）

# ========== 設定（環境に合わせて変更） ==========
Set-Location "C:\Users\hiroy\Desktop\project-root"

# ========== 実行 ==========
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path (Get-Location) "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir "Apply-Rules-v020_$ts.log") | Out-Null

# 要約と詳細は適宜変更してください
$summary = "v020: Windows拡充（Setup/Preview/Save/Rollback、保存時刻自動刻印）"
$details = "承認コメント不要。保存ログ＋rules_latest.md先頭の保存時刻で証跡を残す。"

# 1) update_rules.py で保存処理（latest更新＋index再生成＋intro更新＋保存時刻刻印）
python ".\scripts\update_rules.py" --summary $summary --details $details
if ($LASTEXITCODE -ne 0) {
    Write-Error "update_rules.py の実行に失敗しました。"
    Stop-Transcript | Out-Null
    exit 1
}

Stop-Transcript | Out-Null
Write-Host "`n[DONE] v020 保存（刻印は update_rules.py で実施済み）`n- docs\rules_latest.md 更新済み`n- docs\rules_index.md 追記済み`n- docs\introtemplate.md 更新済み`n- logs\Apply-Rules-v020_$ts.log 出力" -ForegroundColor Green
