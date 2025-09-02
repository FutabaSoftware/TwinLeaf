param(
  [Parameter(Mandatory=$true)][string]$ExportZipOrFolder,
  [string]$OutDir = "$env:USERPROFILE\Desktop\project-root\docs"
)
if(-not (Get-Command python -ErrorAction SilentlyContinue)){
  Write-Host "Pythonが見つかりません。winget install -e --id Python.Python.3.12" -ForegroundColor Yellow
  exit 1
}
$script = Join-Path $PSScriptRoot "convert_chatgpt_export.py"
Write-Host "Input : $ExportZipOrFolder"
Write-Host "OutDir: $OutDir"
python "$script" "$ExportZipOrFolder" "$OutDir"
