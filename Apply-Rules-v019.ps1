# Apply-Rules-v019.ps1 (console-safe)
# 1) Move to your project root (edit the path to match your environment)
Set-Location "C:\Users\hiroy\Desktop\project-root"

# 2) Generate v019 and auto-update docs/latest/index/intro (logs are written under .\logs)
$PR = (Get-Location).Path
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $PR "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Start-Transcript -Path (Join-Path $logDir "Update-Rules_$ts.log") | Out-Null

$summary = @"
ソロ運用モード（個人・余暇時間）を追補：自分承認OK（@Futaba）、25分×1マイクロ出荷、Preview→Save優先、ロールバック明文化、初回セットアップ、秘密情報チェック、BML最小指標、Windows+PowerShell限定
"@

$details = @"
## 付録：ソロ運用モード（個人・余暇時間）

### 目的
最小の手動で最大の成果を出すため、ルール運用を「25分×1単位のマイクロ出荷」に最適化する。現行ワークフロー（Preview→Save）は維持する。

### 役割と承認
- 作業者＝レビュワー＝@Futaba（自分承認OK）
- 承認コメント定型：
  - 「OK @Futaba」（保存前 or 直後のいずれかで可）
  - 完了コメント（保存後）：
    ```
    【更新完了】docs/rules_latest.md（vXXX）に反映
    承認: OK @Futaba
    ```
- これで証跡が残り、次回に迷わない

### 1セッション（25分）の流れ
1) ゴールを1行で書く（何を作る/直すか）
2) すぐ作る（MVP）
3) Rules-Preview.lnk で差分確認（保存しない）
4) 問題なければ Rules-Save.lnk で本番保存
5) 完了コメントを貼って終了
   （※ ショートカットが基本。失敗時のみ Python 直実行）

### 直実行のフォールバック（失敗時だけ）
# プレビュー（保存なし）:
#   python .\scripts\update_rules.py --summary "変更要約1行" --details "必要なら詳細" --diff-only
# 保存:
#   python .\scripts\update_rules.py --summary "変更要約1行" --details "必要なら詳細"
# （--summary / --details / --diff-only をサポート。保存時は latest 更新・index再生成・introtemplateも自動更新）

### ロールバック手順（壊したら即戻す）
# 1) docs\rules_index.md で戻したい版を確認
# 2) 対象版の内容を rules_latest.md に復元
# 3) Rules-Preview → 問題なし → Rules-Save

### 初回セットアップ（Windowsだけ対応）
# 1) PowerShell（管理者）: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# 2) scripts\setup_env.py を実行（依存と venv）
# 3) Rules-Preview.lnk → OKなら Rules-Save.lnk

### 秘密情報チェック（保存前に10秒）
# `APIキー, token, password, client id, 秘密, 個人, mail, addr` で全文検索し該当なしを確認

### 最小の測定（BML の “Measure”）
# 所要分数（25分以内目標）／ロールバック回数（月）／差し戻し率

# ---- Run the real update via Python ----
$scriptPath = Join-Path $PR "scripts\update_rules.py"
if (!(Test-Path $scriptPath)) { throw "scripts\update_rules.py が見つかりません。現在位置を project-root にしてください。" }

python $scriptPath --summary $summary --details $details

Stop-Transcript | Out-Null
Write-Host "`n[DONE] v019 自動格納完了:`n- docs\rules_latest.md 更新`n- docs\rules_index.md 追記`n- docs\introtemplate.md 更新`n- logs\Update-Rules_$ts.log 出力" -ForegroundColor Green
