import sys, subprocess, importlib, textwrap, shutil, os

def p(msg): print(msg, flush=True)

p(f"Python バージョン : {sys.version.split()[0]}  ({sys.executable})")
# pip の用意
try:
    subprocess.run([sys.executable, "-m", "ensurepip", "--upgrade"], check=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    subprocess.run([sys.executable, "-m", "pip", "--version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    p("pip は利用可能です。")
except Exception as e:
    p(f"pip の確認に失敗: {e}")

# === 標準ライブラリの確認（pip不要） ===
stdlib_mods = ["os", "shutil", "logging"]
missing_std = []
for m in stdlib_mods:
    try:
        importlib.import_module(m)
        p(f"[OK] 標準ライブラリ '{m}' は使用可能")
    except Exception as e:
        missing_std.append(m)
        p(f"[WARN] 標準ライブラリ '{m}' の import に失敗: {e}")

# === サードパーティの確認（必要なら pip 対象） ===
# 使い方: python check_python_env.py requests rich  のように追記
third_party = sys.argv[1:]
if third_party:
    p(f"サードパーティ確認対象: {', '.join(third_party)}")
    need_install = []
    for pkg in third_party:
        try:
            importlib.import_module(pkg)
            p(f"[OK] '{pkg}' はインストール済み")
        except Exception:
            need_install.append(pkg)
            p(f"[MISS] '{pkg}' は未インストール")

    if need_install:
        ans = input(f"\n未インストール: {', '.join(need_install)} をインストールしますか？ (y/n) ").strip().lower()
        if ans == "y":
            for pkg in need_install:
                p(f"==> pip install {pkg}")
                proc = subprocess.run([sys.executable, "-m", "pip", "install", pkg], text=True)
                if proc.returncode == 0:
                    p(f"[OK] {pkg} をインストールしました")
                else:
                    p(f"[ERR] {pkg} のインストールに失敗（コード {proc.returncode}）")
        else:
            p("インストールをスキップしました。")
else:
    p("サードパーティ確認対象はありません（引数でパッケージ名を渡せます）。")

# 結果まとめ
p("\n--- 実行結果まとめ ---")
if missing_std:
    p("標準ライブラリで import 失敗: " + ", ".join(missing_std))
else:
    p("標準ライブラリはすべて使用可能。")

input("\n処理が完了しました。Enterキーを押して終了します。")
import sys
if sys.stdin.isatty():
    input("処理が完了しました。Enterキーを押して終了します。")
