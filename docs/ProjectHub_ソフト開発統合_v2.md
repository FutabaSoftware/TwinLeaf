# ソフト開発統合 — プロジェクトハブ v2
（Owner: Futaba / 更新日: 2025-08-31）

このハブは「運用ルール」「Viewer（Chat/AIクライアント）」「ずんだもんVTuber」の3本を1枚で俯瞰するための入口です。
- 共通方針：**Windows専用で拡充**、25分×マイクロ出荷、Preview→Save の舗装路、必要ならルールを柔軟に更新

## トラック一覧
1) **運用ルール（v020）**
   - Save時に ules_latest.md 先頭へ「保存時刻」を自動追記
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
- PRD（Viewer）: PRD_Viewer_v0.1.md
- PRD（ずんだもん）: PRD_Zundamon_v0.1.md
- リリース手順: Release_Checklist_v020.md
- 収益/拡散: Monetization_Plan_v0.1.md
- リスク: Risks_v0.1.md
- 変更記録（ADR）: ADR/ADR-0001-naming-policy.md, ADR/ADR-0002-governance.md
- 会議テンプレ: TEMPLATES/MEETING_NOTE.md
- バックログ: Backlog_merged.csv
"@;

  (Join-Path C:\Users\hiroy\Desktop\project-root\docs "PRD_Viewer_v0.1.md") = @"
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
- 安定フラグ例：--use-angle=d3d11, --disable-features=DirectComposition

## リリース基準
- 連続1時間の会話テストで停止なし
- README/インストーラ/寄付導線が揃う

