# Apply-Rules-v020.ps1 — v020 保存＋保存時刻追記＋ログ一括
# Futaba 専用 — Preview/Save ワークフローの「Save」用ショートカット

# ========== 設定（環境に合わせて変更） ==========
Set-Location "C:\Users\hiroy\Desktop\project-root"

# ========== 実行 ==========
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path (Get-Location) "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir "Apply-Rules-v020_$ts.log") | Out-Null

# 要約と詳細は適宜変更してください
$summary = "v020 更新: Windows拡充（Setup/Preview/Save/Rollback追加・保存時刻自動追記）"
$details = "承認コメント不要。保存ログ＋rules_latest.md先頭の保存時刻で証跡を残す。"

# 1) update_rules.py で保存処理（rules_latest.md更新＋index再生成＋introtemplate更新）
python ".\scripts\update_rules.py" --summary $summary --details $details
if ($LASTEXITCODE -ne 0) {
    Write-Error "update_rules.py の実行に失敗しました。"
    Stop-Transcript | Out-Null
    exit 1
}

# 2) docs\rules_latest.md の先頭へ「保存時刻」を自動追記
$py = @'
import io, os, sys
from datetime import datetime

path = os.path.join("docs", "rules_latest.md")
if not os.path.exists(path):
    sys.exit(f"not found: {path}")

with io.open(path, "r", encoding="utf-8") as f:
    content = f.read()

lines = content.splitlines()
if lines and lines[0].startswith("<!-- 保存時刻:"):
    lines = lines[1:]

now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
new_content = f"<!-- 保存時刻: {now} -->\n" + "\n".join(lines)
if not new_content.endswith("\n"):
    new_content += "\n"

with io.open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(new_content)

print(f"[STAMPED] 保存時刻を付与: {now}")
'@

python - <<$py
if ($LASTEXITCODE -ne 0) {
    Write-Error "保存時刻の追記に失敗しました。"
    Stop-Transcript | Out-Null
    exit 1
}

Stop-Transcript | Out-Null
Write-Host "`n[DONE] v020 保存＋保存時刻追記が完了しました。`n- docs\rules_latest.md 更新済み`n- docs\rules_index.md 追記済み`n- docs\introtemplate.md 更新済み`n- logs\Apply-Rules-v020_$ts.log 出力" -ForegroundColor Green
