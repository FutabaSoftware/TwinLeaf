#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$Summary,
  [string]$Details = "",
  [switch]$DiffOnly,
  [switch]$Rollback
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ルート/ログ
$PR   = Split-Path -Parent $PSScriptRoot
$DOCS = Join-Path $PR 'docs'
$LOGS = Join-Path $PR 'logs'
New-Item -ItemType Directory -Force -Path $DOCS,$LOGS | Out-Null
$Transcript = Join-Path $LOGS ("Update-Rules_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

# Transcript を開始 → 実行全体を try{}finally{} で囲む
try {
  try { Start-Transcript -Path $Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}

  # Python 実行体の検出
  $Py = $null
  foreach($c in @('py -3','py','python')){
    try { & $c -V *> $null; if($LASTEXITCODE -eq 0){ $Py = $c; break } } catch {}
  }
  if(-not $Py){ throw "Python が見つかりません。公式版 or Miniconda をインストールしてください。" }

  # 本体
  $PyMain = Join-Path $PSScriptRoot 'update_rules.py'
  if(-not (Test-Path -LiteralPath $PyMain)){ throw "本体が見つかりません: $PyMain" }

  # Summary 未指定なら対話で入力
  if([string]::IsNullOrWhiteSpace($Summary)){
    Write-Host '変更概要（1〜数行）を入力してください。空行で終了。' -ForegroundColor Yellow
    $lines=@()
    while($true){ $l = Read-Host; if([string]::IsNullOrWhiteSpace($l)){ break }; $lines += $l }
    $Summary = $lines -join "`r`n"
    if([string]::IsNullOrWhiteSpace($Summary)){ throw 'Summary が空です。' }
  }

  # 引数
  $argsList = @($PyMain,'--summary',$Summary)
  if($Details)  { $argsList += @('--details', $Details) }
  if($DiffOnly) { $argsList += '--diff-only' }
  if($Rollback){ $argsList += '--rollback' }

  # 確認つき実行（-WhatIf/プロンプト対応）
  if($PSCmdlet.ShouldProcess("Generate rules (Python)", ($argsList -join ' '))){
    & $Py $argsList
    if($LASTEXITCODE -ne 0){ throw "Python 側でエラー ($LASTEXITCODE)" }
  }
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
}
