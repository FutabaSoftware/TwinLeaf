import os, sys, subprocess, textwrap, pathlib

def p(msg): print(msg, flush=True)
def run(args, check=False):
    p(f"$ {' '.join(args)}"); return subprocess.run(args, text=True, check=check)

# ---- SSOT（単一の出力先） ----
USERPROFILE = os.path.expanduser("~")
PROJECT_ROOT = os.path.join(USERPROFILE, "Desktop", "project-root")
SCRIPTS_DIR  = os.path.join(PROJECT_ROOT, "scripts")
VENV_DIR     = os.path.join(PROJECT_ROOT, "venv")
REQ_FILE     = os.path.join(PROJECT_ROOT, "requirements.txt")
CHECK_PY     = os.path.join(SCRIPTS_DIR, "check_python_env.py")

def ensure_dirs():
    pathlib.Path(PROJECT_ROOT).mkdir(parents=True, exist_ok=True)
    pathlib.Path(SCRIPTS_DIR).mkdir(parents=True, exist_ok=True)
    p(f"[OK] PROJECT_ROOT = {PROJECT_ROOT}")
    p(f"[OK] SCRIPTS_DIR  = {SCRIPTS_DIR}")

def ensure_requirements():
    if not os.path.exists(REQ_FILE):
        tmpl = textwrap.dedent("""\
        # ---- ここに必要な外部ライブラリを1行ずつ書きます ----
        # requests>=2.32.0
        # rich>=13.7.1
        """)
        pathlib.Path(REQ_FILE).write_text(tmpl, encoding="utf-8")
        p(f"[NEW] requirements を作成: {REQ_FILE}")
    else:
        p(f"[OK] requirements を使用: {REQ_FILE}")

def create_venv():
    if not os.path.exists(VENV_DIR):
        p("[I] venv を作成します…")
        run([sys.executable, "-m", "venv", VENV_DIR], check=True)
        p(f"[OK] venv 作成: {VENV_DIR}")
    else:
        p(f"[OK] 既存 venv を使用: {VENV_DIR}")

def venv_bins():
    py  = os.path.join(VENV_DIR, "Scripts", "python.exe")
    return py

def upgrade_pip(py):
    p("[I] pip / wheel / setuptools をアップグレード…")
    run([py, "-m", "pip", "install", "--upgrade", "pip", "wheel", "setuptools"])

def install_requirements(py):
    text = pathlib.Path(REQ_FILE).read_text(encoding="utf-8")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip() and not ln.strip().startswith("#")]
    if not lines:
        p("[I] requirements に有効行が無いのでスキップ（必要なら追記して再実行）")
        return []
    p("[I] requirements をインストールします…")
    res = run([py, "-m", "pip", "install", "-r", REQ_FILE])
    if res.returncode == 0: p("[OK] requirements をインストール完了")
    else: p(f"[WARN] 一部失敗（コード {res.returncode}）")
    return lines

def ensure_check_script():
    if not os.path.exists(CHECK_PY):
        stub = """import sys; print('check_python_env.py stub'); print('Python:', sys.executable)"""
        pathlib.Path(CHECK_PY).write_text(stub, encoding="utf-8")
        p(f"[WARN] {CHECK_PY} が無かったためスタブを生成しました。")

def run_check(py, installed_names):
    ensure_check_script()
    run([py, CHECK_PY] + installed_names)

def show_howto(py):
    act = os.path.join(VENV_DIR, "Scripts", "activate")
    p("\n--- 使い方メモ ------------------------------")
    p(f"1) 仮想環境を有効化  :  {act}")
    p(f"2) 依存を追加する例  :  {py} -m pip install requests rich")
    p(f"3) 依存をロック保存  :  {py} -m pip freeze > {os.path.join(PROJECT_ROOT,'requirements.lock')}")
    p("--------------------------------------------")

def main():
    p(f"Python 実行ファイル: {sys.executable}")
    ensure_dirs()
    ensure_requirements()
    create_venv()
    py = venv_bins()
    upgrade_pip(py)
    installed_names = install_requirements(py)
    p("[I] 環境診断スクリプトを venv の Python で実行します…")
    run_check(py, installed_names)
    show_howto(py)
    input("\n処理が完了しました。Enter キーで終了します。")

if __name__ == "__main__":
    try: main()
    except Exception as e:
        print(f"[ERR] {e}")
        input("Enter で終了")
