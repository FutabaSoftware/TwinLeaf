param(
  [switch]$Apply,
  [string]$Root
)

# --- resolve Root (project-root) ---
if ([string]::IsNullOrWhiteSpace($Root)) {
  if ($PSScriptRoot) {
    # tools\*.ps1 -> parent of parent is project-root
    $Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
  } else {
    throw "Root not specified. Run as a script or pass -Root."
  }
}
if (-not (Test-Path $Root)) { throw ("Root not found: {0}" -f $Root) }
$Root = (Resolve-Path $Root).Path
Write-Host ("[INFO] Root = {0}" -f $Root) -ForegroundColor Cyan

# --- excludes (regex) ---
# exclude .git, .vs, bin, obj, artifacts, packages, venv/.venv, tools (script lives here), and common temp dirs
$excludePattern = '(\\|/)(\.git|\.vs|bin|obj|artifacts|packages|venv|\.venv|tools|dist|build|node_modules)(\\|/|$)'
function Is-ExcludedDir([string]$path) { return ($path -imatch $excludePattern) }

# --- patterns ---
$renamePatterns = @('ViewerHello','viewerhello','viewer-hello') # for names
$replacePairs = @(
  @{from='ViewerHello';  to='TwinLeaf'},
  @{from='viewerhello';  to='twinleaf'},
  @{from='viewer-hello'; to='twinleaf'}
)

# --- collect items under Root only ---
$all = Get-ChildItem -Path "$Root\*" -Recurse -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -like "$Root*" -and -not (Is-ExcludedDir $_.FullName) }

$dirs  = $all | Where-Object {$_.PSIsContainer}           | Sort-Object { $_.FullName.Length } -Descending
$files = $all | Where-Object { -not $_.PSIsContainer }

# --- 1) rename (dirs deepest first, then files) ---
$renamed = 0
function Try-Rename($item) {
  foreach($p in $renamePatterns){
    if ($item.Name -match $p){
      $newName = ($item.Name -replace $p,'TwinLeaf')
      $parent  = Split-Path $item.FullName -Parent
      if ([string]::IsNullOrWhiteSpace($parent)) { return }
      if ($Apply){
        try{
          Rename-Item -LiteralPath $item.FullName -NewName $newName -Force
          Write-Host ("[RENAMED] {0} -> {1}" -f $item.FullName,$newName) -ForegroundColor Green
          $script:renamed++
        } catch {
          Write-Host ("[SKIP]   {0} ({1})" -f $item.FullName,$_.Exception.Message) -ForegroundColor DarkYellow
        }
      } else {
        Write-Host ("[DRYRUN] {0} -> {1}" -f $item.FullName,$newName) -ForegroundColor Yellow
      }
      break
    }
  }
}

foreach($d in $dirs){  Try-Rename $d }
foreach($f in $files){ Try-Rename $f }

# --- 2) content replace in text files ---
$exts = '*.sln','*.csproj','*.props','*.targets','*.cs','*.xaml','*.json','*.ps1','*.md','*.iss','*.config','*.xml'
$targets = Get-ChildItem -Path "$Root\*" -Recurse -File -Include $exts -ErrorAction SilentlyContinue |
  Where-Object { -not (Is-ExcludedDir $_.DirectoryName) }

$updated = 0
foreach($f in $targets){
  try{
    $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
    if ($null -eq $text) { continue } # empty or unreadable file
    $orig = $text
    foreach($pair in $replacePairs){
      $pattern = [regex]::Escape($pair.from)
      $text = [regex]::Replace($text, $pattern, $pair.to, 'IgnoreCase')
    }
    if ($text -ne $orig){
      if ($Apply){
        Set-Content -LiteralPath $f.FullName -Value $text -Encoding UTF8
        Write-Host ("[UPDATED] {0}" -f $f.FullName) -ForegroundColor Green
        $updated++
      } else {
        Write-Host ("[DRYRUN] Would update {0}" -f $f.FullName) -ForegroundColor Yellow
      }
    }
  } catch {
    Write-Host ("[SKIP]   {0} ({1})" -f $f.FullName,$_.Exception.Message) -ForegroundColor DarkYellow
  }
}

Write-Host ("`n[SUMMARY] Renamed={0}, ContentUpdated={1}, Apply={2}" -f $renamed,$updated,$Apply.IsPresent) -ForegroundColor Cyan
Write-Host "Note: .git/.vs/bin/obj/artifacts/packages/venv/.venv/tools etc. are excluded." -ForegroundColor DarkCyan
