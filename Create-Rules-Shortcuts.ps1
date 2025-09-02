# Create-Rules-Shortcuts.ps1 — Desktop に Preview / Save (v020) ショートカットを作成
param(
  [string]$ProjectRoot = "C:\Users\hiroy\Desktop\project-root"
)

$desktop = [Environment]::GetFolderPath("Desktop")
$pwsh = (Get-Command pwsh).Source  # PowerShell 7 の実行ファイル
if (-not $pwsh) { throw "PowerShell 7 (pwsh) が見つかりません。" }

# 1) Preview ショートカット
$previewTarget = Join-Path $ProjectRoot "Preview-Rules.ps1"
if (!(Test-Path $previewTarget)) { throw "見つかりません: $previewTarget" }

$previewLnk = Join-Path $desktop "Rules-Preview.lnk"
$shell = New-Object -ComObject WScript.Shell
$sc1 = $shell.CreateShortcut($previewLnk)
$sc1.TargetPath = $pwsh
$sc1.Arguments  = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$previewTarget`""
$sc1.WorkingDirectory = $ProjectRoot
$sc1.WindowStyle = 1
$sc1.Description = "ルールの差分をプレビュー（保存なし）"
$sc1.Save()

# 2) Save v020 ショートカット（Apply-Rules-v020.ps1）
$saveTarget = Join-Path $ProjectRoot "Apply-Rules-v020.ps1"
if (!(Test-Path $saveTarget)) { throw "見つかりません: $saveTarget" }

$saveLnk = Join-Path $desktop "Rules-Save-v020.lnk"
$sc2 = $shell.CreateShortcut($saveLnk)
$sc2.TargetPath = $pwsh
$sc2.Arguments  = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$saveTarget`""
$sc2.WorkingDirectory = $ProjectRoot
$sc2.WindowStyle = 1
$sc2.Description = "v020 保存＋保存時刻追記（ログ付き）"
$sc2.Save()

Write-Host "[DONE] デスクトップにショートカットを作成しました。" -ForegroundColor Green
Write-Host " - $previewLnk"
Write-Host " - $saveLnk"
