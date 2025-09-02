param(
  [string[]]$Profiles = @("default"),
  [object]$MaxLogBytes = "5MB",
  [int]$Retain = 7,
  [switch]$DryRun
)

# --- helpers ---------------------------------------------------------------

function Parse-Size {
  param([Parameter(Mandatory)][object]$Value)
  if ($Value -is [long] -or $Value -is [int]) { return [int64]$Value }
  $s = "$Value".ToUpper()
  if ($s -match '^\s*(\d+)\s*(B|KB|MB|GB)?\s*$') {
    $n = [int64]$matches[1]
    switch ($matches[2]) {
      'KB' { $n *= 1KB }
      'MB' { $n *= 1MB }
      'GB' { $n *= 1GB }
      default { } # bytes or empty
    }
    return $n
  }
  throw "Invalid size: $Value"
}

function Remove-WithRetry {
  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$Retries = 6,
    [int]$DelayMs = 500
  )
  if (-not (Test-Path -LiteralPath $Path)) { return $true }
  for ($i=0; $i -lt $Retries; $i++) {
    try {
      Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
      return $true
    } catch {
      Start-Sleep -Milliseconds $DelayMs
    }
  }
  return $false
}

function Rotate-Log {
  param(
    [Parameter(Mandatory)][string]$Path,
    [object]$MaxBytes = "5MB",
    [int]$Retain = 7,
    [switch]$DryRun
  )
  $max = Parse-Size $MaxBytes
  if (-not (Test-Path -LiteralPath $Path)) { return "No rotation: file missing" }
  $f = Get-Item -LiteralPath $Path -ErrorAction Stop
  if ($f.Length -le $max) { return "No rotation: $($f.Length) bytes" }

  $bak = "$Path.$((Get-Date).ToString('yyyyMMdd_HHmmss')).bak"
  if ($DryRun) {
    "DRYRUN copy -> $bak"
    "DRYRUN clear -> $Path"
  } else {
    Copy-Item -LiteralPath $Path -Destination $bak -Force
    Clear-Content -LiteralPath $Path
  }

  # prune old backups beyond Retain
  $pattern = [System.IO.Path]::GetFileName($Path) + ".*.bak"
  $dir = Split-Path -LiteralPath $Path -Parent
  $backs = Get-ChildItem -LiteralPath $dir -Filter $pattern -File |
           Sort-Object LastWriteTime -Descending
  if ($backs.Count -gt $Retain) {
    $toRemove = $backs | Select-Object -Skip $Retain
    foreach($b in $toRemove){
      if ($DryRun) { "DRYRUN remove old backup: $($b.FullName)" }
      else { Remove-Item -LiteralPath $b.FullName -Force -ErrorAction SilentlyContinue }
    }
  }

  if ($DryRun) { return "DRYRUN rotated (size=$($f.Length))" }
  return "Rotated -> $bak"
}

function Clean-OneProfile {
  param(
    [Parameter(Mandatory)][string]$Profile,
    [object]$MaxLogBytes = "5MB",
    [switch]$DryRun
  )
  "---- PROFILE: $Profile ----"

  # 1) stop app
  if ($DryRun) {
    "DRYRUN stop process: TwinLeaf"
  } else {
    Stop-Process -Name TwinLeaf -ErrorAction SilentlyContinue
  }

  # 2) remove WebView2 cache under LOCALAPPDATA\TwinLeaf\<profile>\WebView2
  $ud = Join-Path $env:LOCALAPPDATA "TwinLeaf\$Profile\WebView2"
  if (Test-Path -LiteralPath $ud) {
    if ($DryRun) {
      "DRYRUN clean: $ud"
    } else {
      if (Remove-WithRetry $ud) { "Cleaned: $ud" } else { "WARN: failed to clean (locked?): $ud" }
    }
  } else {
    "No cache: $ud"
  }

  # 3) rotate app run.log in LOCALAPPDATA\TwinLeaf
  $logDir = Join-Path $env:LOCALAPPDATA "TwinLeaf"
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $runLog = Join-Path $logDir "run.log"
  Rotate-Log -Path $runLog -MaxBytes $MaxLogBytes -Retain $Retain -DryRun:$DryRun
}

# --- entry -----------------------------------------------------------------

function Invoke-CleanTwinLeaf {
  param(
    [string[]]$Profiles,
    [object]$MaxLogBytes,
    [int]$Retain,
    [switch]$DryRun
  )
  foreach($p in $Profiles){
    Clean-OneProfile -Profile $p -MaxLogBytes $MaxLogBytes -DryRun:$DryRun
  }
}

# Run immediately only when executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
  Invoke-CleanTwinLeaf -Profiles $Profiles -MaxLogBytes $MaxLogBytes -Retain $Retain -DryRun:$DryRun
}
