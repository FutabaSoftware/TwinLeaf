# 保存先のパスを指定
file_path = r'C:\Users\hiroy\Desktop\project-root\scripts\check_python_env.py'

# スクリプト内容
script_content = """
import sys
import subprocess
import pkg_resources

# Pythonのバージョンを確認
print(f"Python バージョン: {sys.version}")

# 必要なパッケージ（標準ライブラリにはインストール不要）
required_packages = [
    "os",  # 標準ライブラリなのでインストール不要
    "shutil",  # 標準ライブラリなのでインストール不要
    "logging",  # 標準ライブラリなのでインストール不要
]

# インストール済みのパッケージをチェック
installed_packages = {pkg.key for pkg in pkg_resources.working_set}

# 必要なパッケージがインストールされているか確認
missing_packages = [pkg for pkg in required_packages if pkg not in installed_packages]

if missing_packages:
    print(f"未インストールのパッケージ: {', '.join(missing_packages)}")
    print("\\nこれらのパッケージをインストールしますか？ (y/n)")

    user_input = input().strip().lower()

    if user_input == "y":
        # 未インストールのパッケージをインストール
        for package in missing_packages:
            try:
                result = subprocess.run([sys.executable, "-m", "pip", "install", package], capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"{package} パッケージがインストールされました。")
                else:
                    print(f"エラーが発生しました: {result.stderr}")
            except Exception as e:
                print(f"エラーが発生しました: {e}")
    else:
        print("パッケージのインストールはキャンセルされました。")
else:
    print("すべての必要なパッケージはすでにインストールされています。")

# スクリプト完了後、画面を保持
input("処理が完了しました。Enterキーを押して終了します。")
"""

# スクリプトを保存
with open(file_path, 'w') as file:
    file.write(script_content)

print(f"スクリプトが保存されました: {file_path}")
