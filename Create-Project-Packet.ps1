param(
  [Parameter(Position=0)]
  [string]$ProjectRoot = "C:\Users\hiroy\Desktop\project-root"
)

# Ensure folders
$docs = Join-Path $ProjectRoot "docs"
$adr  = Join-Path $docs "ADR"
$tmpl = Join-Path $docs "TEMPLATES"
New-Item -ItemType Directory -Force -Path $docs, $adr, $tmpl | Out-Null

function Write-Utf8File($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $normalized = $Content -replace "`r`n", "`n"
  if (-not $normalized.EndsWith("`n")) { $normalized += "`n" }
  Set-Content -Path $Path -Value $normalized -Encoding utf8
}

# --------- Files ---------
$files = @{
  (Join-Path $docs "ProjectHub_ソフト開発統合_v2.md") = @"
# ソフト開発統合 — プロジェクトハブ v2
（Owner: Futaba / 更新日: 2025-08-31）

このハブは「運用ルール」「Viewer（Chat/AIクライアント）」「ずんだもんVTuber」の3本を1枚で俯瞰するための入口です。
- 共通方針：**Windows専用で拡充**、25分×マイクロ出荷、Preview→Save の舗装路、必要ならルールを柔軟に更新

## トラック一覧
1) **運用ルール（v020）**
   - Save時に `rules_latest.md` 先頭へ「保存時刻」を自動追記
   - Preview/Save/Rollback/Setup のショートカット運用
   - ルール変更は「小さく、すぐ反映、戻せる」

2) **Viewer（Windows）**
   - 目的：Chat/AI を安定して使えるクライアント（WebView2・描画相性の回避、再起動導線、簡易ログ）
   - 配布：インストーラ・README・寄付導線（BuyMeACoffee/PayPal）

3) **ずんだもんVTuber（Windows）**
   - 目的：リアルタイム発話（モーラ単位＋先読み）で“配信/録画の両対応”
   - 指標：体感遅延 150–250ms、OBS/録画の最小配線、導入動画

## 使い方（毎回の型）
1. ゴール1行 → 2. 25分作業 → 3. **Preview** → 4. **Save**  
保存で index/intro 同期＆保存時刻が刻印されます。承認コメントは不要。

## 主要ドキュメント
- PRD（Viewer）: `PRD_Viewer_v0.1.md`
- PRD（ずんだもん）: `PRD_Zundamon_v0.1.md`
- リリース手順: `Release_Checklist_v020.md`
- 収益/拡散: `Monetization_Plan_v0.1.md`
- リスク: `Risks_v0.1.md`
- 変更記録（ADR）: `ADR/ADR-0001-naming-policy.md`, `ADR/ADR-0002-governance.md`
- 会議テンプレ: `TEMPLATES/MEETING_NOTE.md`
- バックログ: `Backlog_merged.csv`
"@;

  (Join-Path $docs "PRD_Viewer_v0.1.md") = @"
# PRD — Viewer（Windows 安定クライアント） v0.1
## 目的
- Chat/AIの会話を **安定** して扱える Windows クライアントを提供する。デスクトップアプリ/ブラウザの相性で固まる課題を緩和。

## ユースケース
- 長時間の会話で固まりやすい/描画が止まる → **安定プリセット**で回避
- 途中停止してもすぐ復帰したい → **再起動ボタン/自動復帰**

## MVP範囲
- WebView2 埋め込み（安定フラグ切替）
- 安定プリセット（ANGLE=D3D11、DirectComposition無効などをGUIでトグル）
- クラッシュ/エラー簡易ログ（ユーザーがコピー/開ける）
- 再起動導線（1クリック）
- About/Helpに寄付リンク

## 非目標（v0系）
- Mac/Linux対応、マルチアカウント、拡張プラグイン

## 指標（最小）
- フリーズ・強制終了 率（月次）
- 自動復帰 成功率、ユーザ報告の再現率

## 依存/技術
- Windows 10/11 + PowerShell 7+, WebView2, .NET or Electron系（どちらでも可）
- 安定フラグ例：`--use-angle=d3d11`, `--disable-features=DirectComposition`

## リリース基準
- 連続1時間の会話テストで停止なし
- README/インストーラ/寄付導線が揃う
"@;

  (Join-Path $docs "PRD_Zundamon_v0.1.md") = @"
# PRD — ずんだもんVTuber（Windows） v0.1
## 目的
- 誰でも“ずんだもん”になれるリアルタイム発話・配信ツールを **完全フリー** で提供。

## MVP範囲
- モーラ（拍）単位の逐次合成 + 1–2拍先読みで韻律維持
- ストリーミングTTS（例：FastPitch/FS2 + HiFi-GAN相当）40–80ms チャンク生成
- OBS/録画の最小配線（音声+簡易アバター）
- プリセット（相槌/息継ぎ/SFX）で“間”を演出
- 導入動画（1–2分）＋ README

## 指標
- 体感遅延 150–250ms
- 短文の自然性（主観 4/5 以上）
- 初回セットアップ完了率（完走率）

## 非目標（v0系）
- 多言語/歌唱/高度な表情トラッキング
- Mac/Linux対応

