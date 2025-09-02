from rich import print
import requests, sys

print("[bold cyan]requests + rich デモ[/bold cyan]")
r = requests.get("https://httpbin.org/get", timeout=10)
print(":sparkles: [green]HTTP[/green] status =", r.status_code)
print("[yellow]UA[/yellow]            =", r.json().get("headers", {}).get("User-Agent"))

# 非対話実行なら即終了、対話なら Enter 待ち
if sys.stdin.isatty():
    input("完了。Enterで閉じます。")
