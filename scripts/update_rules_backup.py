
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
update_rules.py (Futaba edition)
- Append/update rules text safely
- --diff-only: show diff without saving
- On save: write new version docs\rules_vXYZ.md, update docs\rules_latest.md,
           regenerate docs\rules_index.md, refresh docs\introtemplate.md
- Stamp "保存時刻" at the very top of rules_latest.md
"""

import argparse
import datetime as _dt
import io
import os
import re
import sys
from pathlib import Path
from difflib import unified_diff

ROOT = Path(__file__).resolve().parents[1]  # project-root（scripts/ の一つ上）
DOCS = ROOT / "docs"
LOGS = ROOT / "logs"
DOCS.mkdir(parents=True, exist_ok=True)
LOGS.mkdir(parents=True, exist_ok=True)

LATEST = DOCS / "rules_latest.md"
INDEX = DOCS / "rules_index.md"
INTRO = DOCS / "introtemplate.md"

ENC = "utf-8"

def read_text(p: Path) -> str:
    if not p.exists():
        return ""
    return p.read_text(encoding=ENC)

def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    # Normalize line endings to \n
    if "\r\n" in s:
        s = s.replace("\r\n", "\n")
    if not s.endswith("\n"):
        s += "\n"
    p.write_text(s, encoding=ENC)

def current_version() -> int:
    # Version is inferred from files rules_vNNN.md under docs/
    rx = re.compile(r"^rules_v(\d{3,}).md$", re.IGNORECASE)
    max_v = 0
    if DOCS.exists():
        for name in os.listdir(str(DOCS)):
            m = rx.match(name)
            if m:
                try:
                    v = int(m.group(1))
                    if v > max_v:
                        max_v = v
                except ValueError:
                    pass
    return max_v

def next_version() -> int:
    return max(1, current_version() + 1)

def stamp_timestamp_to_latest():
    """rules_latest.md の先頭に保存時刻コメントを付与（既存があれば置換）"""
    if not LATEST.exists():
        return
    content = read_text(LATEST)
    lines = content.splitlines()
    if lines and lines[0].startswith("<!-- 保存時刻:"):
        lines = lines[1:]
    now = _dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    stamped = "\n".join(["<!-- 保存時刻: " + now + " -->"] + lines)
    write_text(LATEST, stamped)

def regenerate_index():
    """docs\rules_index.md をバージョン一覧から再生成"""
    versions = []
    rx = re.compile(r"^rules_v(\d{3,}).md$", re.IGNORECASE)
    for name in sorted(os.listdir(str(DOCS))):
        m = rx.match(name)
        if m:
            versions.append(int(m.group(1)))
    lines = ["# ルール版一覧", "", "| 版 | ファイル |", "|---:|---|"]
    for v in sorted(versions):
        fname = f"rules_v{v:03d}.md"
        lines.append(f"| v{v:03d} | {fname} |")
    write_text(INDEX, "\n".join(lines))

def refresh_introtemplate():
    """docs\introtemplate.md を簡易同期（冒頭に現行版と保存手順のミニガイド）"""
    now = _dt.datetime.now().strftime("%Y-%m-%d")
    ver_label = detect_latest_label()
    text = f"""# 引き継ぎテンプレ（自動更新）
- 現行版: {ver_label}
- 日付: {now}

## 保存フロー
1. Rules-Preview（差分確認）
2. 問題なければ Rules-Save（自動で index/intro も同期）

## 完了コメント（任意）
- コメントは不要です（保存時刻は rules_latest.md の先頭に自動追記されます）
"""
    write_text(INTRO, text)

def detect_latest_label() -> str:
    # Try to detect current label from latest content
    body = read_text(LATEST)
    # Use first non-empty heading line as label
    for line in body.splitlines():
        if line.strip().startswith("#"):
            return line.strip().lstrip("#").strip()
    return "rules_latest.md"

def build_new_content(current: str, summary: str, details: str) -> str:
    # Construct next content: append "details" to current, with a standard header block.
    now = _dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    header_lines = []
    if summary.strip():
        header_lines.append(f"## 更新概要（{now}）")
        header_lines.append(f"- {summary.strip()}")
    new_parts = [current.rstrip()]
    if header_lines:
        new_parts.append("\n".join(header_lines))
    if details.strip():
        new_parts.append(details.strip())
    return "\n\n".join([p for p in new_parts if p]).rstrip() + "\n"

def show_diff(a_text: str, b_text: str):
    a_lines = a_text.splitlines(keepends=True)
    b_lines = b_text.splitlines(keepends=True)
    diff = unified_diff(a_lines, b_lines, fromfile="rules_latest.md (current)", tofile="rules_latest.md (proposed)")
    sys.stdout.writelines(diff)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", default="", help="1行要約（見出しに入ります）")
    ap.add_argument("--details", default="", help="本文（Markdown可、latest末尾に追加）")
    ap.add_argument("--diff-only", action="store_true", help="保存せず差分のみ表示")
    args = ap.parse_args()

    current = read_text(LATEST)
    proposed = build_new_content(current, args.summary, args.details)

    if args.diff-only:
        show_diff(current, proposed)
        return  # no save

    # Determine next version
    v = next_version()
    vfile = DOCS / f"rules_v{v:03d}.md"
    write_text(vfile, proposed)      # 1) 版ファイル
    write_text(LATEST, proposed)     # 2) latest を更新
    stamp_timestamp_to_latest()      # 3) 保存時刻を先頭に追記（多重追記は置換）
    regenerate_index()               # 4) index を再生成
    refresh_introtemplate()          # 5) introtemplate を更新

    print(f"[OK] Saved: {vfile.name}")
    print(f"     Updated: {LATEST.name}, {INDEX.name}, {INTRO.name}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)