## リリース基準
- 短文リアルタイム発話デモ成功（< 250ms）
- OBS出力・録画が動作
"@;

  (Join-Path $docs "Release_Checklist_v020.md") = @"
# Release Checklist（v020 運用）
- [ ] 変更内容を1行で要約（ゴール）
- [ ] `Rules-Preview`（保存なし差分確認）
- [ ] `Rules-Save-v020`（保存＋保存時刻刻印＋ログ出力）
- [ ] `docs/rules_index.md` と `docs/introtemplate.md` が更新されている
- [ ] 破壊的変更なら `Rollback` ショートカットが動くか確認
- [ ] 必要に応じて PRD/Backlog を更新（このパケット内のファイル）
"@;

  (Join-Path $docs "Monetization_Plan_v0.1.md") = @"
# Monetization & Growth Plan v0.1
## 方針（長期）
- **完全フリー**でユーザーを広げる → コアユーザー/法人で収益化

## 入口（Viewer / ずんだもん共通）
- ダウンロードは1クリック
- 初回セットアップは一本道
- 公式デモ動画 & チュートリアルで“最初の体験”を担保

## 収益導線
- 寄付：BuyMeACoffee / PayPal / GitHub Sponsors / FANBOX
- 有料アドオン：表情パック・モーション・背景
- 法人ライセンス：商用配信/PR用途（個人は無料）
- 周辺：Booth 素材/テンプレ販売、動画の広告収益

## 時系列
- v1.0：無料版をリリース（使える体験を最優先）
- v1.1：OBS/録画の強化、安定化
- v1.2：アドオン販売開始（表情/モーション）
- v2.x：法人ライセンスとサポート窓口整備
"@;

  (Join-Path $docs "Risks_v0.1.md") = @"
# リスクと対策 v0.1
| リスク | 兆候 | 対策（一次） | 恒久策 |
|---|---|---|---|
| Viewerが環境相性で固まる | “生成中”のまま停止 | 安定プリセット/再起動導線 | キャッシュ自動クリア、例外設定ガイド |
| ずんだもんの遅延が大 | 300ms超で“遅い”体感 | 先読み2拍/短チャンク/クロスフェード | ONNX最適化、DirectML/CUDA、INT8化検証 |
| 命名ポリシー抵触 | “GPT/ChatGPT”を製品名に使用 | 回避命名ガイド | PR/READMEの表現を統一 |
| 1人運用で破綻 | 作業が積み残る | 25分×マイクロ出荷 | Preview→Saveの舗装路徹底 |
"@;

  (Join-Path $adr "ADR-0001-naming-policy.md") = @"
# ADR-0001 命名ポリシー（採用）
- 製品名やアプリ名に **“ChatGPT”/“GPT”** を含めない
- 代替：汎用語＋独自ブランド（例：LeafView, PromptDesk など）
- 理由：混同回避・商標/審査リスク低減・将来の多モデル対応性
"@;

  (Join-Path $adr "ADR-0002-governance.md") = @"
# ADR-0002 ガバナンス（採用）
- ソロ運用：**承認＝Save実行**、承認コメントは不要
- 保存時に `rules_latest.md` 先頭へ「保存時刻」を自動追記
- ルール変更は小刻みに（戻せる状態で）→ 問題があれば即ロールバック
"@;

  (Join-Path $tmpl "MEETING_NOTE.md") = @"
# ミーティングノート（テンプレ）
- 目的（1行）:
- 決定事項（Decision）:
- 宿題（Action）: 担当 / 期日
- 反省（振り返りメモ）:
"@;

  (Join-Path $docs "Backlog_merged.csv") = @"
Type,Track,Title,Detail,Priority,Status,Owner,Due
Rule,Rules,Fix v020 scope,Windows限定/保存時刻刻印/ショートカット整備,High,Doing,Futaba,2025-09-03
Rule,Rules,Rollback shortcut,前版復元の即時実行を検証,High,Todo,Futaba,2025-09-04
App,Viewer,Stability preset,ANGLE=D3D11/DirectComposition切替をGUI化,High,Doing,Futaba,2025-09-06
App,Viewer,Crash log & relaunch,簡易ログ採取と1クリック再起動,Med,Todo,Futaba,2025-09-07
App,Viewer,Installer & README,配布雛形/寄付導線,Med,Todo,Futaba,2025-09-08
Vtuber,Zundamon,Mora streaming TTS,1–2拍先読み/40–80msチャンク/クロスフェード,High,Doing,Futaba,2025-09-09
Vtuber,Zundamon,OBS wiring,音声+簡易アバターの最小配線,Med,Todo,Futaba,2025-09-10
Ops,Common,Demo & tutorial,導入1–2分動画/スクショ,Low,Todo,Futaba,2025-09-12
"@;
}

foreach ($kvp in $files.GetEnumerator()) {
  Write-Utf8File -Path $kvp.Key -Content $kvp.Value
  Write-Host ("[WRITE] " + $kvp.Key)
}

Write-Host "`n[DONE] プロジェクト最小セットを出力しました。`n- 置き先: $docs" -ForegroundColor Green
