import os

# 保存先のディレクトリを指定
save_directory = r"C:\Users\hiroy\Desktop\project-root\scripts"  # ここに保存先を設定

# 保存するファイル名を指定
file_name = "my_script.py"  # 任意のファイル名

# ファイルに書き込む内容（ここに手書きのコードや内容を書きます）
script_content = """
# これは自動生成されたスクリプトの例です
print("自動で保存されたスクリプト")
"""

# フルパスを作成
full_path = os.path.join(save_directory, file_name)

# 指定した場所にファイルを保存
with open(full_path, 'w') as file:
    file.write(script_content)

print(f"スクリプトが保存されました: {full_path}")
