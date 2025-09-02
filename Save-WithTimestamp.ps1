# Save-WithTimestamp.ps1 — 「保存時刻」を自動追記して保存（非侵襲：update_rules.pyは無改造）
# 使い方:
#   1) Set-Location をあなたの project-root に変えて実行
#   2) --summary と --details は必要に応じて編集

# ===== 設定（あなたの環境に合わせてください） =====
Set-Location "C:\Users\hiroy\Desktop\project-root"

# ===== 実行（v020など任意の内容でOK） =====
$summary = "ルール更新：承認コメント廃止。保存時に rules_latest.md 先頭へ保存時刻を自動追記"
$details = "運用を簡略化：Preview→Save で完結。保存ログ＋保存時刻で証跡を残す"

# 1) 既存の update_rules.py で保存処理（latest/index/intro を自動更新）
python ".\scripts\update_rules.py" --summary $summary --details $details

if ($LASTEXITCODE -ne 0) {
  Write-Error "update_rules.py の実行に失敗しました。"
  exit 1
}

# 2) 保存直後に docs\rules_latest.md の先頭へ「保存時刻」を自動追記（多重追記は防止）
$py = @'
import io, os, sys, re
from datetime import datetime

path = os.path.join("docs", "rules_latest.md")
if not os.path.exists(path):
    sys.exit(f"not found: {path}")

with io.open(path, "r", encoding="utf-8") as f:
    content = f.read()

lines = content.splitlines()
if lines and lines[0].startswith("<!-- 保存時刻:"):
    lines = lines[1:]  # 既存の保存時刻を除去して置き換える

now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
new_content = f"<!-- 保存時刻: {now} -->\n" + "\n".join(lines) + ("\n" if lines and lines[-1] != "" else "")
with io.open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(new_content)
print(f"[STAMPED] 保存時刻を付与: {now}")
'@

python - <<$py
if ($LASTEXITCODE -ne 0) {
  Write-Error "保存時刻の追記に失敗しました。"
  exit 1
}

Write-Host "[DONE] ルールを保存し、保存時刻を自動追記しました。" -ForegroundColor Green
