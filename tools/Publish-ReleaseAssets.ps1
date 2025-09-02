param(
  [string]$Root = "C:\Users\hiroy\Desktop\project-root",
  [string]$Version = "0.1.0-beta"
)

$ErrorActionPreference = "Stop"

function Save-Utf8NoBom([string]$Path,[string]$Text){
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $enc)
}
function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[OK]  $m" -ForegroundColor Green }
function Write-Err($m){ Write-Host "[ERR] $m" -ForegroundColor Red }

# --- 1) locate project ---
$proj = Join-Path $Root "viewer\src\TwinLeaf\TwinLeaf.csproj"
if(-not (Test-Path $proj)){ Write-Err "TwinLeaf.csproj not found: $proj"; exit 1 }

$outDir = Join-Path $Root ("publish\TwinLeaf_{0}" -f $Version)
New-Item -ItemType Directory -Force $outDir | Out-Null
Write-Info ("Publish dir = {0}" -f $outDir)

# --- 2) dotnet publish ---
$pubDir = Join-Path $outDir "bin"
dotnet publish $proj -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -o $pubDir

# --- 3) zip ---
$zipPath = Join-Path $outDir ("TwinLeaf_{0}.zip" -f $Version)
if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $pubDir "*") -DestinationPath $zipPath
Write-Ok ("Created ZIP: {0}" -f $zipPath)

# --- 4) sha256 ---
$shaPath = "$zipPath.sha256"
(Get-FileHash $zipPath -Algorithm SHA256).Hash + "  " + (Split-Path $zipPath -Leaf) | Out-File -Encoding ascii $shaPath
Write-Ok ("Created SHA256: {0}" -f $shaPath)

# --- 5) release notes (no code fences to avoid parsing issues) ---
$rnPath = Join-Path $outDir ("RELEASE-NOTES_v{0}.md" -f $Version)
$rn = @(
  "# TwinLeaf v$Version",
  "",
  "## Changes",
  "- Initial release.",
  "",
  "## Assets",
  "- " + (Split-Path $zipPath -Leaf),
  "- " + (Split-Path $shaPath -Leaf),
  "",
  "## Requirements",
  "- Windows 10/11",
  "- .NET Runtime (if not bundled)",
  "- WebView2 Runtime",
  "",
  "## Usage",
  "TwinLeaf.exe --profile chatgpt --url https://chatgpt.com/ --disable-gpu --js-flags=""--max-old-space-size=4096"""
)
Save-Utf8NoBom -Path $rnPath -Text ($rn -join [Environment]::NewLine)
Write-Ok ("Release notes: {0}" -f $rnPath)

# --- 6) summary ---
Write-Host ""
Write-Host "SUMMARY" -ForegroundColor DarkCyan
Write-Host ("  Version : {0}" -f $Version)
Write-Host ("  Output  : {0}" -f $outDir)
Write-Host  "  Assets  :"
Write-Host ("    - {0}" -f $zipPath)
Write-Host ("    - {0}" -f $shaPath)
Write-Host ("    - {0}" -f $rnPath)