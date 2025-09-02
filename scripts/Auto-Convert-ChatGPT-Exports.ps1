$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# パス
$Downloads = Join-Path $env:USERPROFILE 'Downloads'
$SetupDir  = Join-Path $Downloads 'gpt_project_setup'
$DocsDir   = Join-Path $env:USERPROFILE 'Desktop\project-root\docs'
$TmpRoot   = Join-Path $env:TEMP ('chatgpt_export_' + (Get-Date -Format yyyyMMdd_HHmmss))
$LogDir    = Join-Path $env:USERPROFILE 'Desktop\project-root\logs'
$null = New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogFile  = Join-Path $LogDir ("run_" + (Get-Date -Format yyyyMMdd_HHmmss) + ".log")

function Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = '{0}  {1}' -f $ts, $msg
  $line | Tee-Object -FilePath $LogFile -Append | Out-Host
}

try {
  Log ('[P] Start launcher v1.2')

  # ZIP選定（中身検査）
  $zip = Get-ChildItem -LiteralPath $Downloads -Filter '*.zip' -File |
    Sort-Object LastWriteTime -Descending |
    Where-Object {
      try {
        $z = [System.IO.Compression.ZipFile]::OpenRead($_.FullName)
        $hit = $false
        foreach ($e in $z.Entries) {
          if ($e.FullName -match '(^|/|\\)conversations\.json$') { $hit = $true; break }
        }
        $z.Dispose()
        $hit
      } catch { $false }
    } | Select-Object -First 1

  if (-not $zip) { throw 'Downloads に conversations.json を含むZIPが見つかりません。' }
  Log ('[D] ZIP: {0}' -f $zip.Name)

  # 展開
  $null = New-Item -ItemType Directory -Path $TmpRoot -Force
  Expand-Archive -LiteralPath $zip.FullName -DestinationPath $TmpRoot -Force

  # conversations.json を含むフォルダ
  $inputFolder = if (Test-Path (Join-Path $TmpRoot 'conversations.json')) {
    $TmpRoot
  } else {
    Get-ChildItem -LiteralPath $TmpRoot -Recurse -File -Filter 'conversations.json' |
      Select-Object -First 1 | ForEach-Object { Split-Path $_.FullName -Parent }
  }
  if (-not $inputFolder) { throw '展開後に conversations.json が見つかりません。' }

  # 出力先
  if (-not (Test-Path -LiteralPath $DocsDir)) { New-Item -ItemType Directory -Path $DocsDir | Out-Null }

  # 変換本体
  $converter = Join-Path $SetupDir 'ChatGPT_Export2MD.ps1'
  if (-not (Test-Path -LiteralPath $converter)) { throw ('変換スクリプトが見つかりません: {0}' -f $converter) }

  # 署名（-Input/-OutDir）確認
  $help = & $converter -? 2>&1 | Out-String
  if ($help -notmatch '-Input' -or $help -notmatch '-OutDir') {
    throw ('変換スクリプトが旧版です。（-Input / -OutDir がありません）: {0}' -f $converter)
  }

  Log ('[D] Run converter: Source={0}  Out={1}' -f $inputFolder, $DocsDir)
  $out = & $converter -Input $inputFolder -OutDir $DocsDir 2>&1
  foreach ($line in $out) { Log ('[D] ' + [string]$line) }

  Log ('[C] Completed successfully')
}
catch {
  Log ('[C] ERROR: {0}' -f $_.Exception.Message)
}
finally {
  try { if (Test-Path $TmpRoot) { Remove-Item -LiteralPath $TmpRoot -Recurse -Force } } catch {}
  Log ('[A] See log: {0}' -f $LogFile)
  Start-Process notepad.exe $LogFile | Out-Null
}