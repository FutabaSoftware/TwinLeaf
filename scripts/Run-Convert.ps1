# Run-Convert.ps1 — ZIP検出→展開→変換→結果集計→rules.mdに「BML 学びログ」を追記
$ErrorActionPreference = 'Stop'

# SSOT
$Root = Join-Path $env:USERPROFILE 'Desktop\project-root'
$Docs = Join-Path $Root 'docs'
$Logs = Join-Path $Root 'logs'
$null = New-Item -ItemType Directory -Path $Docs,$Logs -Force | Out-Null
$Rules = Join-Path $Docs 'rules.md'
$Log   = Join-Path $Logs ("run_{0}.log" -f (Get-Date -Format yyyyMMdd_HHmmss))

function Add-LearnLogToRules {
  param(
    [Parameter(Mandatory)][string]$RulesPath,
    [Parameter(Mandatory)][datetime]$When,
    [Parameter(Mandatory)][int]$Created,
    [Parameter(Mandatory)][int]$WarnCount,
    [Parameter(Mandatory)][int]$ErrCount,
    [string[]]$WarnSamples,
    [string[]]$ErrSamples
  )
  $enc = New-Object System.Text.UTF8Encoding($false)
  if (-not (Test-Path -LiteralPath $RulesPath)) {
    $stub = "# ルール（SSOT）`r`n`r`n## BML 学びログ`r`n"
    [IO.File]::WriteAllText($RulesPath, $stub, $enc)
  }
  $text = Get-Content -LiteralPath $RulesPath -Raw -Encoding UTF8
  $hasSection = [regex]::IsMatch(
    $text,
    '^\s*##\s*BML 学びログ',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
  )
  if (-not $hasSection) { $text += "`r`n`r`n## BML 学びログ`r`n" }

  $ts = $When.ToString('yyyy-MM-dd HH:mm')
  $block = @"
### 学びログ: $ts
- 生成: **$Created** 件 / WARN: **$WarnCount** / ERR: **$ErrCount**
- 恒久対策（仮案）:
  - 入力パス/`conversations.json` の自動検出フォールバック
  - パス長・禁止文字サニタイズ（閾値230は状況に応じて調整）
  - FAIL 多発時は出力パスを浅く or タイトル短縮幅を拡大
  - 手動実行は本ランナーへ統一（右クリック or 定期起動）

"@
  if ($WarnSamples -and $WarnSamples.Count -gt 0) {
    $block += "**WARN 抜粋**:`r`n````text`r`n" + (($WarnSamples | Select-Object -First 5) -join "`r`n") + "`r`n`````r`n"
  }
  if ($ErrSamples -and $ErrSamples.Count -gt 0) {
    $block += "**ERR/FAIL 抜粋**:`r`n````text`r`n" + (($ErrSamples | Select-Object -First 5) -join "`r`n") + "`r`n`````r`n"
  }
  $block += "`r`n"
  [IO.File]::WriteAllText($RulesPath, ($text + $block), $enc)
}

# ZIP 自動検出
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Downloads = Join-Path $env:USERPROFILE 'Downloads'
$zip = Get-ChildItem -LiteralPath $Downloads -Filter '*.zip' -File |
  Sort-Object LastWriteTime -Descending |
  Where-Object {
    try {
      $z=[IO.Compression.ZipFile]::OpenRead($_.FullName)
      $hit=$false; foreach($e in $z.Entries){ if($e.FullName -match '(^|/|\\)conversations\.json$'){ $hit=$true; break } }
      $z.Dispose(); $hit
    } catch { $false }
  } | Select-Object -First 1

if (-not $zip) { throw "Downloads に ChatGPT エクスポートZIPが見つかりません。" }

"[I] ZIP : $($zip.FullName)" | Out-File -FilePath $Log -Encoding utf8

# 展開
$Tmp = Join-Path $env:TEMP ('chatgpt_export_' + (Get-Date -Format yyyyMMdd_HHmmss))
$null = New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
Expand-Archive -LiteralPath $zip.FullName -DestinationPath $Tmp -Force

$convs = Get-ChildItem -LiteralPath $Tmp -Recurse -File -Filter 'conversations.json' | Select-Object -First 1
if (-not $convs) { throw "展開後に conversations.json が見つかりません。展開先: $Tmp" }
$inputFolder = Split-Path $convs.FullName -Parent

$inAbs  = (Resolve-Path -LiteralPath $inputFolder).Path
$outAbs = (Resolve-Path -LiteralPath $Docs).Path

Write-Host "[I] Src: $inAbs"
Write-Host "[I] Out: $outAbs"

# 変換実行
$Converter = Join-Path $env:USERPROFILE 'Downloads\gpt_project_setup\ChatGPT_Export2MD.ps1'
if (-not (Test-Path -LiteralPath $Converter)) { throw "変換スクリプトが見つかりません: $Converter" }

$lines = & $Converter -Input $inAbs -OutDir $outAbs 2>&1 | Tee-Object -Variable out | Tee-Object -FilePath $Log

# 集計
$created   = ($out | Where-Object { $_ -match '^\[OK\]\s+Created:' }).Count
$warnLines =  $out | Where-Object { $_ -match '^\[WARN\]|\bTruncated and created\b' }
$errLines  =  $out | Where-Object { $_ -match '^\[ERR\]|\bFAIL:' }
$warnCount = $warnLines.Count
$errCount  = $errLines.Count

"[I] Created=$created  Warn=$warnCount  Err=$errCount" | Out-File -FilePath $Log -Append -Encoding utf8
"[I] Log: $Log" | Out-File -FilePath $Log -Append -Encoding utf8

# 学びログ追記
Add-LearnLogToRules -RulesPath $Rules -When (Get-Date) -Created $created -WarnCount $warnCount -ErrCount $errCount `
  -WarnSamples ($warnLines | Select-Object -First 5) -ErrSamples ($errLines | Select-Object -First 5)

Write-Host "[OK] 変換と学び追記が完了。Log: $Log"
