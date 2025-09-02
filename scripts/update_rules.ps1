param(
  [string]$Summary, [string]$Details, [string]$AppendFile, [switch]$NoLatestAlias
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ルート/出力先
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Docs  = Join-Path $ProjectRoot 'docs'
$Logs  = Join-Path $ProjectRoot 'logs'
New-Item -ItemType Directory -Path $Docs,$Logs -Force | Out-Null

# 既存最新版→次番号
$existing = Get-ChildItem -LiteralPath $Docs -Filter 'rules_v*.md' -File -ErrorAction SilentlyContinue |
  Where-Object { $_.BaseName -match '^rules_v(\d{3})$' } |
  Sort-Object { [int]($_.BaseName -replace '^rules_v','') }
$nextNum = if ($existing) { [int]($existing[-1].BaseName -replace '^rules_v','') + 1 } else { 1 }

$verTag=('v{0:000}' -f $nextNum); $today=Get-Date -Format 'yyyy-MM-dd'
$outFile=Join-Path $Docs ("rules_{0}.md" -f $verTag)
$latest =Join-Path $Docs 'rules_latest.md'
$logFile=Join-Path $Logs 'rules_updates.log'

# 概要の取得（未指定なら対話）
if (-not $Summary) {
  Write-Host '今回のルール変更の概要（1〜数行）を入力してください。空行で終了。' -ForegroundColor Yellow
  $lines=@(); while($true){ $line=Read-Host; if([string]::IsNullOrWhiteSpace($line)){break}; $lines+=$line }
  $Summary = ($lines -join "`r`n")
}
if ([string]::IsNullOrWhiteSpace($Summary)) { throw 'Summary（変更概要）が空です。' }

# 詳細の結合
$appendParts = New-Object System.Collections.Generic.List[string]
if ($Details)    { $appendParts.Add($Details) }
if ($AppendFile) {
  if(-not(Test-Path -LiteralPath $AppendFile)){ throw "AppendFile が見つかりません: $AppendFile" }
  $appendParts.Add((Get-Content -LiteralPath $AppendFile -Raw -Encoding UTF8))
}
$appendText = if ($appendParts.Count -gt 0) { $appendParts -join "`r`n`r`n" } else { '' }

# 常設ブロック（内側は @" "@）
$bmlBlock = @"
## 思想（v004 以降の常設）
- **作らない勇気**：要件を削り、最小の道具で最速に価値を出す
- **舗装路（Paved Road）**：推奨の手順・テンプレ・実行器で学習コスト＆ミス最小化
- **BML（Build–Measure–Learn）**：小さく作り、測り、学んで次へ
- **恒久対策テンプレ**
  - 事象：
  - 原因：
  - 恒久策：
  - 再発防止チェック：
"@

$execBlock = @"
## 実行方法
- **基本**：Python は `run.ps1` 経由（venv/依存/再現性を担保）
- **ショートカット運用**：デスクトップからダブルクリックで実行可
- **Enter 待ち制御**：`isatty()` で対話端末のみ待機。自動実行では待たない
- **依存の追加**：`requirements.txt` 追記 → `scripts\setup_env.py` で整備
- **ログ**：`project-root\logs\` に統一
"@

$changelog = @"
## 変更履歴（概要）
- $verTag（$today）: $([string]::Join(' ', ($Summary -split "`r`n")))
"@

$template = @"
# ChatGPT 運用ルール（公開版）
バージョン: $verTag / 最終更新日: $today

## 目的
プログラミング初心者が、**最小の手動で最大の成果**を得るために、ChatGPT と自動化を活用して効率よく高品質な成果物を作る。

## 基本原則
- **結論 → 根拠 → 次の手** で簡潔に回答
- 指示が曖昧でも **合理的に推測** し、**最小限の質問**
- まず **MVP**（動く最小）を出し、**改善ループ**で磨く
- 公開想定：**機密情報は含めない**

## 依頼の出し方（推奨）
- 目的／読者／制約（文字数・形式・期日）／参考資料を簡潔に
- 不足があっても **仮置き**。Yes/No で潰せる質問だけ返す

## 出力ルール
- 納品は **コピペ可能な Markdown**（文書／表／コード／コマンド）
- Windows 前提：**PowerShell優先**、必要に応じてbash併記
- 破壊的操作（削除・上書き・公開）は **実行前に明示** して同意

## 命名・フォルダ（公開資料向け）
- 形式：`YYYYMMDD-shortname-purpose-v001.md`
- 標準ディレクトリ：`docs/` `assets/` `scripts/` `drafts/`

## サンプル依頼
> 目的：◯◯ガイドを 1500 文字で  
> 納品：docs/ に本文 v001・画像パス・作成コマンド

## ライセンス / クレジット
- 任意：CC BY 4.0 または CC BY-NC 4.0
- 寄付リンク：Buy Me a Coffee（任意）

$execBlock
$bmlBlock

## 今回の変更（$verTag）
$Summary

$([string]::IsNullOrWhiteSpace($appendText) ? '' : "`r`n### 詳細`r`n$appendText")

$changelog
"@

# 出力と latest 更新
$template | Set-Content -Path $outFile -Encoding UTF8
if (-not $NoLatestAlias) { $template | Set-Content -Path $latest -Encoding UTF8 }

"[OK] 出力: $outFile" | Tee-Object -FilePath $logFile -Append
if (-not $NoLatestAlias) { "[OK] latest を更新: $latest" | Tee-Object -FilePath $logFile -Append }

# インデックス更新
$indexPath = Join-Path $Docs 'rules_index.md'
$all = Get-ChildItem -LiteralPath $Docs -Filter 'rules_v*.md' -File |
  Where-Object { $_.BaseName -match '^rules_v(\d{3})$' } |
  Sort-Object { [int]($_.BaseName -replace '^rules_v','') } -Descending
$md = @("# ルール版一覧", "", "| 版 | 日付 | パス |","|---:|:---|:---|")
foreach($f in $all){
  $txt  = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
  $date = if ($txt -match '最終更新日:\s*(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { '' }
  $rel  = (Resolve-Path $f.FullName).Path
  $md  += "| $($f.BaseName -replace '^rules_','') | $date | $rel |"
}
$md -join "`r`n" | Set-Content -Path $indexPath -Encoding UTF8
"[OK] インデックス更新: $indexPath" | Tee-Object -FilePath $logFile -Append

Write-Host "[DONE] $verTag を生成しました。" -ForegroundColor Green


