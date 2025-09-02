# Stamp-Latest.ps1 — docs\rules_latest.md の先頭に保存時刻を再刻印する
# 使い方: pwsh -File .\Stamp-Latest.ps1

$proj = "C:\Users\hiroy\Desktop\project-root"
$path = Join-Path $proj "docs\rules_latest.md"

if (-not (Test-Path $path)) {
    Write-Error "ファイルが見つかりません: $path"
    exit 1
}

$ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$raw  = Get-Content $path -Raw -Encoding utf8

# 既存の保存時刻行を削除して置換
$body = $raw -replace '^\s*<!-- 保存時刻: .*? -->\s*\r?\n', ''

$newContent = "<!-- 保存時刻: $ts -->`n" + $body
Set-Content -Path $path -Value $newContent -Encoding utf8

Write-Host "[DONE] 保存時刻を再刻印しました: $ts" -ForegroundColor Green
