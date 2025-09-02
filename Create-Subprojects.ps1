param(
  [Parameter(Position=0)]
  [string]$ProjectRoot = "C:\Users\hiroy\Desktop\project-root"
)

# ---------- Helpers ----------
function New-Dir($p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Write-Utf8($Path, $Text) {
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Dir $dir }
  $normalized = $Text -replace "`r`n", "`n"
  if (-not $normalized.EndsWith("`n")) { $normalized += "`n" }
  Set-Content -Path $Path -Encoding utf8 -Value $normalized
}

# ---------- Layout ----------
$root = $ProjectRoot.TrimEnd('\')
$viewer    = Join-Path $root "viewer"
$zundamon  = Join-Path $root "zundamon"

$paths = @(
  (Join-Path $viewer "docs"),
  (Join-Path $viewer "src"),
  (Join-Path $viewer "assets"),
  (Join-Path $zundamon "docs"),
  (Join-Path $zundamon "src"),
  (Join-Path $zundamon "assets")
)
$paths | ForEach-Object { New-Dir $_ }

# ---------- Seed docs from project-root\docs if exist ----------
$rootDocs = Join-Path $root "docs"
$viewerPRD   = Join-Path $rootDocs "PRD_Viewer_v0.1.md"
$zundaPRD    = Join-Path $rootDocs "PRD_Zundamon_v0.1.md"
$backlogAll  = Join-Path $rootDocs "Backlog_merged.csv"

if (Test-Path $viewerPRD) {
  Copy-Item $viewerPRD (Join-Path $viewer "docs\PRD_Viewer_v0.1.md") -Force
}
if (Test-Path $zundaPRD) {
  Copy-Item $zundaPRD (Join-Path $zundamon "docs\PRD_Zundamon_v0.1.md") -Force
}

# ---------- Create README.md for each project ----------
$viewerReadme = @"
# Viewer（Windows 安定クライアント）
- 目的：WebView2 や描画相性の問題を回避し、**安定**して会話できるクライアントを提供
- まずは `docs\PRD_Viewer_v0.1.md` を確認して、MVPの着手点を決める

## 毎回の運用
1. 目標1行を書く
2. 25分だけ作業
3. project-root で **Rules-Preview → Rules-Save**（保存時刻は自動刻印）

## フォルダ
- `docs/` … 仕様・ノート
- `src/` … ソースコード
- `assets/` … アイコン、画像、音声など
"@
Write-Utf8 (Join-Path $viewer "README.md") $viewerReadme

$zundaReadme = @"
# ずんだもんVTuber（Windows）
- 目的：モーラ単位の逐次合成 + 先読みで、**リアルタイム発話**の配信/録画を快適に
- まずは `docs\PRD_Zundamon_v0.1.md` を確認して、MVPの着手点を決める

## 毎回の運用
1. 目標1行を書く
2. 25分だけ作業
3. project-root で **Rules-Preview → Rules-Save**（保存時刻は自動刻印）

## フォルダ
- `docs/` … 仕様・ノート
- `src/` … ソースコード
- `assets/` … アイコン、画像、音声など
"@
Write-Utf8 (Join-Path $zundamon "README.md") $zundaReadme

# ---------- Minimal starter in src ----------
$viewerStarter = @"
// viewer/src/main.todo
// ここから：UI技術選定（.NET WinUI / WPF / Electron）を決める
// MVP: WebView2 埋め込み + 安定フラグ切替 + 再起動ボタン + 簡易ログ
"@
Write-Utf8 (Join-Path $viewer "src\main.todo") $viewerStarter

$zundaStarter = @"
# zundamon/src/README.todo
# MVP: ストリーミングTTS（40–80ms）+ 先読み2拍 + OBS最小配線
# 優先：体感遅延 150–250ms を満たす最小構成
"@
Write-Utf8 (Join-Path $zundamon "src\README.todo") $zundaStarter

# ---------- Filter Backlog to each project ----------
if (Test-Path $backlogAll) {
  try {
    $rows = Import-Csv -Path $backlogAll
    $viewerRows   = $rows | Where-Object { $_.Track -match 'Viewer' }
    $zundaRows    = $rows | Where-Object { $_.Track -match 'Zundamon' -or $_.Track -match 'Vtuber' }
    if ($viewerRows)   { $viewerRows  | Export-Csv (Join-Path $viewer "docs\Backlog.csv") -NoTypeInformation -Encoding UTF8 }
    if ($zundaRows)    { $zundaRows   | Export-Csv (Join-Path $zundamon "docs\Backlog.csv") -NoTypeInformation -Encoding UTF8 }
  } catch {
    Write-Warning "Backlog_merged.csv のフィルタに失敗しました: $($_.Exception.Message)"
  }
}

# ---------- Root-level convenience launcher ----------
$hub = @"
# このリポジトリの歩き方（ショート版）
- **ルール更新** … project-root にあるショートカット
  - Rules-Preview → Rules-Save-v020（保存時刻は自動刻印）
- **Viewer 開発** … `viewer/` フォルダから開始（README参照）
- **ずんだもん 開発** … `zundamon/` フォルダから開始（README参照）

> 迷ったら `docs\ProjectHub_ソフト開発統合_v2.md` を見れば全体像が掴めます。
"@
Write-Utf8 (Join-Path $root "HOWTO_START.md") $hub

Write-Host "[DONE] サブプロジェクト（viewer / zundamon）を初期化しました。" -ForegroundColor Green
Write-Host " - $viewer"
Write-Host " - $zundamon"
