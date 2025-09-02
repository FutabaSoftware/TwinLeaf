# Convert-LatestExport.ps1
param(
  [string]$ExportsDir = "$env:USERPROFILE\Documents\ChatGPT_exports",
  [string]$OutDir     = "$env:USERPROFILE\Desktop\project-root\docs"
)
$latest = Get-ChildItem $ExportsDir -Filter *.zip -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(-not $latest){ Write-Host "ZIPが見つかりません: $ExportsDir" -f Yellow; exit 1 }

$runner = Join-Path $PSScriptRoot "run_convert.ps1"
Write-Host "変換: $($latest.FullName)" -f Cyan
pwsh -ExecutionPolicy Bypass -File $runner -ExportZipOrFolder $latest.FullName -OutDir $OutDir
