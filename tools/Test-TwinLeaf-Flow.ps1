param(
  [string]$Url     = "https://example.com",
  [string]$Profile = "default"
)

Write-Host "TwinLeaf flow test: start"

# Find latest TwinLeaf.exe under project root
$root = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$exe = Get-ChildItem -Recurse -Path $root -Filter TwinLeaf.exe -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $exe) {
  Write-Error "TwinLeaf.exe not found. Build first."
  exit 1
}
Write-Host ("INFO: EXE = {0}" -f $exe.FullName)

# 1) Launch with --profile
Start-Process $exe.FullName ("--profile {0}" -f $Profile) | Out-Null

# Wait up to 6s until process appears
$ok = $false
for($i=0;$i -lt 30;$i++){
  Start-Sleep -Milliseconds 200
  if (Get-Process TwinLeaf -ErrorAction SilentlyContinue) { $ok = $true; break }
}
if($ok){ Write-Host "OK: launched" } else { Write-Host "WARN: launch not detected (continuing)" }

# 2) Hand off URL
Start-Process $exe.FullName ("--url {0}" -f $Url) | Out-Null
Start-Sleep -Milliseconds 800
Write-Host ("OK: URL handoff -> {0}" -f $Url)

# 3) Request exit
Start-Process $exe.FullName "--exit" | Out-Null

# Wait up to 6s for process to stop
$stopped = $false
for($i=0;$i -lt 30;$i++){
  Start-Sleep -Milliseconds 200
  if (-not (Get-Process TwinLeaf -ErrorAction SilentlyContinue)) { $stopped = $true; break }
}
if($stopped){ Write-Host "OK: exit handoff" } else { Write-Host "WARN: process may still be running" }

# 4) Show log tail
$log = Join-Path $env:LOCALAPPDATA "TwinLeaf\run.log"
if (Test-Path $log) {
  Write-Host ""
  Write-Host "=== run.log (tail 40) ==="
  Get-Content $log -Tail 40
} else {
  Write-Host ("WARN: log not found: {0}" -f $log)
}

Write-Host "TwinLeaf flow test: done"
