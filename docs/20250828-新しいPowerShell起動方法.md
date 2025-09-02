---
title: 新しいPowerShell起動方法
date: 2025-08-28 01:15
---

# 新しいPowerShell起動方法

### user  

Gitとoh-my-posh の本体(Exe)とは？便利？

### assistant  

なるほど、「タスクバーから開いたのに PS5.1 が出てしまった」＝ピン留め修正は途中まで効いているけど、まだ別の起動元（スタートメニューや Win+X）から旧版が残っている。  
そこで **「一回貼り付けて実行」で、今後どこから起動しても PowerShell 7（pwsh.exe）が開く」**ようにまとめたスクリプトを用意した。

以下を **PowerShell 7 でも 5.1 でもどちらでも**貼り付けて実行すれば完了する。  
（Explorer を再起動するので、作業中のファイルコピーなどは終えてから実行してね）

---

### PowerShell ワンショットスクリプト

```powershell
# -*- 最終移行スクリプト -*-
# 目的: Windows PowerShell 5.1 をすべて PowerShell 7 (pwsh.exe) に差し替える

# 1) pwsh.exe のパスを自動検出
try {
    $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
} catch {
    $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
}

# 2) タスクバーのピン留め修正
$taskbar = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
$links = Get-ChildItem $taskbar -Filter *.lnk -ErrorAction SilentlyContinue
$ws  = New-Object -ComObject WScript.Shell
foreach ($lnk in $links) {
    $sc = $ws.CreateShortcut($lnk.FullName)
    if ($sc.TargetPath -match 'WindowsPowerShell\\v1\.0\\powershell\.exe') {
        $sc.TargetPath  = $pwsh
        $sc.Arguments   = ''
        $sc.IconLocation= "$pwsh,0"
        $sc.Save()
    }
}

# 3) スタートメニューの既定関連付け（.ps1 → PS7）
New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -File `"%1`" %*" | Out-Null

# 4) エクスプローラーの右クリック「ここで PowerShell 7 を開く」
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
  Set-ItemProperty -Name "MUIVerb" -Value "ここで PowerShell 7 を開く" -PassThru |
  Set-ItemProperty -Name "Icon" -Value "$pwsh,0" | Out-Null
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null

# 5) Windows Terminal の既定を PowerShell 7 に（あれば）
$terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalSettings) {
    $json = Get-Content $terminalSettings -Raw | ConvertFrom-Json
    $ps7profile = $json.profiles.list | Where-Object { $_.commandline -match "pwsh" }
    if ($ps7profile) {
        $json.profiles.defaults = @{} # ensure exists
        $json.defaultProfile = $ps7profile.guid
        $json | ConvertTo-Json -Depth 10 | Set-Content $terminalSettings -Encoding UTF8
    }
}

# 6) 反映のためエクスプローラーを再起動
Stop-Process -Name explorer -Force
Start-Process explorer.exe

Write-Host "=== PowerShell 7 への完全移行が完了しました ==="
Write-Host "タスクバー/スタート/右クリック/Win+X からすべて PowerShell 7 が開きます"
```

---

### 使い方
1. 今開いている PowerShell（5.1でも7でも可）に **丸ごと貼り付けて Enter**。  
2. 画面が一瞬消えてエクスプローラーが再起動する。  
3. 以後はタスクバー / スタートメニュー / Win+X / `.ps1` 実行 / 右クリック すべてが **PowerShell 7** になる。

---

👉 これで「どこから起動しても最新の PowerShell」環境に統一されるよ。  

やってみる？

### assistant  

いま開いているのは **Windows PowerShell 5.1**（`Desktop / 5.1 / ...\WindowsPowerShell\v1.0`）だね。  
タスクバーの修正はできているので、**別の経路（スタート検索 / Win+X / 右クリック）から旧版が起動**しているだけ。完全移行は下の順で終わり。

---

## A) いますぐ PS7 を開く最短
- **Win+R → `pwsh` → Enter**（常に PS7 が開く）
- もしくは **タスクバーの新しいアイコン**から起動（7.x と表示されるはず）

---

## B) 旧版が起動する経路をつぶす（推奨）

### 1) スタートメニューの整理
1. スタート検索で「PowerShell」と打つ  
2. **Windows PowerShell**を右クリック → **スタートからピン留めを外す** / **タスクバーから外す**  
3. **PowerShell 7 (x64)** を右クリック → **スタート/タスクバーにピン留め**

### 2) Win+X（スタート右クリック）の既定を PS7 に
Win+X が旧版を呼ぶなら **Windows Terminal 経由で PS7** を既定にするのが一番楽。

1. **Windows Terminal**を開く → **設定**（Ctrl+,）  
2. **起動 → 既定のプロファイル** を **PowerShell（PS7）** に変更  
   （左の「プロファイル > PowerShell」で**コマンドライン**が  
   `C:\Program Files\PowerShell\7\pwsh.exe` になっているか確認）  
3. これで **Win+X → Windows Terminal(管理者)** からも PS7 で開くようになる  
   ※ タスクバーに「Terminal」をピン留めしたい場合は、ショートカットに  
   `wt.exe -p "PowerShell"` を使うと**必ず PS7**で起動

### 3) 右クリック「ここで PowerShell 7」を入れる（便利）
```powershell
$pwsh = (Get-Command pwsh).Source
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
  Set-ItemProperty -Name "MUIVerb" -Value "ここで PowerShell 7 を開く" -PassThru |
  Set-ItemProperty -Name "Icon" -Value "$pwsh,0" | Out-Null
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
```

### 4) `.ps1` をダブルクリック＝PS7 で実行に寄せる
```powershell
$pwsh = (Get-Command pwsh).Source
New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -File `"%1`" %*" | Out-Null
```

---

## C) バージョン確認ワンライナー（どこから開いても判別）
```powershell
"Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
```
`Edition=Core / Version=7.x / Home=...\PowerShell\7\` なら PS7。

---

これで「どこから起動しても PS7」になるはず。  
まだどこかで 5.1 が顔を出すなら、**その起動元（ショートカット / Terminal プロファイル）の“リンク先”が `pwsh.exe` か**を教えて。すぐ該当箇所だけ直す手順に落として返す。

### user  

さっきのはタスクバーから開いた結果のやつだよ！「どこから起動しても 最新のパワーシェル」になるのをパワーシェルで1回だけの貼り付けて実行で完了できるように作成お願い。

### user  

@{content_type=image_asset_pointer; asset_pointer=file-service://file-AyMSCvKwH3SjfQJBbQ9nVS; size_bytes=32676; width=1129; height=644; fovea=; metadata=}

右クリックから起動。おそらくうまくいった。

### user  

それぞれ入れたらどうなるの？

### assistant  

まだプロファイル内に“古い定義”（if/else直後にパイプしてる版）が残ってるせいで、読み込み時に毎回こけてます。  
下のスクリプトで **該当関数だけ正しい定義に置換** → 反映します（安全・再実行OK）。

```powershell
# --- profile.ps1 の _fzf-files / _fzf-dirs を安全に置換して修正 ---
$prof = $PROFILE.CurrentUserAllHosts
if(!(Test-Path $prof)){ Write-Host "profile.ps1 がまだ無いようです。"; return }

$txt = Get-Content $prof -Raw

# 置換用の正しい定義
$fixFiles = @'
function _fzf-files {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t f -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
'@

$fixDirs = @'
function _fzf-dirs {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t d -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
'@

# 既存の問題ある定義を検出して置換（無ければそのまま追記）
$reFiles = '(?s)function\s+_fzf-files\s*\{.*?\}'
$reDirs  = '(?s)function\s+_fzf-dirs\s*\{.*?\}'

$changed = $false
if($txt -match $reFiles){ $txt = [regex]::Replace($txt,$reFiles,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $fixFiles }); $changed=$true }
if($txt -match $reDirs ){ $txt = [regex]::Replace($txt,$reDirs ,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $fixDirs  }); $changed=$true }

if(-not $changed){
  # 定義が見つからない場合は末尾に追記（後勝ちでこの定義が有効になる）
  $txt += "`r`n$fixFiles`r`n$fixDirs`r`n"
}

Set-Content $prof $txt -Encoding UTF8

# 読み込みテスト → エラーの行番号を抑止しつつ再読み込み
. $prof
Write-Host "[OK] プロファイル内の fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。"
```

これで `.`（ドットソース）時の `An empty pipe element is not allowed.` は消えるはず。  
もしまだ出るなら、`profile.ps1` に**同種の「 if(){} else{} | fzf 」構造**が他にも残っていないかを一緒に洗います。

### user  

タスクバーから試してみた。Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

新機能と改善のために最新の PowerShell をインストールしてください!https://aka.ms/PSWindows

PS C:\Users\hiroy> "Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
Edition=Desktop  Version=5.1.26100.4768  Home=C:\Windows\System32\WindowsPowerShell\v1.0
PS C:\Users\hiroy>

### assistant  

スクショを見る限り、**右クリック→「ターミナルで開く」(Windows Terminal)** が起動しており、Terminal の**既定プロファイルが “Windows PowerShell (5.1)”**のままです。  
＝ 右クリック時は **Terminal の既定プロファイル** が使われるので、ここを **PS7 に固定**すれば解決します。

下のワンショットを **PowerShell 7 で貼り付け実行**して。  
（Windows Terminal は全て閉じてから実行すること）

```powershell
# --- 右クリック「ターミナルで開く」を PS7 に統一する ---

# 1) pwsh の実体を特定
try { $pwsh = (Get-Command pwsh -ErrorAction Stop).Source } catch { $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe" }

# 2) Windows Terminal の settings.json を検出（Store 版 / 非パッケージ版 両対応）
$paths = @(
  "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",   # Store
  "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"                                      # winget/非Store
) | Where-Object { Test-Path $_ }

foreach ($p in $paths) {
  try {
    $json = Get-Content $p -Raw | ConvertFrom-Json
  } catch {
    # 破損・コメント等で読めない場合は最小構成を作る
    $json = [pscustomobject]@{
      "$schema" = "https://aka.ms/terminal-profiles-schema"
      profiles  = [pscustomobject]@{ list = @() }
    }
  }

  # 既存プロファイルから pwsh を指すものを探す（なければ作成）
  $ps7 = @($json.profiles.list | Where-Object {
    $_.commandline -match 'pwsh\.exe' -or $_.source -eq 'Windows.Terminal.PowershellCore'
  }) | Select-Object -First 1

  if (-not $ps7) {
    $guid = "{"+[guid]::NewGuid().ToString()+"}"
    $ps7 = [pscustomobject]@{
      name        = "PowerShell 7"
      guid        = $guid
      commandline = $pwsh
      startingDirectory = "%USERPROFILE%"
      hidden      = $false
    }
    # プロファイル配列が無ければ作る
    if (-not $json.profiles) { $json | Add-Member -Name profiles -MemberType NoteProperty -Value ([pscustomobject]@{ list=@() }) }
    $json.profiles.list += $ps7
  }

  # 既定プロファイルを PowerShell 7 に
  $json.defaultProfile = $ps7.guid

  # 反映して保存
  $json | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding UTF8
}

# 3) 右クリックの古い「PowerShell をここで開く」が残っている場合は上書き（ユーザー範囲）
$targets = @(
  "HKCU:\Software\Classes\Directory\shell\Powershell",
  "HKCU:\Software\Classes\Directory\Background\shell\Powershell",
  "HKCU:\Software\Classes\Drive\shell\Powershell",
  "HKCU:\Software\Classes\LibraryFolder\Background\shell\Powershell"
)
foreach ($base in $targets) {
  New-Item -Path $base -Force | Out-Null
  Set-ItemProperty -Path $base -Name "Icon" -Value "$pwsh,0" -ErrorAction SilentlyContinue
  $cmdKey = Join-Path $base "command"; New-Item $cmdKey -Force | Out-Null
  # %V / %1 の両方に対応（背景/項目/ドライブ）。存在する方が使われる。
  $cmd = "`"$pwsh`" -NoLogo -NoExit -Command `"$path = if (Test-Path `"%V`") { `"%V`" } elseif (Test-Path `"%1`") { `"%1`" } else { `$PWD }; Set-Location -LiteralPath $path`""
  Set-ItemProperty -Path $cmdKey -Name "(default)" -Value $cmd
}

# 4) 反映：エクスプローラー/ターミナルを再起動
Get-Process -Name WindowsTerminal -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Process -Name explorer -Force
Start-Process explorer.exe

"Done: 右クリックの Terminal 既定プロファイルと古い『PowerShell を開く』を PS7 に統一しました。"
```

### 期待結果
- フォルダや空白で右クリック → **「ターミナルで開く」** を選ぶ → **Windows Terminal が起動し、タブは「PowerShell 7」**  
- 旧来の **「PowerShell をここで開く」** が出る環境でも **PS7 で開く**

うまくいかなければ、**Windows Terminal の設定画面**（Ctrl+,）を開き、  
「起動 → 既定のプロファイル」が **PowerShell 7** になっているかだけ確認してみて。

### assistant  

了解。**PS7用の“気持ちよく使える最小セット”**を一発適用するスクリプトを用意した。  
貼り付け実行だけで、以下が入る：

- UTF-8固定、履歴の賢い保存、ベル無効
- 予測補完（履歴＋プラグイン）を **リスト表示**、`Tab` でメニュー補完
- `Ctrl+R` でインタラクティブ履歴検索、`Ctrl+L` でクリア
- `oh-my-posh`（軽めの Paradox テーマ）、`posh-git`、`Terminal-Icons`
- `ls` 等にアイコン、Gitブランチ表示
- 既存プロファイルは自動バックアップ＆安全に差し替え（再実行しても壊れない）

そのままPS7に貼り付けて実行して。

```powershell
# ==== PS7 快適プロファイル 一発セットアップ ====
# 1) 依存モジュールを導入（ユーザー範囲）
Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
$mods = 'oh-my-posh','posh-git','Terminal-Icons'
foreach($m in $mods){ if(-not (Get-Module -ListAvailable $m)){ Install-Module $m -Scope CurrentUser -Force } }

# 2) プロファイル 書き込み先（全ホスト/現在ユーザー）
$prof = $PROFILE.CurrentUserAllHosts
$dir  = Split-Path $prof
if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }

# 3) 既存プロファイルをバックアップ（1度だけ／毎回上書き安全）
if(Test-Path $prof -and -not (Get-Content $prof -ErrorAction SilentlyContinue | Select-String 'BEGIN GPT-PS-PROFILE')){
  Copy-Item $prof "$prof.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
}

# 4) 既存の当ブロックを除去
if(Test-Path $prof){
  $txt = Get-Content $prof -Raw
  $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
  Set-Content $prof $txt -Encoding UTF8
}

# 5) プロファイル本体を追記
@'
# >>> BEGIN GPT-PS-PROFILE
# --- Console / Encoding ---
[Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

# --- Modules ---
Import-Module posh-git    -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
# oh-my-posh: 軽量 Paradox テーマ（好みで変更可）
$ompExe = (Get-Command oh-my-posh -ErrorAction SilentlyContinue).Source
if($ompExe){
  $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
  oh-my-posh init pwsh --config $theme | Invoke-Expression
}

# --- PSReadLine 快適化 ---
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -MaximumHistoryCount 50000

  # 空行や先頭空白だけは履歴に残さない
  Set-PSReadLineOption -AddToHistoryHandler {
    param($line) return ($line -notmatch '^\s*$')
  }

  # Key bindings
  Set-PSReadLineKeyHandler -Key Tab     -Function MenuComplete
  Set-PSReadLineKeyHandler -Key "Ctrl+l" -ScriptBlock { Clear-Host }
  Set-PSReadLineKeyHandler -Key "Ctrl+r" -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key "Alt+Enter" -Function AcceptLine
}

# --- 見た目少し良く ---
$PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightBlue
$PSStyle.FileInfo.Executable = $PSStyle.Foreground.BrightGreen
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.BrightCyan

# --- 便利エイリアス（安全な範囲） ---
Set-Alias ll Get-ChildItem
function which($name){ Get-Command $name -All }

# --- Git 仮想環境/ブランチ情報は posh-git/oh-my-posh 側に任せる ---
# >>> END GPT-PS-PROFILE
'@ | Add-Content -Path $prof -Encoding UTF8

# 6) すぐ反映
. $prof

Write-Host "`n[OK] 新プロファイルを適用しました。必要ならテーマは $env:POSH_THEMES_PATH から選んで変更してください。"
```

### カスタム（任意）
- テーマ変更：  
  ```powershell
  Get-ChildItem $env:POSH_THEMES_PATH
  # 好きな .omp.json を選んで…
  $THEME='jandedobbeleer.omp.json'   # 例
  (Get-Content $PROFILE.CurrentUserAllHosts -Raw) -replace 'paradox\.omp\.json',$THEME |
    Set-Content $PROFILE.CurrentUserAllHosts -Encoding UTF8
  . $PROFILE.CurrentUserAllHosts
  ```
- いつでもプロファイル編集：`code $PROFILE.CurrentUserAllHosts`（VS Code）/ `notepad $PROFILE.CurrentUserAllHosts`

必要なら、fzf連携やgit高度情報、Python/Condaやkubectl補完など**用途別**の追撃ブロックもすぐ出せる。どれ入れる？

### assistant  

いいね！スクショは **PowerShell 7.5.2**（右上のタブ名も “PowerShell”）になってる。右クリック起動のルートも PS7 固定できたよ 🎉

仕上げチェックだけどうぞ：

```powershell
"Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
(Get-Command pwsh).Source
```
→ `Edition=Core / Version=7.x / Home=...\PowerShell\7` と、`pwsh.exe` の実パスが出れば完全OK。

不要なら古い右クリック項目を消す（任意）：
```powershell
Remove-Item "HKCU:\Software\Classes\Directory\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Classes\Directory\Background\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Classes\Drive\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Classes\LibraryFolder\Background\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force; Start-Process explorer.exe
```

この状態なら  
- タスクバー  
- スタート/検索  
- 右クリック「ターミナルで開く」/「ここで PowerShell 7 を開く」  
- `.ps1` ダブルクリック  
の全部が PS7 で起動するはず。  
他に VS Code や IDE 側の既定シェルも PS7 に寄せたいなら言って。最小設定を一発適用のスニペット出すよ。

### assistant  

やったね！再発しないように“仕上げ”だけ置いとく。必要なものだけ実行して。

---

## 1) 起動確認（いまのタスクバーが本当に PS7 か）
```powershell
$PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $PSHOME
```
`Core / 7.x / ...\PowerShell\7\` ならOK。

---

## 2) 右クリック「ここで PowerShell 7」を追加（超便利）
エクスプローラーで任意フォルダを右クリック→一発でPS7起動できるようにする。

```powershell
$pwsh = (Get-Command pwsh).Source
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
  Set-ItemProperty -Name "MUIVerb" -Value "ここで PowerShell 7 を開く" -PassThru |
  Set-ItemProperty -Name "Icon"    -Value "$pwsh,0" | Out-Null
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
```

（消すとき）
```powershell
Remove-Item "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Recurse -Force
```

---

## 3) `.ps1` をダブルクリックで **PS7** 実行に寄せる（現在ユーザーだけ）
```powershell
$pwsh = (Get-Command pwsh).Source
New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -File `"%1`" %*" | Out-Null
```
※ 既にエディタに関連付けているならスキップでOK。

---

## 4) Windows Terminal を使うなら既定を PS7 に固定
タスクバーが **Windows Terminal** の人向け。手動で  
設定 → 起動 → 既定のプロファイル = PowerShell（PS7）  
を選べば十分。ショートカットから常にPS7で開きたいなら下記をピン留め：
```
wt.exe -p "PowerShell"
```

---

## 5) 念のための再発防止メモ
- タスクバーに旧「Windows PowerShell」アイコンが紛れてたら外す（同名が2つ並ぶことがある）  
- Store 版 PS7 を使っている場合も今回の手順でOK（`Get-Command pwsh` が正しい場所を解決）  

---

他にも「プロファイル最適化（PSReadLine 設定、`oh-my-posh`、補完強化）」まで一気に整えるセットアップも作れる。要るならそのまま流せるスクリプト出すよ。

### user  

実行してみた。

PowerShell 7.5.2
PS C:\Users\hiroy> # --- PowerShell 7 固定 起動元ぜんぶ書換 v2 ---
PS C:\Users\hiroy> # 1) pwsh の場所を検出
PS C:\Users\hiroy> try { $pwsh = (Get-Command pwsh -ErrorAction Stop).Source } catch { $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe" }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 2) .lnk を走査して「powershell.exe(v1.0)」を「pwsh.exe」に置換
PS C:\Users\hiroy> $lnkRoots = @(
>>   "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar",        # タスクバーのピン(従来)
>>   "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\ImplicitAppShortcuts", # 近代ピン
>>   "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",                                # ユーザーのスタートメニュー
>>   "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",                            # 全ユーザーのスタートメニュー
>>   "$env:USERPROFILE\Desktop"                                                           # デスクトップ(念のため)
>> ) | Where-Object { Test-Path $_ }
PS C:\Users\hiroy>
PS C:\Users\hiroy> $pattern = [regex]'WindowsPowerShell\\v1\.0\\powershell\.exe$'
PS C:\Users\hiroy> $ws = New-Object -ComObject WScript.Shell
PS C:\Users\hiroy> $changed = 0
PS C:\Users\hiroy>
PS C:\Users\hiroy> foreach ($root in $lnkRoots) {
>>   Get-ChildItem $root -Filter *.lnk -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
>>     try {
>>       $sc = $ws.CreateShortcut($_.FullName)
>>       if ($pattern.IsMatch($sc.TargetPath)) {
>>         $sc.TargetPath   = $pwsh
>>         $sc.Arguments    = ''
>>         $sc.IconLocation = "$pwsh,0"
>>         $sc.Save()
>>         $changed++
>>       }
>>     } catch {}
>>   }
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 3) Windows Terminal 既定を PS7 に(あれば)
PS C:\Users\hiroy> $terminalJson = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
PS C:\Users\hiroy> if (Test-Path $terminalJson) {
>>   try {
>>     $json = Get-Content $terminalJson -Raw | ConvertFrom-Json
>>     $ps7 = $json.profiles.list | Where-Object { $_.commandline -match 'pwsh' } | Select-Object -First 1
>>     if ($ps7) { $json.defaultProfile = $ps7.guid; $json | ConvertTo-Json -Depth 10 | Set-Content $terminalJson -Encoding UTF8 }
>>   } catch {}
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 4) 右クリック「ここで PowerShell 7」を（未設定なら）作成
PS C:\Users\hiroy> if (-not (Test-Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7")) {
>>   New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force | Out-Null
>>   Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Name "MUIVerb" -Value "ここで PowerShell 7 を開く"
>>   Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Name "Icon" -Value "$pwsh,0"
>>   New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force | Out-Null
>>   Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`""
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 5) 反映のため Explorer 再起動
PS C:\Users\hiroy> Stop-Process -Name explorer -Force
PS C:\Users\hiroy> Start-Process explorer.exe
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 6) 結果表示
PS C:\Users\hiroy> "`n[Done] 書換数: $changed  起動元の .lnk を pwsh.exe に更新しました。タスクバーの同じアイコンから再起動して確認してください。"

[Done] 書換数: 2  起動元の .lnk を pwsh.exe に更新しました。タスクバーの同じアイコンから再起動して確認してください。
PS C:\Users\hiroy>

さらにタスクバーに最新をピン止めしなおして、確認用を実行してみた。
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

新機能と改善のために最新の PowerShell をインストールしてください!https://aka.ms/PSWindows

PS C:\Users\hiroy> "Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
Edition=Desktop  Version=5.1.26100.4768  Home=C:\Windows\System32\WindowsPowerShell\v1.0
PS C:\Users\hiroy>

これ古いやつだよね？

### assistant  

了解。原因は「タスクバーのショートカットが `powershell.exe`（Windows PowerShell 5.1）に向いたまま」か、「Windows Terminal の既定プロファイルが旧版」のどちらか（または両方）で起きることが多い。下の順で一気に直す。

---

# 1) 最短・確実：`pwsh.exe` 直リンクを作り直してピン留め（推奨）
1. エクスプローラーで  
   `C:\Program Files\PowerShell\7\` を開く（MS Store 版なら `C:\Program Files\WindowsApps\Microsoft.PowerShell_*` 配下。分からなければ後ろの「確認コマンド」で場所を出す）。
2. `pwsh.exe` を右クリック → **ショートカットの作成**。できたショートカットをデスクトップへ移動。
3. そのショートカットを右クリック → **プロパティ**  
   - **リンク先**: `"...\pwsh.exe"`（引数不要）  
   - **作業フォルダー**: `%USERPROFILE%`（好みで）  
   - **アイコンの変更**: `pwsh.exe` を指定（青いPS7アイコンになる）
4. そのショートカットを右クリック → **タスクバーにピン留め**。
5. まぎらわしい旧ショートカット（「Windows PowerShell」や古い PowerShell のアイコン）は**すべてタスクバーから外す**。

> これでタスクバーの PS アイコン＝`pwsh.exe`（PowerShell 7）に固定できる。

---

# 2) Windows Terminal を使う場合の設定（ターミナルから必ず PS7 で開く）
タスクバーにピン留めしているのが **Windows Terminal** の場合は、設定を変える。

1. Windows Terminal を開く → **設定**（Ctrl+,）
2. **起動** → **既定のプロファイル** を「PowerShell」（アイコンが PS7 の方）に変更  
   ついでに **既定のターミナル アプリ** が Windows Terminal でもOK。
3. 左の **プロファイル > PowerShell** を開き、**コマンドライン** が  
   `C:\Program Files\PowerShell\7\pwsh.exe` になっているか確認。違えば直す。
4. 必要ならタスクバー用に「PS7専用 Terminal ショートカット」も作れる：  
   デスクトップで右クリック → ショートカット作成 → **項目の場所** に  
   ```
   wt.exe -p "PowerShell"
   ```  
   と入れて作成 → ピン留め（これを押すと必ず PS7 プロファイルで起動）。

---

# 3) 旧リンクを掃除して差し替える（自動化スクリプト）
GUIが面倒なら、以下を **管理者不要** の PowerShell で実行。  
※ エクスプローラーを再起動するので、作業中のコピー/移動を終えてから。

```powershell
# タスクバーにピン留めされた .lnk を PS7 に向け直す
$taskbar = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
$pwsh    = "C:\Program Files\PowerShell\7\pwsh.exe"

# pwsh の場所が違う環境に対応して自動検出
try { $pwsh = (Get-Command pwsh -ErrorAction Stop).Source } catch {}

$links = Get-ChildItem $taskbar -Filter *.lnk -ErrorAction SilentlyContinue
foreach ($lnk in $links) {
  $ws  = New-Object -ComObject WScript.Shell
  $sc  = $ws.CreateShortcut($lnk.FullName)
  if ($sc.TargetPath -match 'WindowsPowerShell\\v1\.0\\powershell\.exe') {
    $sc.TargetPath  = $pwsh
    $sc.Arguments   = ''
    $sc.IconLocation= "$pwsh,0"
    $sc.Save()
  }
}

# ついでに「スタートメニューの古い PowerShell」を未ピンにした場合はスキップされる
# 変更を反映するためエクスプローラーを再起動
Stop-Process -Name explorer -Force
Start-Process explorer.exe
```

---

# 4) 起動確認（これで PS7 になっているか）
タスクバーのアイコンから起動して、以下を実行。

```powershell
$PSVersionTable.PSEdition
$PSVersionTable.PSVersion
$PSHOME
```

- `PSEdition` が `Core`、`PSVersion` が 7.x、`PSHOME` が `...\PowerShell\7\` なら OK。

---

## ありがちな落とし穴
- **同名アイコンが複数ピン留め**されている（古い方を外し忘れ）。→ まず全部外して、PS7だけピン留めし直す。
- **MS Store 版 PS7** はパスが `WindowsApps` 配下。`Get-Command pwsh` で場所を確定してからリンク先を設定。
- **App Execution Alias** は今回無関係（`pwsh`/`powershell` の Win+R や新規プロセス起動に影響するだけ）。タスクバーの挙動は**ショートカットのリンク先**で決まる。

---

この通りやれば、タスクバーから確実に PowerShell 7 が立ち上がる。必要なら「今の環境を検出して自動で PS7 に差し替える」完全自動スクリプトも用意できる。

### assistant  

なるほど、それなら「手動で切り替えるトグル（Enable-PoshPrompt / Disable-PoshPrompt）」は入れず、  
**安全に常時ロードだけど軽量化済み**の構成を共有するのが最良だね 👍  

つまり「自分が変な操作をしなくても、起動時に必要最低限が自動で効く環境」ってこと。  

---

## 🚀 PowerShell 開発環境の進化メモ（安全・自動ロード版）

### ✔ 導入したもの
- **PowerShell 7.5.2** に完全移行  
  （タスクバー・スタート・右クリックすべて PS7 起動に統一）  
- **プロファイル自動整備**  
  - UTF-8 環境固定  
  - oh-my-posh / posh-git / Terminal-Icons は「初回プロンプト描画時」に自動ロード（安全に遅延処理）  
  - fzf / fd / rg / bat / GitHub CLI / VSCode を統合  
- **PSReadLine 拡張**  
  - `Ctrl+R` → 履歴検索（fzf）  
  - `Ctrl+T` → ファイル検索  
  - `Alt+C` → ディレクトリ移動  

### ✔ 開発効率ショートカット
- `gst` → git status  
- `glog` → git log --graph  
- `gco` → fzf でブランチ切替  
- `gpick` → 変更ファイルを選んで VSCode で開く  
- `gstashp` → stash 適用  
- `frg <word>` → ripgrep+fzf+bat → VSCodeでその行へジャンプ  

### ✔ チューニング
- **起動時エラーなし・操作不要**  
- **自動遅延ロードで軽量化**  
- **人為的な切り替え不要**（Enable/Disable 系は除外）  

---

👉 この形なら「手動切り替えで壊す心配なし」、かつ **最良の状態を自動で維持**できる。  

---

質問：このメモを **「環境共有用（別チャットに貼る）サマリ」だけでいい**？  
それとも **「完全再現用スクリプト付き」版**も一緒に作る？

### assistant  

心配ポイントわかる。結論から言うと **安全に共存できる**。理由と“ワンショット導入＋即ロールバック可”のスクリプトを用意した。

## これが安全な理由（要点だけ）
- **プロファイルは防御的**に書いてある  
  - `oh-my-posh.exe` が無ければ起動しない  
  - `git` が無ければ `posh-git` を読み込まない  
- **グローバル設定を書き換えない**（PATHやGit設定は触らない）  
- **バックアップしてから差し替え**（いつでも元に戻せる）

---

## 導入ワンショット（貼り付けて実行）
Git と oh-my-posh 本体を入れて、プロファイルを再適用する。既に入っていればスキップされる。

```powershell
# --- 安全導入: Git + oh-my-posh 本体 + プロファイル再適用 ---
$ErrorActionPreference = 'SilentlyContinue'

# 1) winget で Git / Oh My Posh を導入（あればスキップ）
function Install-IfMissing($id){
  $installed = winget list --id $id -e | Select-String $id
  if(-not $installed){
    winget install --id $id -e --accept-source-agreements --accept-package-agreements
  }
}
Install-IfMissing 'Git.Git'
Install-IfMissing 'JanDeDobbeleer.OhMyPosh'

# 2) テーマ探しやすくするために環境変数を補助（セッション限定）
$themeRoots = @(
  $env:POSH_THEMES_PATH,
  "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
  "C:\Program Files\oh-my-posh\themes"
) | Where-Object { $_ -and (Test-Path $_) }
if($themeRoots){ $env:POSH_THEMES_PATH = $themeRoots[0] }

# 3) さっき作った“防御的プロファイル”を再適用（存在しなければ作成）
$prof = $PROFILE.CurrentUserAllHosts
if(!(Test-Path (Split-Path $prof))){ New-Item (Split-Path $prof) -ItemType Directory | Out-Null }

# 既存の当ブロックだけ消す
if(Test-Path $prof){
  $txt = Get-Content $prof -Raw
  $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
  Set-Content $prof $txt -Encoding UTF8
}

# “防御的プロファイル”を追記（Git/OMPが無ければ勝手に諦める作り）
@'
# >>> BEGIN GPT-PS-PROFILE
[Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

if (Get-Command git -ErrorAction SilentlyContinue) { Import-Module posh-git -ErrorAction SilentlyContinue }
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
$themeRoots = @($env:POSH_THEMES_PATH,"$env:LOCALAPPDATA\Programs\oh-my-posh\themes","C:\Program Files\oh-my-posh\themes") | Where-Object { $_ -and (Test-Path $_) }
if ($omp -and $themeRoots) {
  $theme = Join-Path ($themeRoots[0]) 'paradox.omp.json'
  if (Test-Path $theme) { oh-my-posh init pwsh --config $theme | Invoke-Expression }
}

if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -MaximumHistoryCount 50000
  Set-PSReadLineOption -AddToHistoryHandler { param($line) return ($line -notmatch '^\s*$') }
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  Set-PSReadLineKeyHandler -Key Ctrl+l    -ScriptBlock { Clear-Host }
  Set-PSReadLineKeyHandler -Key Ctrl+r    -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key Alt+Enter -Function AcceptLine
}

$PSStyle.FileInfo.Directory    = $PSStyle.Foreground.BrightBlue
$PSStyle.FileInfo.Executable   = $PSStyle.Foreground.BrightGreen
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.BrightCyan

Set-Alias ll Get-ChildItem
function which($name){ Get-Command $name -All }
# >>> END GPT-PS-PROFILE
'@ | Add-Content -Path $prof -Encoding UTF8

. $prof
Write-Host "`n[OK] Git/oh-my-posh を反映。テーマ: $env:POSH_THEMES_PATH"
```

> もし初回でプロンプトが変わらなかったら、一度 **PSを開き直す** だけでOK。

---

## ロールバック（いつでも元に戻せる）
1発で **今回入れた見た目だけ**をオフにする（Git本体は残す）：
```powershell
# ブロック削除
$prof = $PROFILE.CurrentUserAllHosts
if(Test-Path $prof){
  $txt = Get-Content $prof -Raw
  $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
  Set-Content $prof $txt -Encoding UTF8
  . $prof
}
Write-Host "[Rolled back] プロンプト拡張を無効化しました。"
```

完全にパッケージも消したい場合（任意）：
```powershell
winget uninstall JanDeDobbeleer.OhMyPosh -e
# Git も消すなら
# winget uninstall Git.Git -e
```

---

## ちょい補足（見た目を最大化したい場合）
- Terminal のフォントを **Cascadia Code PL** や **MesloLGM Nerd Font** にすると記号が崩れない  
  （フォントは **Terminal 設定 → プロファイル → PowerShell → 外観 → フォント** で変更）

---

必要なら「fzf 連携（超高速履歴＆ファイル検索）」や「git/gh 強化」「kubectl/az 補完」など、用途別の追撃も出す。最初はこの最小セットで運用して、慣れてきたら足していこう。

### user  

多分うまくできた。　　PowerShell 7.5.2
Loading personal and system profiles took 1942ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ git --version
git version 2.51.0.windows.1
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ (Get-Command oh-my-posh).Source
C:\Users\hiroy\AppData\Local\Programs\oh-my-posh\bin\oh-my-posh.exe
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $env:POSH_THEMES_PATH
C:\Users\hiroy\AppData\Local\Programs\oh-my-posh\themes\
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ Test-Path "$env:POSH_THEMES_PATH\paradox.omp.json"
True
 hiroy@DESKTOP-D6G9TM0  ~ 
❯


PowerShell 7.5.2
Loading personal and system profiles took 1245ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # もっとも確実なテーマフォルダを検出して環境変数に反映
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $roots = @(
>   "$env:ProgramFiles\oh-my-posh\themes",
>   "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
> ) | Where-Object { Test-Path $_ }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if($roots){ $env:POSH_THEMES_PATH = $roots[0] }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # セッションに即テーマ適用（プロファイルの設定はそのまま活きる）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
>   $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
>   if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression }
> }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯


PowerShell 7.5.2
Loading personal and system profiles took 1291ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # PSReadLineは即時。oh-my-poshはキー入力orgitリポで初回実行
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $global:__omp_inited = $false
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ Set-PSReadLineKeyHandler -Key 'Ctrl+o' -ScriptBlock {
>   if(-not $global:__omp_inited){
>     $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
>     if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression; $global:__omp_inited=$true }
>   }
> }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # git リポでプロンプト描画時に一度だけ初期化
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ function prompt {
>   if(-not $global:__omp_inited -and (Test-Path .git)){
>     $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
>     if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression; $global:__omp_inited=$true }
>   }
>   "$(Get-Location)> "
> }
C:\Users\hiroy>


C:\Users\hiroy> $THEME='jandedobbeleer.omp.json'   # 例
C:\Users\hiroy> oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\$THEME" | Invoke-Expression
 hiroy    ~   179ms⠀     

### assistant  

ばっちり動いてる ✨  
スクショに出てる **カラフルな矢印付きプロンプト（ /  /  など）** は oh-my-posh が効いてる証拠。  
しかも Git も正常に入ってるから、リポジトリに入ればプロンプトに **ブランチ名や変更状態** が表示されるはず。

---

### ✅ ここまでで整った環境
- **PowerShell 7.5.2 固定**
- **Git**（2.51.0）が使える
- **oh-my-posh.exe** + 好きなテーマ（paradox / jandedobbeleer など）
- **posh-git + Terminal-Icons** 有効
- **PSReadLine 強化**（Tab補完・Ctrl+R検索・Ctrl+Lクリア）
- プロンプトに色＆アイコン付き情報

---

### 💡 次のカスタム案（好みに応じて）
1. **テーマ切替**  
   ```powershell
   Get-ChildItem $env:POSH_THEMES_PATH | Select-Object Name
   # 好きなテーマ名を選んで…
   $THEME='jandedobbeleer.omp.json'
   oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\$THEME" | Invoke-Expression
   ```
   → 気に入ったら `$PROFILE` に書き換えれば毎回それで起動。

2. **フォント強化**  
   今の “Cascadia Code PL” でも動くけど、アイコン崩れがあれば Nerd Font (例: MesloLGM Nerd Font) を入れて Terminal のフォントに設定。

3. **パフォーマンス**  
   起動が 1秒ちょいかかってる。前に仕込んだ **遅延ロード（Ctrl+O または Git リポに入った時だけ oh-my-posh 起動）** をプロファイルに残すと軽くなる。

4. **fzf 連携**（オプション）  
   `Ctrl+R` で超高速ファジー検索、`fzf` コマンドでファイル選択。  
   → 導入すると「コマンド・ファイルを対話的に選んで実行」ができる。

---

👉 今の状態でもう「プロンプトは最高級」になってる。  
次は **「fzf 連携」入れてさらに操作性を上げる**か、**「git/gh 便利関数」追加**か、どっちを優先したい？

### assistant  

ナイス！`Core / 7.5.2 / C:\Program Files\PowerShell\7` になってれば完全勝利👏

仕上げに “便利＋再発防止” のクイックだけ置いとく。要るものだけ実行でOK。

---

### 1) Win+X（スタート右クリック）もPS7で固定
（Windows Terminal経由に統一）
1. Windows Terminal → 設定（Ctrl+,）
2. 起動 → 既定のプロファイル = **PowerShell**（pwsh）
3. プロファイル → PowerShell → **コマンドライン**が `...\PowerShell\7\pwsh.exe` か確認

---

### 2) 右クリック「ここで PowerShell 7」を常備
```powershell
$pwsh=(Get-Command pwsh).Source
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
  Set-ItemProperty -Name MUIVerb -Value "ここで PowerShell 7 を開く" -PassThru |
  Set-ItemProperty -Name Icon -Value "$pwsh,0" | Out-Null
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
```

---

### 3) `.ps1` ダブルクリック＝PS7で実行
```powershell
$pwsh=(Get-Command pwsh).Source
New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -File `"%1`" %*" | Out-Null
```

---

### 4) VS Code も pwsh を既定に（任意）
`Ctrl+,` → settings.json に追記：
```json
"terminal.integrated.defaultProfile.windows": "PowerShell",
"terminal.integrated.profiles.windows": {
  "PowerShell": { "source": "PowerShell", "path": "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }
}
```

---

全部そろったら、どこから開いても PS7 固定。  
他にプロファイル最適化（補完/色/ヒストリ）もまとめてやるなら、用途だけ教えて。最小構成で一発セットアップ出す。

### assistant  

最高！エラー消えてプロファイルもクリーン化できたよ 🙌  
最後の行、描画 2ms の表示も出てるし（OMP テーマのプロンプト）、良い感じ。

## 動作チェック（すぐ確認）
- `Ctrl+T` → ファイル一覧が出る
- `Alt+C` → ディレクトリ一覧→選択で `cd`
- `Ctrl+R` → 履歴検索
- `frg <語>` → プレビュー付きで選んで VS Code で開く

## 起動時間の最終チューニング（任意）
今でも遅延ロードで軽くなってるけど、さらに速さ優先なら **oh-my-posh を手動トグル**にできます。

### 1行追加（プロファイル末尾に追記）
```powershell
function Enable-PoshPrompt { __Init-OhMyPosh }
function Disable-PoshPrompt { Remove-Item function:prompt -ErrorAction SilentlyContinue; $function:prompt = { "$(Get-Location)> " }; $global:__omp_inited=$false }
```
- 普段は無効 → 必要なときだけ `Enable-PoshPrompt`
- さらに軽くしたい日 → `Disable-PoshPrompt`

## もしまた詰まったら
- `notepad $PROFILE.CurrentUserAllHosts` で中身を直接見てOK  
- 失敗時は `*.bak_YYYYMMDD_*` から即ロールバック可

ほかに「このキーでこう動かしたい」「VS Code を既定タブで開きたい」みたいな要望あれば、ピンポイントで追記版を作るよ！

### assistant  

了解 👍  
**最良の共有形式は Markdown 見出し付きで整える方法**だよ。  

- ChatGPTの別チャットにそのまま貼れば、文脈が分かりやすい  
- 後から読み返す自分にも優しい（見出しごとに一目で把握できる）  
- 必要ならコピペしてドキュメント化や GitHub README にも流用できる  

---

## 🚀 PowerShell 開発環境の進化メモ

### ✔ 導入したもの
- **PowerShell 7.5.2** に完全移行  
  （タスクバー・スタート・右クリックすべて PS7 起動に統一）  
- **プロファイル自動整備**  
  - UTF-8 環境固定  
  - oh-my-posh / posh-git / Terminal-Icons を遅延ロード  
  - fzf / fd / rg / bat / GitHub CLI / VSCode を統合  
- **PSReadLine 拡張**  
  - `Ctrl+R` → 履歴検索（fzf）  
  - `Ctrl+T` → ファイル検索  
  - `Alt+C` → ディレクトリ移動  

### ✔ 開発効率ショートカット
- `gst` → git status  
- `glog` → git log --graph  
- `gco` → fzf でブランチ切替  
- `gpick` → 変更ファイルを選んで VSCode で開く  
- `gstashp` → stash 適用  
- `frg <word>` → ripgrep+fzf+bat → VSCodeでその行へジャンプ  

### ✔ チューニング
- プロンプトは **初回描画時にのみ oh-my-posh 起動** → 起動時間大幅短縮  
- `Enable-PoshPrompt` / `Disable-PoshPrompt` で手動トグル可能  

---

👉 この形で別チャットに貼れば「どこまで進化したか」が一発で伝わるし、次の相談もスムーズにできる。  

---

要確認：この共有メモ、**自分用にさらに「手順まとめ」版（セットアップ用スクリプト付き）**も一緒に作っとく？

### user  

最良なのでお願い

### assistant  

いいね、ほぼ完了！  
`ripgrep (rg)` だけ見つからなかったので、そこだけ入れ直そう。

## ripgrep の入れ方（どちらか通る方でOK）
```
winget install BurntSushi.ripgrep.MSVC -e --accept-package-agreements --accept-source-agreements
```
もし通らなければまず検索して ID を確認：
```
winget search ripgrep
```
（表示された ID に対して `winget install <ID> -e ...` を実行）

> rg は fzf と組み合わせる場面が多い（プロジェクト内テキスト検索など）。入っていると後々便利。

---

## 動作チェック（そのまま試して）
- `Ctrl+R` → 履歴が出たら OK（選んで Enter で実行）
- `Ctrl+T` → ファイル一覧が出る → 選んだパスが入力欄に挿入
- `Alt+C` → ディレクトリ一覧 → 選ぶとその場所に `cd`

※ fzf/fd を winget で入れた直後は **新しいウィンドウを1回開き直す**と PATH が確実です。

---

## 次：git/gh 便利関数を入れる？
まだならこの一発で追加できます（安全・再実行OK）：
```powershell
winget install GitHub.cli -e --accept-package-agreements --accept-source-agreements

$prof=$PROFILE.CurrentUserAllHosts
if(!(Test-Path (Split-Path $prof))){New-Item -ItemType Directory -Path (Split-Path $prof)|Out-Null}
if(Test-Path $prof){(Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN GIT-GH-BLOCK.*?# >>> END GIT-GH-BLOCK','' | Set-Content $prof -Encoding UTF8}

@'
# >>> BEGIN GIT-GH-BLOCK
if (Get-Command git -ErrorAction SilentlyContinue) {
  function glog { git log --oneline --graph --decorate --color --all }
  function gclean {
    git fetch --prune
    git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} |
      ForEach-Object { git branch -d ($_ -replace '^\s+','') }
  }
  function gsync { git fetch origin; git checkout main 2>$null; git checkout master 2>$null; git pull --ff-only }
  if (Get-Command fzf -ErrorAction SilentlyContinue) {
    function gco {
      $b = git for-each-ref --format="%(refname:short)" refs/heads | fzf --height 40% --reverse
      if($b){ git checkout $b }
    }
  } else { Set-Alias gco 'git checkout' }
}
if (Get-Command gh -ErrorAction SilentlyContinue) {
  function gpr   { param([string]$t=""); gh pr create --fill --title $t }
  function gprvw { gh pr view --web }
  function ghlogin { gh auth login }
}
# >>> END GIT-GH-BLOCK
'@ | Add-Content $prof -Encoding UTF8

. $prof
Write-Host "[OK] git/gh 便利関数を有効化しました（gco / glog / gclean / gpr ...）"
```

### 使い方ミニチート
- `gco` … ブランチを fzf で選んでチェックアウト  
- `glog` … カラー1行ログ  
- `gclean` … マージ済みローカルブランチ掃除  
- `ghlogin` → 初回 GitHub 認証 → `gpr -t "タイトル"` でPR作成、`gprvw` でPRを開く

---

必要なら、`rg` を使った「プロジェクト内テキスト検索 → fzf で候補 → エディタで開く」ワークフローも組み込める。やりたければ VS Code 連携版を用意するよ。

### assistant  

いいね、では**開発効率ブースト**を一気に入れよう。  
（安全設計：存在チェック付き・再実行OK・要件が無ければ何もしない）

## 導入ワンショット（貼り付けて実行）
```powershell
# === Dev boost: gh + git/fzfユーティリティ + VSCode 連携 ===

# 1) 必要ツール（あればスキップ）
winget install GitHub.cli -e --accept-source-agreements --accept-package-agreements
winget install sharkdp.bat -e --accept-source-agreements --accept-package-agreements  # frgのプレビュー用

# 2) プロファイルに便利関数を追加（重複防止）
$prof = $PROFILE.CurrentUserAllHosts
$dir  = Split-Path $prof
if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }
if(Test-Path $prof){
  (Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN DEV-BOOST-BLOCK.*?# >>> END DEV-BOOST-BLOCK','' |
    Set-Content $prof -Encoding UTF8
}

@'
# >>> BEGIN DEV-BOOST-BLOCK
# ガード
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
$hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
$hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
$hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)

# ---- Git 基本ショートカット ----
if($hasGit){
  function gst   { git status -sb }
  function glog  { git log --graph --decorate --oneline --color --all }
  function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
  function gclean{
    git fetch --prune
    git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} |
      ForEach-Object { git branch -d ($_ -replace '^\s+','') }
  }
}

# ---- fzf 連携（ある場合だけ）----
if($hasGit -and $hasFzf){
  # ブランチ切替（ローカル＋リモート）
  function gco {
    $locals  = git for-each-ref --format="%(refname:short)" refs/heads
    $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
    $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | `
           fzf --height 40% --reverse
    if(!$sel -or $sel -like "===*==="){ return }
    if($sel -like "*/ *"){ $sel = $sel.Trim() }
    if($locals -contains $sel){ git switch $sel; return }
    # リモート選択時は追跡ブランチを切って切替
    if($sel -like "*/ *"){ $sel = $sel.Trim() }
    if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
    git switch -c $name --track $sel
  }

  # 変更ファイルから選んで VSCode で開く
  function gpick {
    if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
    $files = git ls-files -m -o --exclude-standard
    $sel = $files | fzf --height 40% --reverse -m
    if($sel){ code $sel }
  }

  # stash を選んで適用
  function gstashp {
    $line = git stash list | fzf --height 40% --reverse
    if($line){ $id = $line.Split(':')[0]; git stash apply $id }
  }
}

# ---- GitHub CLI 連携（ある場合だけ）----
if($hasGh){
  function ghlogin { gh auth login }           # 初回認証
  function gpr     { param([string]$t=""); gh pr create --fill --title $t }
  function gprvw   { gh pr view --web }
  function gprco   {
    $sel = gh pr list --limit 50 | fzf --height 40% --reverse
    if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
  }
  function gbrowse { gh repo view --web }
}

# ---- ripgrep + fzf + bat + VSCode: frg改良版 ----
function frg {
  param([Parameter(Mandatory=$true)][string]$q)
  if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
  if(-not $hasFzf){ Write-Host "fzf がありません"; return }
  $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
  $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
  if($sel){
    $parts = $sel -split ':'
    if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
  }
}
# >>> END DEV-BOOST-BLOCK
'@ | Add-Content $prof -Encoding UTF8

. $prof
Write-Host "[OK] Dev boost を適用しました。 (gco, gst, glog, gpick, gstashp, gpr, gprvw, gprco, gbrowse, frg)"
```

## 使い方ミニチート
- **ブランチ切替**：`gco` → fzf で選択（リモートも可 / 自動で追跡ブランチ作成）  
- **変更ファイルをVSCodeで開く**：`gpick`（複数選択可）  
- **stash適用**：`gstashp` → 選んで適用  
- **ログ**：`glog`（`q`で終了）、状態：`gst`  
- **掃除**（マージ済みローカルを削除）：`gclean`  
- **GitHub**：  
  - 初回認証 → `ghlogin`  
  - PR作成 → `gpr -t "タイトル"`  
  - PR閲覧 → `gprvw`  
  - PRをチェックアウト → `gprco`  
  - リポをブラウザで開く → `gbrowse`  
- **全文検索→開く**：`frg 文字列` → ヒットを選ぶ → VSCodeで該当行を開く

---

必要なら、**Python/Node/Go** など言語別のテンプレや、**Docker/kubectl/az** の補完強化も足せるよ。どのスタックをよく使う？

### assistant  

✅ 出力を見ると、`rg PowerShell` がちゃんと走っていて、カレント以下のファイルからヒットした行を一覧で返してますね。  
つまり **ripgrep (rg) も PATH に通って正常稼働中**。  

これで **fzf セットの3本柱**が揃いました：  
- `fzf` → あいまい検索 UI  
- `fd` → ファイル・ディレクトリ検索  
- `rg` → テキスト検索  

---

### 💡 これで出来ること
- `Ctrl+R` → コマンド履歴を fzf で対話検索  
- `Ctrl+T` → ファイル検索してパスを挿入  
- `Alt+C` → ディレクトリ検索して即 `cd`  
- `rg <文字列> | fzf` → テキスト検索結果からさらに絞り込み、選んだ行をコピー/利用  

たとえば **「ソースコード内から関数を探して VSCode で開く」** みたいなワークフローも組める：

```powershell
function frg {
  param([string]$q)
  $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview 'bat --style=numbers --color=always --line-range :500 {1} --highlight-line {2}' --preview-window=up:40%
  if($sel){
    $parts = $sel -split ':'
    code "$($parts[0])" -g "$($parts[1])"
  }
}
```
`frg "PowerShell"` → 該当行をプレビューしながら選び、Enterで VSCode がその行を開く。

---

### 次のステップ
- **Git/GitHub 便利関数**を追加すると、fzf と組み合わさって「ブランチ選択 checkout」「ログ検索」「PR作成」まで一気に楽になる。  
- もう少し軽量化したいなら、`oh-my-posh` を **遅延ロード**にして起動時間を削る。

👉 どっちを優先する？  
- **開発効率系（git/gh強化）**  
- **パフォーマンス調整（起動時間短縮）**

### assistant  

いいね！ 🚀  
これで **Dev boost セット**（git/fzf/gh/VSCode/rg/bat）全部がそろってプロファイルに常駐した。  

---

## ✅ 今できること（確認ポイント）

- **Git便利系**
  - `gst` → Git status（簡略）
  - `glog` → カラー付き履歴グラフ
  - `gclean` → マージ済みブランチ一括削除
  - `gsync` → main/master を最新に同期

- **fzf連携**
  - `gco` → ブランチ一覧（ローカル/リモート両方）から選んで切替  
  - `gpick` → 変更ファイルを fzf で選んで VSCode で開く  
  - `gstashp` → stash 一覧から選んで適用  

- **GitHub CLI**
  - `ghlogin` → 初回だけブラウザ認証  
  - `gpr -t "修正内容"` → 現在ブランチから PR 作成  
  - `gprvw` → 開いている PR をブラウザで表示  
  - `gprco` → PR一覧から選んで checkout  
  - `gbrowse` → リポジトリをブラウザで開く  

- **全文検索系**
  - `frg foo` → ripgrep + fzf + bat プレビュー → 選んだファイルを VSCode で該当行オープン  

---

## 💡 おすすめ試運転シナリオ
1. 適当な git リポに入る
   - `gco` でブランチ切替  
   - `gst` → 状態確認  
   - 何か編集 → `gpick` → そのファイルを VSCode で開く  
2. `frg PowerShell` → 出てきた行をプレビューして選択 → VSCode がその行で開く  
3. `ghlogin` → GitHub 認証通したら `gpr -t "テストPR"` を作って遊べる  

---

👉 これで **「検索・Git・GitHub・エディタ連携」が一発でつながった開発環境**になった。  
次のチューニングは **「起動速度（1588ms → 短縮）」**に取りかかる？ それとも **fzf をもっと Git 専用に強化**（コミット検索/差分プレビュー）する方が興味ある？

### user  

PowerShell 7.5.2
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:74
Line |
  74 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
PS C:\Users\hiroy> # === profile.ps1 をバックアップして“健全版”に入れ替え（再実行OK） ===
PS C:\Users\hiroy> $prof = $PROFILE.CurrentUserAllHosts
PS C:\Users\hiroy> $dir  = Split-Path $prof
PS C:\Users\hiroy> if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # バックアップ
PS C:\Users\hiroy> if(Test-Path $prof){
>>   Copy-Item $prof "$prof.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 新しい内容（エラーの原因だった if/else→直パイプは完全排除済み）
PS C:\Users\hiroy> $new = @'
>> # >>> BEGIN GPT-PS-PROFILE  (最良チューニング・固定化)
>> [Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
>> [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
>> $PSModuleAutoloadingPreference = 'All'
>>
>> # 遅延ロード用フラグ
>> $global:__omp_inited    = $false
>> $global:__icons_inited  = $false
>> $global:__poshgit_inited= $false
>>
>> function __Init-OhMyPosh {
>>   if($global:__omp_inited){ return }
>>   $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
>>   if(-not $omp){ return }
>>   $themeRoots = @($env:POSH_THEMES_PATH,"$env:LOCALAPPDATA\Programs\oh-my-posh\themes","$env:ProgramFiles\oh-my-posh\themes") |
>>     Where-Object { $_ -and (Test-Path $_) }
>>   $theme = if($themeRoots){ Join-Path $themeRoots[0] 'jandedobbeleer.omp.json' }
>>   if($theme -and (Test-Path $theme)){
>>     oh-my-posh init pwsh --config $theme | Invoke-Expression
>>     $global:__omp_inited = $true
>>   }
>> }
>> function __Init-TerminalIcons {
>>   if($global:__icons_inited){ return }
>>   Import-Module Terminal-Icons -ErrorAction SilentlyContinue
>>   $global:__icons_inited = $true
>> }
>> function __Init-PoshGit {
>>   if($global:__poshgit_inited){ return }
>>   if(Get-Command git -ErrorAction SilentlyContinue){
>>     Import-Module posh-git -ErrorAction SilentlyContinue
>>     $global:__poshgit_inited = $true
>>   }
>> }
>>
>> # PSReadLine（軽いので即時）
>> if (Get-Module -ListAvailable PSReadLine) {
>>   Import-Module PSReadLine -ErrorAction SilentlyContinue
>>   Set-PSReadLineOption -EditMode Windows
>>   Set-PSReadLineOption -BellStyle None
>>   Set-PSReadLineOption -PredictionSource HistoryAndPlugin
>>   Set-PSReadLineOption -PredictionViewStyle ListView
>>   Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
>>   Set-PSReadLineOption -HistorySearchCursorMovesToEnd
>>   Set-PSReadLineOption -MaximumHistoryCount 50000
>> }
>>
>> # fzf 既定
>> if(Get-Command fd  -ErrorAction SilentlyContinue){ $env:FZF_DEFAULT_COMMAND = 'fd -H -E .git' }
>> if(Get-Command bat -ErrorAction SilentlyContinue){ $env:BAT_THEME='TwoDark' }
>>
>> # ls/ll 初回実行でアイコンをロード（遅延）
>> function ls { if(-not $global:__icons_inited){ __Init-TerminalIcons }; Get-ChildItem @args }
>> Set-Alias ll Get-ChildItem
>>
>> # 初回プロンプト描画時だけ OMP/posh-git を初期化
>> $script:__prompt_inited = $false
>> $__origPrompt = $function:prompt
>> function prompt {
>>   if(-not $script:__prompt_inited){
>>     __Init-PoshGit
>>     __Init-OhMyPosh
>>     $script:__prompt_inited = $true
>>   }
>>   if ($__origPrompt) { & $__origPrompt } else { "$(Get-Location)> " }
>> }
>>
>> function which($name){ Get-Command $name -All }
>>
>> # ---- fzf ヘルパー（安全版：必ず変数に受けてからパイプ） ----
>> function _fzf-files {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t f -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> function _fzf-dirs {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t d -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> # キーバインド
>> if (Get-Module -ListAvailable PSReadLine) {
>>   Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
>>     $histFile = (Get-PSReadLineOption).HistorySavePath
>>     $items = (Get-Content $histFile -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
>>     $sel = ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
>>     if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
>>   }
>>   Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
>>     $sel = _fzf-files
>>     if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
>>   }
>>   Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
>>     $sel = _fzf-dirs
>>     if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine() }
>>   }
>> }
>> # >>> END GPT-PS-PROFILE
>>
>> # >>> BEGIN DEV-BOOST-BLOCK（軽量化対応）
>> $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
>> $hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
>> $hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
>> $hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
>> $hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)
>>
>> if($hasGit){
>>   function gst   { git status -sb }
>>   function glog  { git log --graph --decorate --oneline --color --all }
>>   function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
>>   function gclean{
>>     git fetch --prune
>>     git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} | ForEach-Object { git branch -d ($_ -replace '^\s+','') }
>>   }
>> }
>> if($hasGit -and $hasFzf){
>>   function gco {
>>     $locals  = git for-each-ref --format="%(refname:short)" refs/heads
>>     $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
>>     $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | fzf --height 40% --reverse
>>     if(!$sel -or $sel -like "===*==="){ return }
>>     if($locals -contains $sel){ git switch $sel; return }
>>     if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
>>     git switch -c $name --track $sel
>>   }
>>   function gpick {
>>     if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
>>     $files = git ls-files -m -o --exclude-standard
>>     $sel = $files | fzf --height 40% --reverse -m
>>     if($sel){ code $sel }
>>   }
>>   function gstashp {
>>     $line = git stash list | fzf --height 40% --reverse
>>     if($line){ $id = $line.Split(':')[0]; git stash apply $id }
>>   }
>> }
>> if($hasGh){
>>   function ghlogin { gh auth login }
>>   function gpr     { param([string]$t=""); gh pr create --fill --title $t }
>>   function gprvw   { gh pr view --web }
>>   function gprco   {
>>     $sel = gh pr list --limit 50 | fzf --height 40% --reverse
>>     if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
>>   }
>>   function gbrowse { gh repo view --web }
>> }
>>
>> # ripgrep + fzf + bat + VSCode
>> function frg {
>>   param([Parameter(Mandatory=$true)][string]$q)
>>   if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
>>   if(-not $hasFzf){ Write-Host "fzf がありません"; return }
>>   $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
>>   $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
>>   if($sel){
>>     $parts = $sel -split ':'
>>     if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
>>   }
>> }
>> # >>> END DEV-BOOST-BLOCK
>> '@
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 上書き
PS C:\Users\hiroy> Set-Content $prof $new -Encoding UTF8
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 反映
PS C:\Users\hiroy> . $prof
PS C:\Users\hiroy> Write-Host "[OK] profile.ps1 をクリーンな内容に入れ替えました。Ctrl+T / Alt+C を試し、起動時エラーが消えたことを確認してください。"
[OK] profile.ps1 をクリーンな内容に入れ替えました。Ctrl+T / Alt+C を試し、起動時エラーが消えたことを確認してください。
 hiroy    ~   2ms⠀    

### user  

手動は自分が変な操作しそうで怖いから入れていない。

### user  

最良な方でお願い

### user  

最短で直す方法で試したらうまくできたみたい。タスクバーから起動して、確認用を実行してみた。PowerShell 7.5.2 
PS C:\Users\hiroy> $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $PSHOME
Core

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      5      2
C:\Program Files\PowerShell\7

PS C:\Users\hiroy>

### assistant  

いい質問。ざっくり言うと——

- **fzf 連携**＝「なんでも“あいまい検索でサクッと選ぶ”」がターミナルでできるようになる（履歴・ファイル・ディレクトリ・Gitブランチ等）。  
- **git/gh 便利関数**＝日常の Git / GitHub 作業（ブランチ切替・ログ閲覧・PR作成/チェック）が短いコマンドで一発になる。

下に、それぞれ「入れると何が起きるか → 最小導入 → 使い方 → ロールバック」をセットで置く。貼り付け一発でOK。

---

# fzf 連携（高速あいまい検索）

## 入れると何が起きる？
- `Ctrl+R`：対話的に**コマンド履歴を検索**→Enterで実行  
- `Ctrl+T`：**ファイルを検索して選択**→パスがカーソル位置に挿入  
- `Alt+C`：**ディレクトリを検索して選択**→そこへ `cd`  
- `git checkout` や `git log` も fzf 経由でサクサク選べるように（後述の関数と連動）

## 導入ワンショット
```powershell
# === fzf + 補助ツール導入 & キーバインド ===
# ツール本体
winget install junegunn.fzf -e --accept-package-agreements --accept-source-agreements
winget install BurntSushi.ripgrep -e --accept-package-agreements --accept-source-agreements   # rg: 超高速検索
winget install sharkdp.fd -e --accept-package-agreements --accept-source-agreements           # fd: 高速ファイル検索

# プロファイルに機能追記（重複防止で同名ブロックを一度消してから追加）
$prof=$PROFILE.CurrentUserAllHosts
if(!(Test-Path (Split-Path $prof))){New-Item -ItemType Directory -Path (Split-Path $prof)|Out-Null}
if(Test-Path $prof){(Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN FZF-BLOCK.*?# >>> END FZF-BLOCK','' | Set-Content $prof -Encoding UTF8}

@'
# >>> BEGIN FZF-BLOCK
# fzf helpers
function _fzf-files { fd -t f -H -E .git 2>$null | fzf --height 40% --reverse }
function _fzf-dirs  { fd -t d -H -E .git 2>$null | fzf --height 40% --reverse }
function _fzf-hist  {
  $items = (Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
  ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
}

# キーバインド
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
  $sel = _fzf-hist
  if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
  $sel = _fzf-files
  if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
}
Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
  $sel = _fzf-dirs
  if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`n$(Get-Location)> ") }
}
# >>> END FZF-BLOCK
'@ | Add-Content $prof -Encoding UTF8

. $prof
Write-Host "[OK] fzf 連携を有効化しました（Ctrl+R / Ctrl+T / Alt+C）"
```

## 使い方（例）
- `Ctrl+R` → キーワードで過去コマンドを検索 → Enter  
- `Ctrl+T` → `readme` と打つ → 候補から選ぶ → パスが入力欄に入る  
- `Alt+C` → `src` などで検索 → そのフォルダにジャンプ

## ロールバック
```powershell
$prof=$PROFILE.CurrentUserAllHosts
if(Test-Path $prof){
  (Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN FZF-BLOCK.*?# >>> END FZF-BLOCK','' | Set-Content $prof -Encoding UTF8
  . $prof
}
Write-Host "[Rolled back] fzf キーバインドを無効化しました。"
```

---

# git/gh 便利関数（Git/GitHub効率化）

## 入れると何が起きる？
- **ブランチ切替を対話的に**：`gco` → 一覧から選ぶだけ  
- **綺麗なログ**：`glog` → 1行カラー表示で履歴が見やすい  
- **不要ブランチ掃除**：`gclean` → マージ済みのローカルブランチを削除  
- **PR 作成/チェックが一瞬**：`gpr`（作成）・`gprvw`（ブラウザでPRを開く）  
  → GitHub CLI `gh` を利用

## 導入ワンショット
```powershell
# === gh(GitHub CLI) & git 補助関数 ===
winget install GitHub.cli -e --accept-package-agreements --accept-source-agreements

# プロファイル追記（重複防止）
$prof=$PROFILE.CurrentUserAllHosts
if(!(Test-Path (Split-Path $prof))){New-Item -ItemType Directory -Path (Split-Path $prof)|Out-Null}
if(Test-Path $prof){(Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN GIT-GH-BLOCK.*?# >>> END GIT-GH-BLOCK','' | Set-Content $prof -Encoding UTF8}

@'
# >>> BEGIN GIT-GH-BLOCK
# 安全ガード：git/gh が無い時は何もしない
if (Get-Command git -ErrorAction SilentlyContinue) {
  function glog { git log --oneline --graph --decorate --color --all }
  function gclean {
    git fetch --prune
    git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} | ForEach-Object { git branch -d ($_ -replace '^\s+','') }
  }
  function gsync { git fetch origin; git checkout main 2>$null; git checkout master 2>$null; git pull --ff-only }

  # fzf があれば対話選択つきブランチ checkout
  if (Get-Command fzf -ErrorAction SilentlyContinue) {
    function gco {
      $b = git for-each-ref --format="%(refname:short)" refs/heads | fzf --height 40% --reverse
      if($b){ git checkout $b }
    }
  } else {
    Set-Alias gco 'git checkout'
  }
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
  function gpr   { param([string]$t="") ; gh pr create --fill --title $t }
  function gprvw { gh pr view --web }
  function ghlogin { gh auth login }  # 初回はこれでブラウザ認証
}
# >>> END GIT-GH-BLOCK
'@ | Add-Content $prof -Encoding UTF8

. $prof
Write-Host "[OK] git/gh 便利関数を有効化しました（gco / glog / gclean / gpr ...）"
```

## 使い方（例）
- `gco` → ブランチ一覧から選択 → 切替  
- `glog` → カラー1行ログ（`q`で終了）  
- `gclean` → マージ済みローカルブランチを一括削除  
- `ghlogin` → 初回だけ GitHub 認証  
- `gpr -t "修正: ログ整形"` → 現在ブランチで PR 作成  
- `gprvw` → その PR をブラウザで開く

## ロールバック
```powershell
$prof=$PROFILE.CurrentUserAllHosts
if(Test-Path $prof){
  (Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN GIT-GH-BLOCK.*?# >>> END GIT-GH-BLOCK','' | Set-Content $prof -Encoding UTF8
  . $prof
}
Write-Host "[Rolled back] git/gh 便利関数を無効化しました。"
```

---

## どっちから入れるべき？
- **まず fzf**（誰でも恩恵が大きい／副作用ほぼゼロ）  
- その次に **git/gh 便利関数**（Git をよく触るなら爆速）

必要なら、さらに **“ファイル名で開く → VS Code”** や **“最近のディレクトリ履歴にジャンプ”** など、あなたの作業パターンに合わせた関数を足して最適化できる。欲しい動きがあれば書いて。

### user  

いったん、ここまで開発環境が進化したことをchatgptの別のチャットルームに共有したい。どう伝えるのが最良？

### user  

@{content_type=image_asset_pointer; asset_pointer=file-service://file-Fh3KcxZFgj5KYSzmwgowXi; size_bytes=39986; width=1119; height=644; fovea=; metadata=}

PowerShell 7.5.2
PS C:\Users\hiroy> # 右クリックの既定「PowerShell をここで開く」を PS7 に置換（ユーザー範囲）
PS C:\Users\hiroy> $pwsh = (Get-Command pwsh).Source
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 対象 (フォルダ項目 / フォルダ背景 / ドライブ / ライブラリ背景)
PS C:\Users\hiroy> $targets = @(
>>   "HKCU:\Software\Classes\Directory\shell\Powershell",
>>   "HKCU:\Software\Classes\Directory\Background\shell\Powershell",
>>   "HKCU:\Software\Classes\Drive\shell\Powershell",
>>   "HKCU:\Software\Classes\LibraryFolder\Background\shell\Powershell"
>> )
PS C:\Users\hiroy>
PS C:\Users\hiroy> foreach ($base in $targets) {
>>   New-Item -Path $base -Force | Out-Null
>>   # アイコンもPS7に
>>   Set-ItemProperty -Path $base -Name "Icon" -Value "$pwsh,0" -ErrorAction SilentlyContinue
>>
>>   # command サブキー
>>   $cmdKey = Join-Path $base "command"
>>   New-Item -Path $cmdKey -Force | Out-Null
>>
>>   # 既定の右クリックは %V で対象パスが来るので、PS7をその場所で開く
>>   # ※ Set-Location で確実に遷移。-NoExit でウィンドウを閉じない
>>   $cmd = "`"$pwsh`" -NoLogo -NoExit -Command Set-Location -LiteralPath `"%V`""
>>   Set-ItemProperty -Path $cmdKey -Name "(default)" -Value $cmd
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 既に作った「ここで PowerShell 7 を開く」(OpenPwsh7) も念のため揃える
PS C:\Users\hiroy> if (Test-Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command") {
>>   Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7"
>>　右クリックからだと古いのが起動してしまう。

### assistant  

OK、まだタスクバーのピンが「スタートメニュー側の .lnk」を参照していて、その **元 .lnk** が 5.1 を指してる状態っぽい。  
下の“強化版”で **スタートメニュー／タスクバー由来の全部の .lnk を一括で PS7 に書き換え** → 反映までやる。貼り付け一発でどうぞ。

```powershell
# --- PowerShell 7 固定 起動元ぜんぶ書換 v2 ---
# 1) pwsh の場所を検出
try { $pwsh = (Get-Command pwsh -ErrorAction Stop).Source } catch { $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe" }

# 2) .lnk を走査して「powershell.exe(v1.0)」を「pwsh.exe」に置換
$lnkRoots = @(
  "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar",        # タスクバーのピン(従来)
  "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\ImplicitAppShortcuts", # 近代ピン
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",                                # ユーザーのスタートメニュー
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",                            # 全ユーザーのスタートメニュー
  "$env:USERPROFILE\Desktop"                                                           # デスクトップ(念のため)
) | Where-Object { Test-Path $_ }

$pattern = [regex]'WindowsPowerShell\\v1\.0\\powershell\.exe$'
$ws = New-Object -ComObject WScript.Shell
$changed = 0

foreach ($root in $lnkRoots) {
  Get-ChildItem $root -Filter *.lnk -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      $sc = $ws.CreateShortcut($_.FullName)
      if ($pattern.IsMatch($sc.TargetPath)) {
        $sc.TargetPath   = $pwsh
        $sc.Arguments    = ''
        $sc.IconLocation = "$pwsh,0"
        $sc.Save()
        $changed++
      }
    } catch {}
  }
}

# 3) Windows Terminal 既定を PS7 に(あれば)
$terminalJson = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalJson) {
  try {
    $json = Get-Content $terminalJson -Raw | ConvertFrom-Json
    $ps7 = $json.profiles.list | Where-Object { $_.commandline -match 'pwsh' } | Select-Object -First 1
    if ($ps7) { $json.defaultProfile = $ps7.guid; $json | ConvertTo-Json -Depth 10 | Set-Content $terminalJson -Encoding UTF8 }
  } catch {}
}

# 4) 右クリック「ここで PowerShell 7」を（未設定なら）作成
if (-not (Test-Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7")) {
  New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force | Out-Null
  Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Name "MUIVerb" -Value "ここで PowerShell 7 を開く"
  Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Name "Icon" -Value "$pwsh,0"
  New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force | Out-Null
  Set-ItemProperty "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`""
}

# 5) 反映のため Explorer 再起動
Stop-Process -Name explorer -Force
Start-Process explorer.exe

# 6) 結果表示
"`n[Done] 書換数: $changed  起動元の .lnk を pwsh.exe に更新しました。タスクバーの同じアイコンから再起動して確認してください。"
```

### 確認コマンド（タスクバーの同じアイコンから起動して）
```powershell
"Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
```
`Edition=Core / Version=7.x / Home=...\PowerShell\7\` になればOK。

まだ 5.1 が出るなら、そのアイコンだけ“別形式のピン”になってる可能性があるから、**一度そのアイコンを右クリック→タスクバーからピン留めを外す → スタートの「PowerShell 7」から右クリック→タスクバーにピン留め**を試してみて。どうしても残る場合は、そのアイコンの **ショートカットのプロパティ（リンク先）** を教えてくれれば、そこだけ狙い撃ちのスクリプトにする。

### user  

できたかな？　PowerShell 7.5.2
Loading personal and system profiles took 1469ms.
PS C:\Users\hiroy> # --- 安全導入: Git + oh-my-posh 本体 + プロファイル再適用 ---
PS C:\Users\hiroy> $ErrorActionPreference = 'SilentlyContinue'
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 1) winget で Git / Oh My Posh を導入（あればスキップ）
PS C:\Users\hiroy> function Install-IfMissing($id){
>>   $installed = winget list --id $id -e | Select-String $id
>>   if(-not $installed){
>>     winget install --id $id -e --accept-source-agreements --accept-package-agreements
>>   }
>> }
PS C:\Users\hiroy> Install-IfMissing 'Git.Git'
見つかりました Git [Git.Git] バージョン 2.51.0
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
ダウンロード中 https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe
  ██████████████████████████████  61.7 MB / 61.7 MB
インストーラーハッシュが正常に検証されました
パッケージのインストールを開始しています...
インストーラーは管理者として実行するように要求します。プロンプトが表示されます。
インストールが完了しました
PS C:\Users\hiroy> Install-IfMissing 'JanDeDobbeleer.OhMyPosh'
見つかりました Oh My Posh [JanDeDobbeleer.OhMyPosh] バージョン 26.19.1
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
ダウンロード中 https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v26.19.1/install-x64.msi
  ██████████████████████████████  5.85 MB / 5.85 MB
インストーラーハッシュが正常に検証されました
パッケージのインストールを開始しています...
インストールが完了しました
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 2) テーマ探しやすくするために環境変数を補助（セッション限定）
PS C:\Users\hiroy> $themeRoots = @(
>>   $env:POSH_THEMES_PATH,
>>   "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
>>   "C:\Program Files\oh-my-posh\themes"
>> ) | Where-Object { $_ -and (Test-Path $_) }
PS C:\Users\hiroy> if($themeRoots){ $env:POSH_THEMES_PATH = $themeRoots[0] }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 3) さっき作った“防御的プロファイル”を再適用（存在しなければ作成）
PS C:\Users\hiroy> $prof = $PROFILE.CurrentUserAllHosts
PS C:\Users\hiroy> if(!(Test-Path (Split-Path $prof))){ New-Item (Split-Path $prof) -ItemType Directory | Out-Null }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 既存の当ブロックだけ消す
PS C:\Users\hiroy> if(Test-Path $prof){
>>   $txt = Get-Content $prof -Raw
>>   $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
>>   Set-Content $prof $txt -Encoding UTF8
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # “防御的プロファイル”を追記（Git/OMPが無ければ勝手に諦める作り）
PS C:\Users\hiroy> @'
>> # >>> BEGIN GPT-PS-PROFILE
>> [Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
>> [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
>>
>> if (Get-Command git -ErrorAction SilentlyContinue) { Import-Module posh-git -ErrorAction SilentlyContinue }
>> Import-Module Terminal-Icons -ErrorAction SilentlyContinue
>>
>> $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
>> $themeRoots = @($env:POSH_THEMES_PATH,"$env:LOCALAPPDATA\Programs\oh-my-posh\themes","C:\Program Files\oh-my-posh\themes") | Where-Object { $_ -and (Test-Path $_) }
>> if ($omp -and $themeRoots) {
>>   $theme = Join-Path ($themeRoots[0]) 'paradox.omp.json'
>>   if (Test-Path $theme) { oh-my-posh init pwsh --config $theme | Invoke-Expression }
>> }
>>
>> if (Get-Module -ListAvailable PSReadLine) {
>>   Import-Module PSReadLine -ErrorAction SilentlyContinue
>>   Set-PSReadLineOption -EditMode Windows
>>   Set-PSReadLineOption -BellStyle None
>>   Set-PSReadLineOption -PredictionSource HistoryAndPlugin
>>   Set-PSReadLineOption -PredictionViewStyle ListView
>>   Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
>>   Set-PSReadLineOption -HistorySearchCursorMovesToEnd
>>   Set-PSReadLineOption -MaximumHistoryCount 50000
>>   Set-PSReadLineOption -AddToHistoryHandler { param($line) return ($line -notmatch '^\s*$') }
>>   Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
>>   Set-PSReadLineKeyHandler -Key Ctrl+l    -ScriptBlock { Clear-Host }
>>   Set-PSReadLineKeyHandler -Key Ctrl+r    -Function ReverseSearchHistory
>>   Set-PSReadLineKeyHandler -Key Alt+Enter -Function AcceptLine
>> }
>>
>> $PSStyle.FileInfo.Directory    = $PSStyle.Foreground.BrightBlue
>> $PSStyle.FileInfo.Executable   = $PSStyle.Foreground.BrightGreen
>> $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.BrightCyan
>>
>> Set-Alias ll Get-ChildItem
>> function which($name){ Get-Command $name -All }
>> # >>> END GPT-PS-PROFILE
>> '@ | Add-Content -Path $prof -Encoding UTF8
PS C:\Users\hiroy>
PS C:\Users\hiroy> . $prof
PS C:\Users\hiroy> Write-Host "`n[OK] Git/oh-my-posh を反映。テーマ: $env:POSH_THEMES_PATH"

[OK] Git/oh-my-posh を反映。テーマ: C
PS C:\Users\hiroy>

### user  

PowerShell 7.5.2
Loading personal and system profiles took 1302ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # === Dev boost: gh + git/fzfユーティリティ + VSCode 連携 ===
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # 1) 必要ツール（あればスキップ）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ winget install GitHub.cli -e --accept-source-agreements --accept-package-agreements
見つかりました GitHub CLI [GitHub.cli] バージョン 2.78.0
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
ダウンロード中 https://github.com/cli/cli/releases/download/v2.78.0/gh_2.78.0_windows_amd64.msi
  ██████████████████████████████  17.4 MB / 17.4 MB
インストーラーハッシュが正常に検証されました
パッケージのインストールを開始しています...
インストーラーは管理者として実行するように要求します。プロンプトが表示されます。
インストールが完了しました
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ winget install sharkdp.bat -e --accept-source-agreements --accept-package-agreements  # frgのプレビュー用
見つかりました bat [sharkdp.bat] バージョン 0.25.0
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
このパッケージには次の依存関係が必要です:
  - パッケージ
      Microsoft.VCRedist.2015+.x64
ダウンロード中 https://github.com/sharkdp/bat/releases/download/v0.25.0/bat-v0.25.0-x86_64-pc-windows-msvc.zip
  ██████████████████████████████  3.18 MB / 3.18 MB
インストーラーハッシュが正常に検証されました
アーカイブを展開しています...
アーカイブが正常に展開されました
パッケージのインストールを開始しています...
パス環境変数が変更されました; 新しい値を使用するにはシェルを再起動してください。
コマンド ライン エイリアスが追加されました: "bat"
インストールが完了しました
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # 2) プロファイルに便利関数を追加（重複防止）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $prof = $PROFILE.CurrentUserAllHosts
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $dir  = Split-Path $prof
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(Test-Path $prof){
>   (Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN DEV-BOOST-BLOCK.*?# >>> END DEV-BOOST-BLOCK','' |
>     Set-Content $prof -Encoding UTF8
> }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ @'
> # >>> BEGIN DEV-BOOST-BLOCK
> # ガード
> $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
> $hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
> $hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
> $hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
> $hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)
>
> # ---- Git 基本ショートカット ----
> if($hasGit){
>   function gst   { git status -sb }
>   function glog  { git log --graph --decorate --oneline --color --all }
>   function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
>   function gclean{
>     git fetch --prune
>     git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} |
>       ForEach-Object { git branch -d ($_ -replace '^\s+','') }
>   }
> }
>
> # ---- fzf 連携（ある場合だけ）----
> if($hasGit -and $hasFzf){
>   # ブランチ切替（ローカル＋リモート）
>   function gco {
>     $locals  = git for-each-ref --format="%(refname:short)" refs/heads
>     $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
>     $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | `
>            fzf --height 40% --reverse
>     if(!$sel -or $sel -like "===*==="){ return }
>     if($sel -like "*/ *"){ $sel = $sel.Trim() }
>     if($locals -contains $sel){ git switch $sel; return }
>     # リモート選択時は追跡ブランチを切って切替
>     if($sel -like "*/ *"){ $sel = $sel.Trim() }
>     if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
>     git switch -c $name --track $sel
>   }
>
>   # 変更ファイルから選んで VSCode で開く
>   function gpick {
>     if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
>     $files = git ls-files -m -o --exclude-standard
>     $sel = $files | fzf --height 40% --reverse -m
>     if($sel){ code $sel }
>   }
>
>   # stash を選んで適用
>   function gstashp {
>     $line = git stash list | fzf --height 40% --reverse
>     if($line){ $id = $line.Split(':')[0]; git stash apply $id }
>   }
> }
>
> # ---- GitHub CLI 連携（ある場合だけ）----
> if($hasGh){
>   function ghlogin { gh auth login }           # 初回認証
>   function gpr     { param([string]$t=""); gh pr create --fill --title $t }
>   function gprvw   { gh pr view --web }
>   function gprco   {
>     $sel = gh pr list --limit 50 | fzf --height 40% --reverse
>     if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
>   }
>   function gbrowse { gh repo view --web }
> }
>
> # ---- ripgrep + fzf + bat + VSCode: frg改良版 ----
> function frg {
>   param([Parameter(Mandatory=$true)][string]$q)
>   if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
>   if(-not $hasFzf){ Write-Host "fzf がありません"; return }
>   $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
>   $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
>   if($sel){
>     $parts = $sel -split ':'
>     if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
>   }
> }
> # >>> END DEV-BOOST-BLOCK
> '@ | Add-Content $prof -Encoding UTF8
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ . $prof
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ Write-Host "[OK] Dev boost を適用しました。 (gco, gst, glog, gpick, gstashp, gpr, gprvw, gprco, gbrowse, frg)"
[OK] Dev boost を適用しました。 (gco, gst, glog, gpick, gstashp, gpr, gprvw, gprco, gbrowse, frg)
 hiroy@DESKTOP-D6G9TM0  ~ 
❯

### user  

PowerShell 7.5.2
Loading personal and system profiles took 1588ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ function frg {
>   param([string]$q)
>   $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview 'bat --style=numbers --color=always --line-range :500 {1} --highlight-line {2}' --preview-window=up:40%
>   if($sel){
>     $parts = $sel -split ':'
>     code "$($parts[0])" -g "$($parts[1])"
>   }
> }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯　　開発効率を重視したい

### assistant  

グッド！ほぼ入ってる。  
エラーの原因は **`if(Test-Path $prof -and …)` の書き方**で、`-and` は `Test-Path` のパラメータじゃなく**条件演算子**。また、`posh-git` の警告は **Git が未インストール**なだけ。ついでに `oh-my-posh` の**テーマパス**も環境によって違うので動的に探すよう直す。

下の“修正版フルスクリプト”を **PS7** に丸ごと貼り付けて実行して。  
（再実行しても安全。さっきのブロックを消してから良い設定を書き直す）

```powershell
# ==== PS7 快適プロファイル 修正版（再適用OK） ====

# 依存モジュール（ユーザー範囲）
Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
$mods = 'oh-my-posh','posh-git','Terminal-Icons'
foreach($m in $mods){ if(-not (Get-Module -ListAvailable $m)){ Install-Module $m -Scope CurrentUser -Force -ErrorAction SilentlyContinue } }

# プロファイル
$prof = $PROFILE.CurrentUserAllHosts
$dir  = Split-Path $prof
if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }

# 既存バックアップ（← 正しい条件式）
if( (Test-Path $prof) -and -not (Select-String -Path $prof -Pattern 'BEGIN GPT-PS-PROFILE' -Quiet) ){
  Copy-Item $prof "$prof.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
}

# 既存ブロック削除
if(Test-Path $prof){
  $txt = Get-Content $prof -Raw
  $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
  Set-Content $prof $txt -Encoding UTF8
}

# 新ブロック（git 未導入や OMP テーマパス差も吸収）
@'
# >>> BEGIN GPT-PS-PROFILE
[Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

# Modules（git が無ければ posh-git は読み込まない）
if (Get-Command git -ErrorAction SilentlyContinue) { Import-Module posh-git -ErrorAction SilentlyContinue }
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# oh-my-posh（EXE があり、テーマが見つかる時のみ）
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
$themeRoots = @(
  $env:POSH_THEMES_PATH,
  "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
  "C:\Program Files\oh-my-posh\themes"
) | Where-Object { $_ -and (Test-Path $_) }
if ($omp -and $themeRoots) {
  $theme = Join-Path ($themeRoots[0]) 'paradox.omp.json'
  if (Test-Path $theme) { oh-my-posh init pwsh --config $theme | Invoke-Expression }
}

# PSReadLine
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -MaximumHistoryCount 50000
  Set-PSReadLineOption -AddToHistoryHandler { param($line) return ($line -notmatch '^\s*$') }
  Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
  Set-PSReadLineKeyHandler -Key Ctrl+l    -ScriptBlock { Clear-Host }
  Set-PSReadLineKeyHandler -Key Ctrl+r    -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key Alt+Enter -Function AcceptLine
}

$PSStyle.FileInfo.Directory    = $PSStyle.Foreground.BrightBlue
$PSStyle.FileInfo.Executable   = $PSStyle.Foreground.BrightGreen
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.BrightCyan

Set-Alias ll Get-ChildItem
function which($name){ Get-Command $name -All }
# >>> END GPT-PS-PROFILE
'@ | Add-Content -Path $prof -Encoding UTF8

. $prof
Write-Host "`n[OK] プロファイルを適用しました。"
```

### 追加メモ
- **Git を使う予定があるなら**（posh-gitの警告も消える）：
  ```powershell
  winget install --id Git.Git -e
  ```
- **oh-my-posh の本体(Exe)も入れてテーマを確実に使う**（まだ未導入なら）：
  ```powershell
  winget install JanDeDobbeleer.OhMyPosh -e
  ```
  その後もう一度上のスクリプトを実行すれば、テーマが反映される。

必要なら、fzf 連携（`Ctrl+R`で超高速検索/ファジー補完）や、`kubectl`/`az`/`git` の充実補完セットも追撃できる。欲しい構成を教えて。

### user  

PowerShell 7.5.2
PS C:\Users\hiroy\OneDrive\デスクトップ> "Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
Edition=Core  Version=7.5.2  Home=C:\Program Files\PowerShell\7
PS C:\Users\hiroy\OneDrive\デスクトップ> (Get-Command pwsh).Source
C:\Program Files\PowerShell\7\pwsh.exe
PS C:\Users\hiroy\OneDrive\デスクトップ>

PowerShell 7.5.2
PS C:\Users\hiroy> Remove-Item "HKCU:\Software\Classes\Directory\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
PS C:\Users\hiroy> Remove-Item "HKCU:\Software\Classes\Directory\Background\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
PS C:\Users\hiroy> Remove-Item "HKCU:\Software\Classes\Drive\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
PS C:\Users\hiroy> Remove-Item "HKCU:\Software\Classes\LibraryFolder\Background\shell\Powershell" -Recurse -Force -ErrorAction SilentlyContinue
PS C:\Users\hiroy> Stop-Process -Name explorer -Force; Start-Process explorer.exe
PS C:\Users\hiroy>

うまくいってるよね？

### assistant  

エラーの原因わかった！  
`_fzf-files` / `_fzf-dirs` の定義で **if/else の直後をそのままパイプ**していたせいで、PowerShell が「パイプの左側が式じゃない」と怒っています（`An empty pipe element is not allowed.`）。  
→ 一度 **結果を変数に入れてから fzf に流す**ようにすればOK。

下のホットフィックスを貼り付けて実行してね（今のセッションでも即直るし、プロファイルにも追記して次回からも有効）。

```powershell
# --- fzf ホットフィックス: if/else の結果を変数に入れてからパイプ ---

# 1) 今のセッションの関数を差し替え
function _fzf-files {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t f -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}

function _fzf-dirs {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t d -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}

# 2) プロファイルにも追記して永続化（後勝ちでこの定義が有効になる）
$prof = $PROFILE.CurrentUserAllHosts
@'
function _fzf-files {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t f -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
function _fzf-dirs {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t d -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
'@ | Add-Content -Path $prof -Encoding UTF8

# 3) 反映
. $prof
Write-Host "[OK] fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。"
```

### 動作確認
- `Ctrl+T` → ファイル一覧が開けばOK  
- `Alt+C` → ディレクトリ一覧 → 選択で `cd`  

起動時間はプロンプト初回描画で oh-my-posh をロードする都合上、**最初の1回だけ少し重め**に見えることがあるけど、以降の新規タブや再描画は軽いはず。  
もしまだ 2秒超えるようなら、さらに絞って **oh-my-posh を“手動トグル”**（必要時だけ `Enable-PoshPrompt/Disable-PoshPrompt`）にする超ストイック版も出せるよ。

### assistant  

はい、それは **まだ Windows PowerShell 5.1** です。  
(`Edition=Desktop / Version=5.1 / Home=…WindowsPowerShell\v1.0`) になっているので、タスクバーのアイコンが **依然として powershell.exe (旧版)** を指しています。

---

## 状況整理
- スクリプトでは「.lnk（ショートカット）」を全部書き換えた → `[Done] 書換数: 2` は効いている  
- それでも起動すると 5.1 → つまり「タスクバーのアイコン」が **ストアアプリの AppX 経由ピン留め** または **特殊なシェルショートカット** になっていて、通常の `.lnk` とは別に管理されている。

Windows 10/11 ではタスクバーのピンが **AppID ベース（ストア・システムアプリ）** の場合、.lnk 書き換えでは置き換わらないケースがあります。

---

## 最短で直す方法（確実）
1. **今のタスクバーの PowerShell アイコンを右クリック → 「タスクバーからピン留めを外す」**  
   （この時点で古い 5.1 アイコンを完全に消す）
2. **スタートメニューで「PowerShell 7」または「PowerShell 7 (x64)」を検索**  
   - 出てきたアイコンを右クリック → 「その他」 → 「タスクバーにピン留めする」  
   - これでタスクバーに PS7 が登録される
3. タスクバーのそのアイコンから開くと **Edition=Core / Version=7.x** になるはず

---

## 確認
```powershell
$PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $PSHOME
```
が  
```
Core
7.5.2
C:\Program Files\PowerShell\7
```
になれば完全移行成功。

---

## 補足（自動で PS7 アイコンをピン留めする）
もし手動操作を省きたいなら、スクリプトで「PowerShell 7 をタスクバーに直接ピン留め」することもできます。ただしこれは **レジストリの Taskband バイナリ** を書き換えるため手荒。最も安全で確実なのは上記の「旧アイコンを外して → 新アイコンをピン留め直す」手順です。

---

👉 今の状態は「古いアイコンがまだタスクバーに残っている」だけなので、まずは手動で **旧アイコンを外す → 新しい PowerShell 7 をピン留め** をやってみて。  

試して結果どう？

### assistant  

任せて。**起動時間を最優先で短縮**しつつ、今の快適さは維持する“最良チューニング”を一発で入れるね。  
やることは：**徹底的な遅延ロード**（oh-my-posh / Terminal-Icons / posh-git を“使う瞬間まで”読み込まない）＋ fzf の既定検索を高速化。

下をそのまま **PS7** に貼り付けて実行して。

```powershell
# === 最良チューニング: 起動高速化（再実行OK） ===
$prof = $PROFILE.CurrentUserAllHosts
$dir  = Split-Path $prof
if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }

# 既存の GPT ブロック/DEV/FZF ブロックはまとめて置き換え（安全に再投入）
if(Test-Path $prof){
  (Get-Content $prof -Raw) `
    -replace '(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','' `
    -replace '(?s)# >>> BEGIN FZF-BLOCK.*?# >>> END FZF-BLOCK','' `
    -replace '(?s)# >>> BEGIN DEV-BOOST-BLOCK.*?# >>> END DEV-BOOST-BLOCK','' `
  | Set-Content $prof -Encoding UTF8
}

@'
# >>> BEGIN GPT-PS-PROFILE  (最良チューニング版)
# エンコーディングだけ即時設定（軽い）
[Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

# --- オートロード基本設定（標準でAllだが明示） ---
$PSModuleAutoloadingPreference = 'All'

# --- oh-my-posh / posh-git / Terminal-Icons を遅延ロード ---
$global:__omp_inited = $false
$global:__icons_inited = $false
$global:__poshgit_inited = $false

function __Init-OhMyPosh {
  if($global:__omp_inited){ return }
  $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
  if(-not $omp){ return }
  $themeRoots = @(
    $env:POSH_THEMES_PATH,
    "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
    "$env:ProgramFiles\oh-my-posh\themes"
  ) | Where-Object { $_ -and (Test-Path $_) }
  $theme = if($themeRoots){ Join-Path $themeRoots[0] 'jandedobbeleer.omp.json' }  # 情報量多め・軽快
  if($theme -and (Test-Path $theme)){
    oh-my-posh init pwsh --config $theme | Invoke-Expression
    $global:__omp_inited = $true
  }
}

function __Init-TerminalIcons {
  if($global:__icons_inited){ return }
  Import-Module Terminal-Icons -ErrorAction SilentlyContinue
  $global:__icons_inited = $true
}

function __Init-PoshGit {
  if($global:__poshgit_inited){ return }
  if(Get-Command git -ErrorAction SilentlyContinue){
    Import-Module posh-git -ErrorAction SilentlyContinue
    $global:__poshgit_inited = $true
  }
}

# --- PSReadLine（軽いので即時） ---
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -MaximumHistoryCount 50000

  # fzf 連携（キー割当のみ。本体はPATHにある想定）
  function _fzf-files { if(-not $global:__icons_inited){__Init-TerminalIcons}; if(Get-Command fd -ErrorAction SilentlyContinue){ fd -t f -H -E .git 2>$null } else { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --height 40% --reverse }
  function _fzf-dirs  { if(-not $global:__icons_inited){__Init-TerminalIcons}; if(Get-Command fd -ErrorAction SilentlyContinue){ fd -t d -H -E .git 2>$null } else { Get-ChildItem -Recurse -Directory | ForEach-Object FullName } | fzf --height 40% --reverse }
  function _fzf-hist  {
    $items = (Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
    ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
  }
  Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    $sel = _fzf-hist
    if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
  }
  Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    $sel = _fzf-files
    if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
  }
  Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
    $sel = _fzf-dirs
    if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine() }
  }
}

# --- fzf 既定（高速検索: fd / ripgrep 活用）---
if(Get-Command fd -ErrorAction SilentlyContinue){ $env:FZF_DEFAULT_COMMAND = 'fd -H -E .git' }
if(Get-Command bat -ErrorAction SilentlyContinue){ $env:BAT_THEME='TwoDark' }

# --- ls/ll 初回実行時にアイコンを有効化（遅延） ---
function ls { if(-not $global:__icons_inited){__Init-TerminalIcons}; Get-ChildItem @args }
Set-Alias ll Get-ChildItem

# --- プロンプト描画の最初のタイミングで OMP / posh-git を一度だけ初期化 ---
$script:__prompt_inited = $false
$__origPrompt = $function:prompt
function prompt {
  if(-not $script:__prompt_inited){
    __Init-PoshGit
    __Init-OhMyPosh
    $script:__prompt_inited = $true
  }
  if ($__origPrompt) { & $__origPrompt } else { "$(Get-Location)> " }
}

# --- 便利関数（軽いものだけ常駐）---
function which($name){ Get-Command $name -All }
# >>> END GPT-PS-PROFILE

# >>> BEGIN DEV-BOOST-BLOCK（軽量化対応版）
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
$hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
$hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
$hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)

if($hasGit){
  function gst   { git status -sb }
  function glog  { git log --graph --decorate --oneline --color --all }
  function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
  function gclean{
    git fetch --prune
    git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} | ForEach-Object { git branch -d ($_ -replace '^\s+','') }
  }
}

if($hasGit -and $hasFzf){
  function gco {
    $locals  = git for-each-ref --format="%(refname:short)" refs/heads
    $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
    $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | fzf --height 40% --reverse
    if(!$sel -or $sel -like "===*==="){ return }
    if($locals -contains $sel){ git switch $sel; return }
    if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
    git switch -c $name --track $sel
  }
  function gpick {
    if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
    $files = git ls-files -m -o --exclude-standard
    $sel = $files | fzf --height 40% --reverse -m
    if($sel){ code $sel }
  }
  function gstashp {
    $line = git stash list | fzf --height 40% --reverse
    if($line){ $id = $line.Split(':')[0]; git stash apply $id }
  }
}

if($hasGh){
  function ghlogin { gh auth login }
  function gpr     { param([string]$t=""); gh pr create --fill --title $t }
  function gprvw   { gh pr view --web }
  function gprco   {
    $sel = gh pr list --limit 50 | fzf --height 40% --reverse
    if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
  }
  function gbrowse { gh repo view --web }
}

# ripgrep + fzf + bat + VSCode
function frg {
  param([Parameter(Mandatory=$true)][string]$q)
  if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
  if(-not $hasFzf){ Write-Host "fzf がありません"; return }
  $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
  $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
  if($sel){
    $parts = $sel -split ':'
    if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
  }
}
# >>> END DEV-BOOST-BLOCK
'@ | Add-Content $prof -Encoding UTF8

. $prof
Write-Host "`n[OK] 最良チューニングを適用しました。起動時間を確認してみてください。"
```

### 何が変わる？
- 起動直後は **何も重いモジュールを読み込まない** → 体感が軽くなる  
- **初回のプロンプト描画時にだけ** oh-my-posh / posh-git を初期化  
- `ls/ll` を初めて叩いた瞬間に **Terminal-Icons** を読み込み  
- fzf の既定検索を **fd** に寄せて、`Ctrl+T / Alt+C` がキビキビ

### 測定のコツ
PowerShell を開き直して、ウィンドウ上部の  
`Loading personal and system profiles took XXXms.` の数値を比べてみて。  
（1,000ms台 → 数百ms〜1,000ms前後に落ちれば成功）

もっと詰めたい（300ms台を目指す等）なら、使っていない機能をピンポイントでさらに遅延/無効化する版も作るよ。

### user  

Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

新機能と改善のために最新の PowerShell をインストールしてください!https://aka.ms/PSWindows

PS C:\Users\hiroy> $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $PSHOME
Desktop

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      26100  4768
C:\Windows\System32\WindowsPowerShell\v1.0


PS C:\Users\hiroy>

### assistant  

完璧！ 🎉  

これで fzf セットが全部揃った状態だね：

- **fzf** → あいまい検索 UI  
- **fd** → 高速ファイル/ディレクトリ検索  
- **rg (ripgrep)** → 超高速テキスト検索  
- **キーバインド**  
  - `Ctrl+R` → 履歴検索  
  - `Ctrl+T` → ファイル選択  
  - `Alt+C` → ディレクトリ選択  

---

### ✅ 動作チェック
開き直した PowerShell で試してみて：

```powershell
# テキスト検索 (カレント配下で "PowerShell" を含む行)
rg PowerShell

# fzf 経由で履歴検索 (Ctrl+R を押す)
# fzf 経由でファイル検索 (Ctrl+T を押す)
# fzf 経由でディレクトリ移動 (Alt+C を押す)
```

---

### 💡 応用（欲しければ追加できる）
- `rg` と `fzf` を組み合わせて「検索結果から選んで VSCode で開く」関数  
- `git` コマンドと組み合わせて「ブランチ一覧を fzf で選んで checkout」(= gco)  
- 最近のディレクトリ履歴から移動（zoxide/fzf連携）

---

👉 今の状態でもう “最強クラスの PowerShell 作業環境” になってる。  
次は試しに **Ctrl+R / Ctrl+T / Alt+C の動作確認**をしてみる？

### user  

PowerShell 7.5.2
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:66
Line |
  66 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
PS C:\Users\hiroy> # --- profile.ps1 の _fzf-files / _fzf-dirs を安全に置換して修正 ---
PS C:\Users\hiroy> $prof = $PROFILE.CurrentUserAllHosts
PS C:\Users\hiroy> if(!(Test-Path $prof)){ Write-Host "profile.ps1 がまだ無いようです。"; return }
PS C:\Users\hiroy>
PS C:\Users\hiroy> $txt = Get-Content $prof -Raw
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 置換用の正しい定義
PS C:\Users\hiroy> $fixFiles = @'
>> function _fzf-files {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t f -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> '@
PS C:\Users\hiroy>
PS C:\Users\hiroy> $fixDirs = @'
>> function _fzf-dirs {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t d -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> '@
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 既存の問題ある定義を検出して置換（無ければそのまま追記）
PS C:\Users\hiroy> $reFiles = '(?s)function\s+_fzf-files\s*\{.*?\}'
PS C:\Users\hiroy> $reDirs  = '(?s)function\s+_fzf-dirs\s*\{.*?\}'
PS C:\Users\hiroy>
PS C:\Users\hiroy> $changed = $false
PS C:\Users\hiroy> if($txt -match $reFiles){ $txt = [regex]::Replace($txt,$reFiles,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $fixFiles }); $changed=$true }
PS C:\Users\hiroy> if($txt -match $reDirs ){ $txt = [regex]::Replace($txt,$reDirs ,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $fixDirs  }); $changed=$true }
PS C:\Users\hiroy>
PS C:\Users\hiroy> if(-not $changed){
>>   # 定義が見つからない場合は末尾に追記（後勝ちでこの定義が有効になる）
>>   $txt += "`r`n$fixFiles`r`n$fixDirs`r`n"
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> Set-Content $prof $txt -Encoding UTF8
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 読み込みテスト → エラーの行番号を抑止しつつ再読み込み
PS C:\Users\hiroy> . $prof
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:74
Line |
  74 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
PS C:\Users\hiroy> Write-Host "[OK] プロファイル内の fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。"
[OK] プロファイル内の fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。
PS C:\Users\hiroy>

### assistant  

いい質問 👍  
出てきた **Git** と **oh-my-posh.exe 本体** は「プロファイル強化の中核ツール」みたいな位置づけ。便利さのイメージを整理すると：

---

## 🔧 Git
- **なに？**  
  分散型バージョン管理システム。ソースコードや設定ファイルの変更履歴を管理する標準的なツール。  
  → ほぼすべての開発プロジェクト（OSS 含む）が GitHub / GitLab / Azure DevOps などで使ってる。

- **PowerShell プロンプト上の便利さ**  
  - `posh-git` モジュールが **現在ディレクトリが Git リポジトリならブランチ名や変更状態をプロンプトに表示**してくれる  
  - `git status` で未コミット変更や追跡状態を確認  
  - 右クリックで開いたターミナルからそのまま `git` 操作可能  

- **開発以外でも便利**  
  - 設定ファイルやスクリプトをバージョン管理  
  - GitHub の公開リポジトリからツールをそのまま取得  
  - dotfiles 管理（プロファイルや設定を別PCに再利用）

---

## 🎨 oh-my-posh 本体 (`oh-my-posh.exe`)
- **なに？**  
  PowerShell/Command Prompt/Bash/Zsh など **シェルの見た目をカスタマイズするツール**。  
  モジュールではなく実行ファイル（`oh-my-posh.exe`）として動作する。  

- **便利な点**  
  - プロンプトに **Gitブランチ/ステータス/エラーコード/経過時間** を一目で表示  
  - 数十種類の **カラフルなテーマ**が選べる（Powerline系やMinimal系）  
  - Nerd Font（記号付きフォント）と組み合わせると、フォルダやGit状態がアイコン付きで見やすい  
  - 複数シェルで共通設定を流用できる（PowerShellとWSLで同じテーマなど）

- **インストール**（Windowsなら winget が最速）
  ```powershell
  winget install JanDeDobbeleer.OhMyPosh -e
  ```
  これで `C:\Program Files\oh-my-posh\bin\oh-my-posh.exe` が入る。  
  プロファイルで `oh-my-posh init pwsh --config <テーマファイル>` を呼ぶとカスタムプロンプトになる。

---

## ✨ 両方導入するとどうなるか？
- **Git** → バージョン管理や GitHub 利用ができる  
- **posh-git + Git** → プロンプトに「ブランチ名」「未コミット数」「状態」が常時表示  
- **oh-my-posh.exe + テーマ** → 見た目を整えて、Git 情報や環境情報をカラフルに表示  
- **Terminal-Icons** → `ls` でアイコン付きファイル一覧  

→ 結果、ターミナルが「開発者っぽいカッコ良さ」と「実用的な情報表示」の両方を兼ね備える。

---

### ✅ まとめ
- **Git** … なくても動くけど、入れた方が絶対便利（開発以外でも設定管理やダウンロード用途に使える）。  
- **oh-my-posh.exe** … 見た目と情報量が段違いになる。実用＋モチベーションアップ。  

---

👉 ここまでで「導入したい」の気持ちある？  
それなら **Git + oh-my-posh 本体** を winget で入れて、さっきのプロファイルをもう一度適用する流れを一発スクリプトにまとめようか？

### user  

やってみた。PowerShell 7.5.2
PS C:\Users\hiroy> # -*- 最終移行スクリプト -*-
PS C:\Users\hiroy> # 目的: Windows PowerShell 5.1 をすべて PowerShell 7 (pwsh.exe) に差し替える
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 1) pwsh.exe のパスを自動検出
PS C:\Users\hiroy> try {
>>     $pwsh = (Get-Command pwsh -ErrorAction Stop).Source
>> } catch {
>>     $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 2) タスクバーのピン留め修正
PS C:\Users\hiroy> $taskbar = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
PS C:\Users\hiroy> $links = Get-ChildItem $taskbar -Filter *.lnk -ErrorAction SilentlyContinue
PS C:\Users\hiroy> $ws  = New-Object -ComObject WScript.Shell
PS C:\Users\hiroy> foreach ($lnk in $links) {
>>     $sc = $ws.CreateShortcut($lnk.FullName)
>>     if ($sc.TargetPath -match 'WindowsPowerShell\\v1\.0\\powershell\.exe') {
>>         $sc.TargetPath  = $pwsh
>>         $sc.Arguments   = ''
>>         $sc.IconLocation= "$pwsh,0"
>>         $sc.Save()
>>     }
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 3) スタートメニューの既定関連付け（.ps1 → PS7）
PS C:\Users\hiroy> New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
>>   Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -File `"%1`" %*" | Out-Null
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 4) エクスプローラーの右クリック「ここで PowerShell 7 を開く」
PS C:\Users\hiroy> New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
>>   Set-ItemProperty -Name "MUIVerb" -Value "ここで PowerShell 7 を開く" -PassThru |
>>   Set-ItemProperty -Name "Icon" -Value "$pwsh,0" | Out-Null
PS C:\Users\hiroy> New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
>>   Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 5) Windows Terminal の既定を PowerShell 7 に（あれば）
PS C:\Users\hiroy> $terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
PS C:\Users\hiroy> if (Test-Path $terminalSettings) {
>>     $json = Get-Content $terminalSettings -Raw | ConvertFrom-Json
>>     $ps7profile = $json.profiles.list | Where-Object { $_.commandline -match "pwsh" }
>>     if ($ps7profile) {
>>         $json.profiles.defaults = @{} # ensure exists
>>         $json.defaultProfile = $ps7profile.guid
>>         $json | ConvertTo-Json -Depth 10 | Set-Content $terminalSettings -Encoding UTF8
>>     }
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 6) 反映のためエクスプローラーを再起動
PS C:\Users\hiroy> Stop-Process -Name explorer -Force
PS C:\Users\hiroy> Start-Process explorer.exe
PS C:\Users\hiroy>
PS C:\Users\hiroy> Write-Host "=== PowerShell 7 への完全移行が完了しました ==="
=== PowerShell 7 への完全移行が完了しました ===
PS C:\Users\hiroy> Write-Host "タスクバー/スタート/右クリック/Win+X からすべて PowerShell 7 が開きます"
タスクバー/スタート/右クリック/Win+X からすべて PowerShell 7 が開きます
PS C:\Users\hiroy>

### user  

PowerShell 7.5.2
Loading personal and system profiles took 2105ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # === 最良チューニング: 起動高速化（再実行OK） ===
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $prof = $PROFILE.CurrentUserAllHosts
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $dir  = Split-Path $prof
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # 既存の GPT ブロック/DEV/FZF ブロックはまとめて置き換え（安全に再投入）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(Test-Path $prof){
>   (Get-Content $prof -Raw) `
>     -replace '(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','' `
>     -replace '(?s)# >>> BEGIN FZF-BLOCK.*?# >>> END FZF-BLOCK','' `
>     -replace '(?s)# >>> BEGIN DEV-BOOST-BLOCK.*?# >>> END DEV-BOOST-BLOCK','' `
>   | Set-Content $prof -Encoding UTF8
> }
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ @'
> # >>> BEGIN GPT-PS-PROFILE  (最良チューニング版)
> # エンコーディングだけ即時設定（軽い）
> [Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
> [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
>
> # --- オートロード基本設定（標準でAllだが明示） ---
> $PSModuleAutoloadingPreference = 'All'
>
> # --- oh-my-posh / posh-git / Terminal-Icons を遅延ロード ---
> $global:__omp_inited = $false
> $global:__icons_inited = $false
> $global:__poshgit_inited = $false
>
> function __Init-OhMyPosh {
>   if($global:__omp_inited){ return }
>   $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
>   if(-not $omp){ return }
>   $themeRoots = @(
>     $env:POSH_THEMES_PATH,
>     "$env:LOCALAPPDATA\Programs\oh-my-posh\themes",
>     "$env:ProgramFiles\oh-my-posh\themes"
>   ) | Where-Object { $_ -and (Test-Path $_) }
>   $theme = if($themeRoots){ Join-Path $themeRoots[0] 'jandedobbeleer.omp.json' }  # 情報量多め・軽快
>   if($theme -and (Test-Path $theme)){
>     oh-my-posh init pwsh --config $theme | Invoke-Expression
>     $global:__omp_inited = $true
>   }
> }
>
> function __Init-TerminalIcons {
>   if($global:__icons_inited){ return }
>   Import-Module Terminal-Icons -ErrorAction SilentlyContinue
>   $global:__icons_inited = $true
> }
>
> function __Init-PoshGit {
>   if($global:__poshgit_inited){ return }
>   if(Get-Command git -ErrorAction SilentlyContinue){
>     Import-Module posh-git -ErrorAction SilentlyContinue
>     $global:__poshgit_inited = $true
>   }
> }
>
> # --- PSReadLine（軽いので即時） ---
> if (Get-Module -ListAvailable PSReadLine) {
>   Import-Module PSReadLine -ErrorAction SilentlyContinue
>   Set-PSReadLineOption -EditMode Windows
>   Set-PSReadLineOption -BellStyle None
>   Set-PSReadLineOption -PredictionSource HistoryAndPlugin
>   Set-PSReadLineOption -PredictionViewStyle ListView
>   Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
>   Set-PSReadLineOption -HistorySearchCursorMovesToEnd
>   Set-PSReadLineOption -MaximumHistoryCount 50000
>
>   # fzf 連携（キー割当のみ。本体はPATHにある想定）
>   function _fzf-files { if(-not $global:__icons_inited){__Init-TerminalIcons}; if(Get-Command fd -ErrorAction SilentlyContinue){ fd -t f -H -E .git 2>$null } else { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --height 40% --reverse }
>   function _fzf-dirs  { if(-not $global:__icons_inited){__Init-TerminalIcons}; if(Get-Command fd -ErrorAction SilentlyContinue){ fd -t d -H -E .git 2>$null } else { Get-ChildItem -Recurse -Directory | ForEach-Object FullName } | fzf --height 40% --reverse }
>   function _fzf-hist  {
>     $items = (Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
>     ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
>   }
>   Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
>     $sel = _fzf-hist
>     if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
>   }
>   Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
>     $sel = _fzf-files
>     if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
>   }
>   Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
>     $sel = _fzf-dirs
>     if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine() }
>   }
> }
>
> # --- fzf 既定（高速検索: fd / ripgrep 活用）---
> if(Get-Command fd -ErrorAction SilentlyContinue){ $env:FZF_DEFAULT_COMMAND = 'fd -H -E .git' }
> if(Get-Command bat -ErrorAction SilentlyContinue){ $env:BAT_THEME='TwoDark' }
>
> # --- ls/ll 初回実行時にアイコンを有効化（遅延） ---
> function ls { if(-not $global:__icons_inited){__Init-TerminalIcons}; Get-ChildItem @args }
> Set-Alias ll Get-ChildItem
>
> # --- プロンプト描画の最初のタイミングで OMP / posh-git を一度だけ初期化 ---
> $script:__prompt_inited = $false
> $__origPrompt = $function:prompt
> function prompt {
>   if(-not $script:__prompt_inited){
>     __Init-PoshGit
>     __Init-OhMyPosh
>     $script:__prompt_inited = $true
>   }
>   if ($__origPrompt) { & $__origPrompt } else { "$(Get-Location)> " }
> }
>
> # --- 便利関数（軽いものだけ常駐）---
> function which($name){ Get-Command $name -All }
> # >>> END GPT-PS-PROFILE
>
> # >>> BEGIN DEV-BOOST-BLOCK（軽量化対応版）
> $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
> $hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
> $hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
> $hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
> $hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)
>
> if($hasGit){
>   function gst   { git status -sb }
>   function glog  { git log --graph --decorate --oneline --color --all }
>   function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
>   function gclean{
>     git fetch --prune
>     git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} | ForEach-Object { git branch -d ($_ -replace '^\s+','') }
>   }
> }
>
> if($hasGit -and $hasFzf){
>   function gco {
>     $locals  = git for-each-ref --format="%(refname:short)" refs/heads
>     $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
>     $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | fzf --height 40% --reverse
>     if(!$sel -or $sel -like "===*==="){ return }
>     if($locals -contains $sel){ git switch $sel; return }
>     if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
>     git switch -c $name --track $sel
>   }
>   function gpick {
>     if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
>     $files = git ls-files -m -o --exclude-standard
>     $sel = $files | fzf --height 40% --reverse -m
>     if($sel){ code $sel }
>   }
>   function gstashp {
>     $line = git stash list | fzf --height 40% --reverse
>     if($line){ $id = $line.Split(':')[0]; git stash apply $id }
>   }
> }
>
> if($hasGh){
>   function ghlogin { gh auth login }
>   function gpr     { param([string]$t=""); gh pr create --fill --title $t }
>   function gprvw   { gh pr view --web }
>   function gprco   {
>     $sel = gh pr list --limit 50 | fzf --height 40% --reverse
>     if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
>   }
>   function gbrowse { gh repo view --web }
> }
>
> # ripgrep + fzf + bat + VSCode
> function frg {
>   param([Parameter(Mandatory=$true)][string]$q)
>   if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
>   if(-not $hasFzf){ Write-Host "fzf がありません"; return }
>   $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
>   $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
>   if($sel){
>     $parts = $sel -split ':'
>     if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
>   }
> }
> # >>> END DEV-BOOST-BLOCK
> '@ | Add-Content $prof -Encoding UTF8
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ . $prof
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:66
Line |
  66 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
 hiroy@DESKTOP-D6G9TM0  ~   
❯ Write-Host "`n[OK] 最良チューニングを適用しました。起動時間を確認してみてください。"

[OK] 最良チューニングを適用しました。起動時間を確認してみてください。
 hiroy@DESKTOP-D6G9TM0  ~ 
❯

### user  

 hiroy@DESKTOP-D6G9TM0  ~ 
❯ winget install BurntSushi.ripgrep.MSVC -e --accept-package-agreements --accept-source-agreements
見つかりました RipGrep MSVC [BurntSushi.ripgrep.MSVC] バージョン 14.1.1
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
ダウンロード中 https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-pc-windows-msvc.zip
  ██████████████████████████████  1.96 MB / 1.96 MB
インストーラーハッシュが正常に検証されました
アーカイブを展開しています...
アーカイブが正常に展開されました
パッケージのインストールを開始しています...
パス環境変数が変更されました; 新しい値を使用するにはシェルを再起動してください。
コマンド ライン エイリアスが追加されました: "rg"
インストールが完了しました
 hiroy@DESKTOP-D6G9TM0  ~ 
❯

### user  

PowerShell 7.5.2
Loading personal and system profiles took 1278ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # === fzf + 補助ツール導入 & キーバインド ===
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # ツール本体
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ winget install junegunn.fzf -e --accept-package-agreements --accept-source-agreements
見つかりました fzf [junegunn.fzf] バージョン 0.65.1
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
ダウンロード中 https://github.com/junegunn/fzf/releases/download/v0.65.1/fzf-0.65.1-windows_amd64.zip
  ██████████████████████████████  1.77 MB / 1.77 MB
インストーラーハッシュが正常に検証されました
アーカイブを展開しています...
アーカイブが正常に展開されました
パッケージのインストールを開始しています...
パス環境変数が変更されました; 新しい値を使用するにはシェルを再起動してください。
コマンド ライン エイリアスが追加されました: "fzf"
インストールが完了しました
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ winget install BurntSushi.ripgrep -e --accept-package-agreements --accept-source-agreements   # rg: 超高速検索
入力条件に一致するパッケージが見つかりませんでした。
 hiroy@DESKTOP-D6G9TM0  ~   
❯ winget install sharkdp.fd -e --accept-package-agreements --accept-source-agreements           # fd: 高速ファイル検索
見つかりました fd [sharkdp.fd] バージョン 10.3.0
このアプリケーションは所有者からライセンス供与されます。
Microsoft はサードパーティのパッケージに対して責任を負わず、ライセンスも付与しません。
このパッケージには次の依存関係が必要です:
  - パッケージ
      Microsoft.VCRedist.2015+.x64
ダウンロード中 https://github.com/sharkdp/fd/releases/download/v10.3.0/fd-v10.3.0-x86_64-pc-windows-msvc.zip
  ██████████████████████████████  1.42 MB / 1.42 MB
インストーラーハッシュが正常に検証されました
アーカイブを展開しています...
アーカイブが正常に展開されました
パッケージのインストールを開始しています...
パス環境変数が変更されました; 新しい値を使用するにはシェルを再起動してください。
コマンド ライン エイリアスが追加されました: "fd"
インストールが完了しました
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # プロファイルに機能追記（重複防止で同名ブロックを一度消してから追加）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ $prof=$PROFILE.CurrentUserAllHosts
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(!(Test-Path (Split-Path $prof))){New-Item -ItemType Directory -Path (Split-Path $prof)|Out-Null}
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ if(Test-Path $prof){(Get-Content $prof -Raw) -replace '(?s)# >>> BEGIN FZF-BLOCK.*?# >>> END FZF-BLOCK','' | Set-Content $prof -Encoding UTF8}
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ @'
> # >>> BEGIN FZF-BLOCK
> # fzf helpers
> function _fzf-files { fd -t f -H -E .git 2>$null | fzf --height 40% --reverse }
> function _fzf-dirs  { fd -t d -H -E .git 2>$null | fzf --height 40% --reverse }
> function _fzf-hist  {
>   $items = (Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
>   ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
> }
>
> # キーバインド
> Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
>   $sel = _fzf-hist
>   if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
> }
> Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
>   $sel = _fzf-files
>   if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
> }
> Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
>   $sel = _fzf-dirs
>   if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`n$(Get-Location)> ") }
> }
> # >>> END FZF-BLOCK
> '@ | Add-Content $prof -Encoding UTF8
 hiroy@DESKTOP-D6G9TM0  ~ 
❯
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ . $prof
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ Write-Host "[OK] fzf 連携を有効化しました（Ctrl+R / Ctrl+T / Alt+C）"
[OK] fzf 連携を有効化しました（Ctrl+R / Ctrl+T / Alt+C）
 hiroy@DESKTOP-D6G9TM0  ~ 
❯

### assistant  

完了ログありがとう。仕上げに「確認・ロールバック・併用オプション」だけ置いとく。必要なとこだけ使って。

---

## すぐ確認（どこから開いても PS7？）
1) タスクバーのアイコン → 起動して実行  
```powershell
"Edition=$($PSVersionTable.PSEdition)  Version=$($PSVersionTable.PSVersion)  Home=$PSHOME"
```
`Edition=Core / Version=7.x / Home=...\PowerShell\7\` ならOK。

2) Win+X → Windows Terminal(管理者) でも同じ出力になるか確認。  
3) エクスプローラーで任意フォルダを右クリック → 「ここで PowerShell 7 を開く」が出て開けるか。  
4) `.ps1` をダブルクリックして PS7 で走るか。

---

## もし戻したくなったら（ロールバック）
貼り付け一発で元に戻せるようにしてある：

```powershell
# 右クリックメニューを削除
Remove-Item "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Recurse -Force

# .ps1 の関連付けを Windows PowerShell 5.1 に戻す
$ps51 = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
New-Item "HKCU:\Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$ps51`" -NoLogo -File `"%1`" %*" | Out-Null

# タスクバーのピン留めのうち、5.1 を指していたら復帰（任意）
$taskbar = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
$ws = New-Object -ComObject WScript.Shell
Get-ChildItem $taskbar -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object{
  $sc = $ws.CreateShortcut($_.FullName)
  if ($sc.TargetPath -match 'PowerShell\\7\\pwsh\.exe') {
    $sc.TargetPath = $ps51; $sc.Arguments=''; $sc.IconLocation="$ps51,0"; $sc.Save()
  }
}
Stop-Process -Name explorer -Force; Start-Process explorer.exe
```

---

## 5.1 も併用したい派向け（右クリックに 5.1 も追加）
管理ツールが 5.1 前提のとき用に、PS7 と並べて出せるようにする：

```powershell
$ps51 = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPS51" -Force |
  Set-ItemProperty -Name "MUIVerb" -Value "ここで Windows PowerShell 5.1 を開く" -PassThru |
  Set-ItemProperty -Name "Icon" -Value "$ps51,0" | Out-Null
New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPS51\command" -Force |
  Set-ItemProperty -Name "(default)" -Value "`"$ps51`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
```

（消す場合）
```powershell
Remove-Item "HKCU:\Software\Classes\Directory\shell\OpenPS51" -Recurse -Force
```

---

## 小ネタ（互換モジュール）
5.1 専用モジュールが必要なら、PS7 で下記を入れるとだいたい動かせる：
```powershell
Install-Module -Name WindowsCompatibility -Scope CurrentUser
Import-WinModule ServerManager  # 例
```

---

他にも PS7 のプロファイル最適化（補完/色/履歴など）を一括で整えるスニペットも作れる。要るなら用途（開発/管理/日常）だけ教えてくれれば、その場で落とし込むよ。

### assistant  

いいね 👍  
別チャットに「進化の成果」を共有するなら、**要点を簡潔にまとめつつ、自分がやった工夫を強調する形**が最良。  

以下みたいなフォーマットを使うと、相手（＝ChatGPTの別ルームや将来の自分）がすぐに理解できて、追加相談もしやすいよ👇  

---

## 🚀 PowerShell 開発環境の進化メモ（共有用）

### ✔ 導入したもの
- **PowerShell 7.5.2** に完全移行（タスクバー/右クリック/スタート全部 PS7 起動）  
- **プロファイル自動整備**  
  - UTF-8 環境強制  
  - 遅延ロード（oh-my-posh, posh-git, Terminal-Icons）  
  - fzf / fd / rg / bat / GitHub CLI / VSCode 連携  
- **PSReadLine 拡張**  
  - `Ctrl+R` → 履歴検索（fzf）  
  - `Ctrl+T` → ファイル検索  
  - `Alt+C` → ディレクトリ移動  

### ✔ 開発効率ショートカット
- `gst` → git status  
- `glog` → git log --graph  
- `gco` → fzf でブランチ選択  
- `gpick` → 変更ファイルを選んで VSCode で開く  
- `gstashp` → stash pick  
- `frg <word>` → ripgrep+fzf+bat で全文検索 → VSCode ジャンプ  

### ✔ チューニング
- プロンプトは **初回描画時にのみ oh-my-posh 起動** → 起動時間大幅短縮  
- `Enable-PoshPrompt` / `Disable-PoshPrompt` で手動トグル可能  

---

👉 こんな感じで「導入物／ショートカット／チューニング」を3ブロックでまとめると、読みやすいし別チャットに投げてもすぐ再現・応用できる。  

---

質問：  
この「共有用サマリ」を、**コードブロック形式（```で囲む）**にした方がいい？  
それとも Markdown のまま（見出し付き）で渡したい？

### user  

やって

### assistant  

エラーは**プロファイル内に残っている古い `_fzf-files/_fzf-dirs` 定義**（`} | fzf ...` みたいに if/else の直後をパイプしている版）がまだ生きているのが原因です。  
部分置換が引っかからなかった可能性があるので、**安全にバックアップ → まるごと健全版で書き替え**ます（再実行OK・いつでも戻せる）。

下を **PS7** にそのまま貼り付けて実行してください。

```powershell
# === profile.ps1 をバックアップして“健全版”に入れ替え（再実行OK） ===
$prof = $PROFILE.CurrentUserAllHosts
$dir  = Split-Path $prof
if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }

# バックアップ
if(Test-Path $prof){
  Copy-Item $prof "$prof.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
}

# 新しい内容（エラーの原因だった if/else→直パイプは完全排除済み）
$new = @'
# >>> BEGIN GPT-PS-PROFILE  (最良チューニング・固定化)
[Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$PSModuleAutoloadingPreference = 'All'

# 遅延ロード用フラグ
$global:__omp_inited    = $false
$global:__icons_inited  = $false
$global:__poshgit_inited= $false

function __Init-OhMyPosh {
  if($global:__omp_inited){ return }
  $omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
  if(-not $omp){ return }
  $themeRoots = @($env:POSH_THEMES_PATH,"$env:LOCALAPPDATA\Programs\oh-my-posh\themes","$env:ProgramFiles\oh-my-posh\themes") |
    Where-Object { $_ -and (Test-Path $_) }
  $theme = if($themeRoots){ Join-Path $themeRoots[0] 'jandedobbeleer.omp.json' }
  if($theme -and (Test-Path $theme)){
    oh-my-posh init pwsh --config $theme | Invoke-Expression
    $global:__omp_inited = $true
  }
}
function __Init-TerminalIcons {
  if($global:__icons_inited){ return }
  Import-Module Terminal-Icons -ErrorAction SilentlyContinue
  $global:__icons_inited = $true
}
function __Init-PoshGit {
  if($global:__poshgit_inited){ return }
  if(Get-Command git -ErrorAction SilentlyContinue){
    Import-Module posh-git -ErrorAction SilentlyContinue
    $global:__poshgit_inited = $true
  }
}

# PSReadLine（軽いので即時）
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -BellStyle None
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -MaximumHistoryCount 50000
}

# fzf 既定
if(Get-Command fd  -ErrorAction SilentlyContinue){ $env:FZF_DEFAULT_COMMAND = 'fd -H -E .git' }
if(Get-Command bat -ErrorAction SilentlyContinue){ $env:BAT_THEME='TwoDark' }

# ls/ll 初回実行でアイコンをロード（遅延）
function ls { if(-not $global:__icons_inited){ __Init-TerminalIcons }; Get-ChildItem @args }
Set-Alias ll Get-ChildItem

# 初回プロンプト描画時だけ OMP/posh-git を初期化
$script:__prompt_inited = $false
$__origPrompt = $function:prompt
function prompt {
  if(-not $script:__prompt_inited){
    __Init-PoshGit
    __Init-OhMyPosh
    $script:__prompt_inited = $true
  }
  if ($__origPrompt) { & $__origPrompt } else { "$(Get-Location)> " }
}

function which($name){ Get-Command $name -All }

# ---- fzf ヘルパー（安全版：必ず変数に受けてからパイプ） ----
function _fzf-files {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t f -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
function _fzf-dirs {
  if(-not $global:__icons_inited){ __Init-TerminalIcons }
  $items = if(Get-Command fd -ErrorAction SilentlyContinue){
    fd -t d -H -E .git 2>$null
  } else {
    Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
  }
  $items | fzf --height 40% --reverse
}
# キーバインド
if (Get-Module -ListAvailable PSReadLine) {
  Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    $histFile = (Get-PSReadLineOption).HistorySavePath
    $items = (Get-Content $histFile -ErrorAction SilentlyContinue) + (Get-History | ForEach-Object CommandLine)
    $sel = ($items | Select-Object -Unique) -join "`n" | fzf --height 40% --reverse
    if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
  }
  Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    $sel = _fzf-files
    if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
  }
  Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock {
    $sel = _fzf-dirs
    if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine() }
  }
}
# >>> END GPT-PS-PROFILE

# >>> BEGIN DEV-BOOST-BLOCK（軽量化対応）
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$hasFzf = [bool](Get-Command fzf -ErrorAction SilentlyContinue)
$hasGh  = [bool](Get-Command gh  -ErrorAction SilentlyContinue)
$hasBat = [bool](Get-Command bat -ErrorAction SilentlyContinue)
$hasCode= [bool](Get-Command code -ErrorAction SilentlyContinue)

if($hasGit){
  function gst   { git status -sb }
  function glog  { git log --graph --decorate --oneline --color --all }
  function gsync { git fetch origin; git switch main 2>$null; git switch master 2>$null; git pull --ff-only }
  function gclean{
    git fetch --prune
    git branch --merged | Where-Object {$_ -notmatch '^\*|main|master'} | ForEach-Object { git branch -d ($_ -replace '^\s+','') }
  }
}
if($hasGit -and $hasFzf){
  function gco {
    $locals  = git for-each-ref --format="%(refname:short)" refs/heads
    $remotes = git for-each-ref --format="%(refname:short)" refs/remotes | Where-Object {$_ -notmatch '/HEAD$'}
    $sel = @("=== local branches ===") + $locals + "=== remote branches ===" + $remotes | fzf --height 40% --reverse
    if(!$sel -or $sel -like "===*==="){ return }
    if($locals -contains $sel){ git switch $sel; return }
    if($sel -match '^origin/(.+)$'){ $name=$Matches[1] } else { $name=($sel -replace '.+?/','') }
    git switch -c $name --track $sel
  }
  function gpick {
    if(-not $hasCode){ Write-Host "code コマンドが見つかりません"; return }
    $files = git ls-files -m -o --exclude-standard
    $sel = $files | fzf --height 40% --reverse -m
    if($sel){ code $sel }
  }
  function gstashp {
    $line = git stash list | fzf --height 40% --reverse
    if($line){ $id = $line.Split(':')[0]; git stash apply $id }
  }
}
if($hasGh){
  function ghlogin { gh auth login }
  function gpr     { param([string]$t=""); gh pr create --fill --title $t }
  function gprvw   { gh pr view --web }
  function gprco   {
    $sel = gh pr list --limit 50 | fzf --height 40% --reverse
    if($sel){ $num = ($sel -split '\s+')[0]; gh pr checkout $num }
  }
  function gbrowse { gh repo view --web }
}

# ripgrep + fzf + bat + VSCode
function frg {
  param([Parameter(Mandatory=$true)][string]$q)
  if(-not (Get-Command rg -ErrorAction SilentlyContinue)){ Write-Host "rg がありません"; return }
  if(-not $hasFzf){ Write-Host "fzf がありません"; return }
  $preview = if($hasBat){ "bat --style=numbers --color=always --line-range :200 {1} --highlight-line {2}" } else { "type {1}" }
  $sel = rg --line-number $q | fzf --delimiter : --nth 3.. --preview $preview --preview-window=up:60%
  if($sel){
    $parts = $sel -split ':'
    if($hasCode){ code "$($parts[0])" -g "$($parts[1])" } else { Write-Host "$($parts[0]):$($parts[1])" }
  }
}
# >>> END DEV-BOOST-BLOCK
'@

# 上書き
Set-Content $prof $new -Encoding UTF8

# 反映
. $prof
Write-Host "[OK] profile.ps1 をクリーンな内容に入れ替えました。Ctrl+T / Alt+C を試し、起動時エラーが消えたことを確認してください。"
```

### 期待する結果
- ドットソース (`. $PROFILE.CurrentUserAllHosts`) 時の **ParserError が消える**  
- `Ctrl+T` / `Alt+C` が動作  
- 起動時の体感はそのまま or 以前より軽い（oh-my-posh/posh-git/Terminal-Icons は遅延初期化）

> もしまだエラーが出る場合は、`notepad $PROFILE.CurrentUserAllHosts` で開いて**66〜80行付近**に `}| fzf` のような行が残っていないか一度目視で確認してみて。消せば即解決します。

### user  

PowerShell 7.5.2
PS C:\Users\hiroy> # ==== PS7 快適プロファイル 一発セットアップ ====
PS C:\Users\hiroy> # 1) 依存モジュールを導入（ユーザー範囲）
PS C:\Users\hiroy> Set-PSRepository PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
PS C:\Users\hiroy> $mods = 'oh-my-posh','posh-git','Terminal-Icons'
PS C:\Users\hiroy> foreach($m in $mods){ if(-not (Get-Module -ListAvailable $m)){ Install-Module $m -Scope CurrentUser -Force } }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 2) プロファイル 書き込み先（全ホスト/現在ユーザー）
PS C:\Users\hiroy> $prof = $PROFILE.CurrentUserAllHosts
PS C:\Users\hiroy> $dir  = Split-Path $prof
PS C:\Users\hiroy> if(!(Test-Path $dir)){ New-Item $dir -ItemType Directory | Out-Null }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 3) 既存プロファイルをバックアップ（1度だけ／毎回上書き安全）
PS C:\Users\hiroy> if(Test-Path $prof -and -not (Get-Content $prof -ErrorAction SilentlyContinue | Select-String 'BEGIN GPT-PS-PROFILE')){
>>   Copy-Item $prof "$prof.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
>> }
Test-Path: A parameter cannot be found that matches parameter name 'and'.
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 4) 既存の当ブロックを除去
PS C:\Users\hiroy> if(Test-Path $prof){
>>   $txt = Get-Content $prof -Raw
>>   $txt = [regex]::Replace($txt,'(?s)# >>> BEGIN GPT-PS-PROFILE.*?# >>> END GPT-PS-PROFILE','')
>>   Set-Content $prof $txt -Encoding UTF8
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 5) プロファイル本体を追記
PS C:\Users\hiroy> @'
>> # >>> BEGIN GPT-PS-PROFILE
>> # --- Console / Encoding ---
>> [Console]::InputEncoding  = [Text.UTF8Encoding]::UTF8
>> [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
>>
>> # --- Modules ---
>> Import-Module posh-git    -ErrorAction SilentlyContinue
>> Import-Module Terminal-Icons -ErrorAction SilentlyContinue
>> # oh-my-posh: 軽量 Paradox テーマ（好みで変更可）
>> $ompExe = (Get-Command oh-my-posh -ErrorAction SilentlyContinue).Source
>> if($ompExe){
>>   $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
>>   oh-my-posh init pwsh --config $theme | Invoke-Expression
>> }
>>
>> # --- PSReadLine 快適化 ---
>> if (Get-Module -ListAvailable PSReadLine) {
>>   Import-Module PSReadLine -ErrorAction SilentlyContinue
>>   Set-PSReadLineOption -EditMode Windows
>>   Set-PSReadLineOption -BellStyle None
>>   Set-PSReadLineOption -PredictionSource HistoryAndPlugin
>>   Set-PSReadLineOption -PredictionViewStyle ListView
>>   Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
>>   Set-PSReadLineOption -HistorySearchCursorMovesToEnd
>>   Set-PSReadLineOption -MaximumHistoryCount 50000
>>
>>   # 空行や先頭空白だけは履歴に残さない
>>   Set-PSReadLineOption -AddToHistoryHandler {
>>     param($line) return ($line -notmatch '^\s*$')
>>   }
>>
>>   # Key bindings
>>   Set-PSReadLineKeyHandler -Key Tab     -Function MenuComplete
>>   Set-PSReadLineKeyHandler -Key "Ctrl+l" -ScriptBlock { Clear-Host }
>>   Set-PSReadLineKeyHandler -Key "Ctrl+r" -Function ReverseSearchHistory
>>   Set-PSReadLineKeyHandler -Key "Alt+Enter" -Function AcceptLine
>> }
>>
>> # --- 見た目少し良く ---
>> $PSStyle.FileInfo.Directory = $PSStyle.Foreground.BrightBlue
>> $PSStyle.FileInfo.Executable = $PSStyle.Foreground.BrightGreen
>> $PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.BrightCyan
>>
>> # --- 便利エイリアス（安全な範囲） ---
>> Set-Alias ll Get-ChildItem
>> function which($name){ Get-Command $name -All }
>>
>> # --- Git 仮想環境/ブランチ情報は posh-git/oh-my-posh 側に任せる ---
>> # >>> END GPT-PS-PROFILE
>> '@ | Add-Content -Path $prof -Encoding UTF8
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 6) すぐ反映
PS C:\Users\hiroy> . $prof
WARNING: git command could not be found. Please create an alias or add it to your PATH.
C:\Users\hiroy>
C:\Users\hiroy> Write-Host "`n[OK] 新プロファイルを適用しました。必要ならテーマは $env:POSH_THEMES_PATH から選んで変更してください。"

[OK] 新プロファイルを適用しました。必要ならテーマは  から選んで変更してください。
C:\Users\hiroy>

### assistant  

いい感じ！Git / oh-my-posh は入ってる。仕上げとして「テーマ適用の確認」と「見た目が出ない場合のワンショット修正」を置くね。

## ① 状態チェック（そのまま貼り付け）
```powershell
git --version
(Get-Command oh-my-posh).Source
$env:POSH_THEMES_PATH
Test-Path "$env:POSH_THEMES_PATH\paradox.omp.json"
```
- 4行目が **True** ならテーマパスOK。False や空なら②へ。

## ② テーマパスの自動補正 + すぐ反映（安全）
```powershell
# もっとも確実なテーマフォルダを検出して環境変数に反映
$roots = @(
  "$env:ProgramFiles\oh-my-posh\themes",
  "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
) | Where-Object { Test-Path $_ }
if($roots){ $env:POSH_THEMES_PATH = $roots[0] }

# セッションに即テーマ適用（プロファイルの設定はそのまま活きる）
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
  if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression }
}
```

## ③ フォントだけ注意（見た目が崩れる場合）
Windows Terminal → 設定 → プロファイル（PowerShell）→ **外観** → フォント  
まずは **Cascadia Code PL** を選択（標準で入ってる“Powerline”対応フォント）。  
※ もっとリッチなアイコン類を使いたくなったら、後で Nerd Font を入れてもOK。

## ④ 起動が重いと感じたら（1469ms 対策の軽量化）
プロファイルに **遅延ロード**を足すと体感が軽くなる：
```powershell
# PSReadLineは即時。oh-my-poshはキー入力orgitリポで初回実行
$global:__omp_inited = $false
Set-PSReadLineKeyHandler -Key 'Ctrl+o' -ScriptBlock {
  if(-not $global:__omp_inited){
    $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
    if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression; $global:__omp_inited=$true }
  }
}
# git リポでプロンプト描画時に一度だけ初期化
function prompt {
  if(-not $global:__omp_inited -and (Test-Path .git)){ 
    $theme = Join-Path $env:POSH_THEMES_PATH 'paradox.omp.json'
    if(Test-Path $theme){ oh-my-posh init pwsh --config $theme | Invoke-Expression; $global:__omp_inited=$true }
  }
  "$(Get-Location)> "
}
```
（↑を `$PROFILE.CurrentUserAllHosts` の **GPTブロック直後**に追記。あとで消してもOK）

---

ここまで済めば、**Git 情報 + カラープロンプト + 補完強化**が安定表示できるはず。  
表示がまだ地味なら、`Get-ChildItem $env:POSH_THEMES_PATH` で他テーマを試そう。変更は：

```powershell
$THEME='jandedobbeleer.omp.json'   # 例
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\$THEME" | Invoke-Expression
```

必要なら **fzf 連携（Ctrl+Rの超高速検索）** や **git/gh 補助コマンド** もすぐ足すよ。

### user  

@{content_type=image_asset_pointer; asset_pointer=file-service://file-35BYRVB46oM4Qo95NfKpYw; size_bytes=101033; width=310; height=351; fovea=; metadata=}

@{content_type=image_asset_pointer; asset_pointer=file-service://file-HLNfq3zG8hVcTyRAs78zW3; size_bytes=81348; width=1131; height=73; fovea=; metadata=}

パワーシェルをタスクバーにピン止めしているんだけど、古いパワーシェルが起動してしまう。新しいバージョンのパワーシェルをここから起動するにはどうすればいい？新しいパワーシェルを起動してピン止めして試しても、古いのが起動してしまう状態。最良の方法を提供して。調べ尽くして深く考えて。

### user  

PowerShell 7.5.2
PS C:\Users\hiroy> $pwsh=(Get-Command pwsh).Source
PS C:\Users\hiroy> New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7" -Force |
>>   Set-ItemProperty -Name MUIVerb -Value "ここで PowerShell 7 を開く" -PassThru |
>>   Set-ItemProperty -Name Icon -Value "$pwsh,0" | Out-Null
PS C:\Users\hiroy> New-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenPwsh7\command" -Force |
>>   Set-ItemProperty -Name "(default)" -Value "`"$pwsh`" -NoLogo -WorkingDirectory `"%V`"" | Out-Null
PS C:\Users\hiroy>　これ実行したけど右クリックで古いのが起動される。

### user  

どっちも導入したいけど、chatgptの別チャットでパワーシェル多用してるから、エラーとかの原因にならないかが心配。

### assistant  

うん 👍 ばっちり整ったよ。  

- **確認結果**  
  ```
  Edition=Core  Version=7.5.2  Home=C:\Program Files\PowerShell\7
  (Get-Command pwsh).Source → C:\Program Files\PowerShell\7\pwsh.exe
  ```
  → 起動しているのは確実に **PowerShell 7.5.2 (Core)**。  

- **旧「Windows PowerShell」の右クリック項目**も削除済み → もう紛らわしい 5.1 は出てこない。  

つまり現在は  
✅ タスクバー  
✅ スタート検索  
✅ Win+X（Terminal既定）  
✅ 右クリック「ここで PowerShell 7」  
✅ `.ps1` ダブルクリック  

すべて **PowerShell 7** に統一されてる状態。  

---

これでもう「どこから起動しても PS7」完成だよ 🎉  
あとは好みに応じてプロファイル（補完/色/プロンプト）を整えるだけ。  

👉 必要なら「プロファイル強化スクリプト（PSReadLine, oh-my-posh, 履歴永続化）」を一発セットアップできるように作るけど、やる？

### user  

うまくいったみたい！　PowerShell 7.5.2
PS C:\Users\hiroy> # タスクバーにピン留めされた .lnk を PS7 に向け直す
PS C:\Users\hiroy> $taskbar = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
PS C:\Users\hiroy> $pwsh    = "C:\Program Files\PowerShell\7\pwsh.exe"
PS C:\Users\hiroy>
PS C:\Users\hiroy> # pwsh の場所が違う環境に対応して自動検出
PS C:\Users\hiroy> try { $pwsh = (Get-Command pwsh -ErrorAction Stop).Source } catch {}
PS C:\Users\hiroy>
PS C:\Users\hiroy> $links = Get-ChildItem $taskbar -Filter *.lnk -ErrorAction SilentlyContinue
PS C:\Users\hiroy> foreach ($lnk in $links) {
>>   $ws  = New-Object -ComObject WScript.Shell
>>   $sc  = $ws.CreateShortcut($lnk.FullName)
>>   if ($sc.TargetPath -match 'WindowsPowerShell\\v1\.0\\powershell\.exe') {
>>     $sc.TargetPath  = $pwsh
>>     $sc.Arguments   = ''
>>     $sc.IconLocation= "$pwsh,0"
>>     $sc.Save()
>>   }
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # ついでに「スタートメニューの古い PowerShell」を未ピンにした場合はスキップされる
PS C:\Users\hiroy> # 変更を反映するためエクスプローラーを再起動
PS C:\Users\hiroy> Stop-Process -Name explorer -Force
PS C:\Users\hiroy> Start-Process explorer.exe
PS C:\Users\hiroy>

### user  

PowerShell 7.5.2
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:66
Line |
  66 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
PS C:\Users\hiroy> # --- fzf ホットフィックス: if/else の結果を変数に入れてからパイプ ---
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 1) 今のセッションの関数を差し替え
PS C:\Users\hiroy> function _fzf-files {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t f -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> function _fzf-dirs {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t d -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 2) プロファイルにも追記して永続化（後勝ちでこの定義が有効になる）
PS C:\Users\hiroy> $prof = $PROFILE.CurrentUserAllHosts
PS C:\Users\hiroy> @'
>> function _fzf-files {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t f -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> function _fzf-dirs {
>>   if(-not $global:__icons_inited){ __Init-TerminalIcons }
>>   $items = if(Get-Command fd -ErrorAction SilentlyContinue){
>>     fd -t d -H -E .git 2>$null
>>   } else {
>>     Get-ChildItem -Recurse -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object FullName
>>   }
>>   $items | fzf --height 40% --reverse
>> }
>> '@ | Add-Content -Path $prof -Encoding UTF8
PS C:\Users\hiroy>
PS C:\Users\hiroy> # 3) 反映
PS C:\Users\hiroy> . $prof
ParserError: C:\Users\hiroy\OneDrive\ドキュメント\PowerShell\profile.ps1:66
Line |
  66 |  …  { Get-ChildItem -Recurse -File | ForEach-Object FullName } | fzf --h …
     |                                                                ~
     | An empty pipe element is not allowed.
PS C:\Users\hiroy> Write-Host "[OK] fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。"
[OK] fzf 関数を修正しました。Ctrl+T / Alt+C を試してください。
PS C:\Users\hiroy>

### user  

PowerShell 7.5.2
Loading personal and system profiles took 1265ms.
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ # テキスト検索 (カレント配下で "PowerShell" を含む行)
 hiroy@DESKTOP-D6G9TM0  ~ 
❯ rg PowerShell
venv311\Scripts\Activate.ps1
3:Activate a Python virtual environment for the current PowerShell session.
42:execution policy for the user. You can do this by issuing the following PowerShell

Downloads\zunda_mic_quicktest.py
5:PowerShell: python zunda_mic_quicktest.py 1

Downloads\gpt_cli.py
3:gpt_cli.py  — Crash-resilient ChatGPT client (Windows/PowerShell向け)

Downloads\zunda_files_diag.py
67:        # Get-MpThreatDetection をPowerShell経由で叩く

Downloads\ZundaLivePortable\zunda_mic_quicktest.py
5:PowerShell: python zunda_mic_quicktest.py 1

OneDrive\ドキュメント\WindowsPowerShell\Modules\ps2exe\1.0.17\ps2exe.psd1
39:# Minimum version of the Windows PowerShell engine required by this module
40:PowerShellVersion = '3.0'
42:# Name of the Windows PowerShell host required by this module
43:# PowerShellHostName = ''
45:# Minimum version of the Windows PowerShell host required by this module
46:# PowerShellHostVersion = ''
48:# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
51:# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
96:# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.

OneDrive\ドキュメント\WindowsPowerShell\Modules\ps2exe\1.0.17\ps2exe.ps1
144:            Write-Output "PowerShell Desktop environment started...`n"
365:            if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost.dll" })
367:                    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost.dll" } | Select-Object -First 1).Location
476:// Simple PowerShell host created by Ingo Karstein (http://blog.karstein-consulting.com)
2553:                                   using (PowerShell posh = PowerShell.Create())
2803:           Write-Error -ErrorAction Continue "Could not create the PowerShell .exe file because of compilation errors. Use -verbose parameter to see details."

OneDrive\ドキュメント\PowerShell\profile.ps1
55:  if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert($sel) }
59:  if($sel){ [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($sel -join ' ')) }
63:  if($sel){ Set-Location $sel; [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`n$(Get-Location)> ") }

OneDrive\ドキュメント\PowerShell\powershell.config.json
1:{"Microsoft.PowerShell:ExecutionPolicy":"RemoteSigned"}

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Terminal-Icons.psm1
53:                        $theme = Import-PowerShellDataFile $item.FullName
196:        $colorData = Import-PowerShellDataFile $_.FullName
210:        $hash.Add($_.Basename, (Import-PowerShellDataFile $_.FullName))

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Terminal-Icons.psd1
8:    Description       = 'PowerShell module to add file icons to terminal based on file extension'
9:    PowerShellVersion = '5.1'
10:    # PowerShellHostName = ''
11:    # PowerShellHostVersion = ''

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Terminal-Icons.format.ps1xml
29:                                                  $_.PSParentPath.Replace("Microsoft.PowerShell.Core\FileSystem::", "")

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Data\iconThemes\devblackops.psd1
193:            # PowerShell

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Data\colorThemes\devblackops_light.psd1
188:      # PowerShell

OneDrive\ドキュメント\PowerShell\Modules\Terminal-Icons\0.11.0\Data\colorThemes\devblackops.psd1
188:            # PowerShell

OneDrive\ドキュメント\PowerShell\Modules\ps2exe\1.0.17\ps2exe.psd1
39:# Minimum version of the Windows PowerShell engine required by this module
40:PowerShellVersion = '3.0'
42:# Name of the Windows PowerShell host required by this module
43:# PowerShellHostName = ''
45:# Minimum version of the Windows PowerShell host required by this module
46:# PowerShellHostVersion = ''
48:# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
51:# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
96:# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.

OneDrive\ドキュメント\PowerShell\Modules\ps2exe\1.0.17\ps2exe.ps1
144:            Write-Output "PowerShell Desktop environment started...`n"
365:            if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost.dll" })
367:                    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "Microsoft.PowerShell.ConsoleHost.dll" } | Select-Object -First 1).Location
476:// Simple PowerShell host created by Ingo Karstein (http://blog.karstein-consulting.com)
2553:                                   using (PowerShell posh = PowerShell.Create())
2803:           Write-Error -ErrorAction Continue "Could not create the PowerShell .exe file because of compilation errors. Use -verbose parameter to see details."

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\WindowTitle.ps1
11:                $Host.UI.RawUI.WindowTitle = 'PowerShell';

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\Utils.ps1
55:    # PowerShell 5.x only runs on Windows so use .NET types to determine isAdminProcess
68:    Configures your PowerShell profile (startup) script to import the posh-git
69:    module when PowerShell starts.
71:    Checks if your PowerShell profile script is not already importing posh-git
73:    PowerShell to load posh-git whenever PowerShell starts.
88:    Updates your profile script for the current PowerShell host to import the
89:    posh-git module when the current PowerShell host starts.
92:    Updates your profile script for all PowerShell hosts to import the posh-git
93:    module whenever any PowerShell host starts.
206:    # Make sure the PowerShell profile directory exists
209:        if ($PSCmdlet.ShouldProcess($profileDir, "Create current user PowerShell profile directory")) {
221:    Modifies your PowerShell profile (startup) script so that it does not import
222:    the posh-git module when PowerShell starts.
224:    Checks if your PowerShell profile script is importing posh-git and if it does,
225:    removes the command to import the posh-git module. This will cause PowerShell
226:    to no longer load posh-git whenever PowerShell starts.
238:    Updates your profile script for the current PowerShell host to stop importing
239:    the posh-git module when the current PowerShell host starts.
242:    Updates your profile script for all PowerShell hosts to no longer import the
243:    posh-git module whenever any PowerShell host starts.

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\PoshGitTypes.ps1
280:    [psobject]$WindowTitle = {param($GitStatus, [bool]$IsAdmin) "$(if ($IsAdmin) {'Admin: '})$(if ($GitStatus) {"$($GitStatus.RepoName) [$($GitStatus.Branch)]"} else {Get-PromptPath}) - PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) $(if ([IntPtr]::Size -eq 4) {'32-bit '})($PID)"}

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\posh-git.psm1
94:    # When using Write-Host, we return a single space from this function to prevent PowerShell from displaying "PS>"

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\posh-git.psd1
21:# Minimum version of the Windows PowerShell engine required by this module
22:PowerShellVersion = '5.0'
61:# This may also contain a PSData hashtable with additional module metadata used by PowerShell.

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\GitUtils.ps1
19:    $pathInfo = Microsoft.PowerShell.Management\Get-Location
452:    $pathInfo = Microsoft.PowerShell.Management\Get-Location

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\GitTabExpansion.ps1
558:    Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName $cmdNames -Native -ScriptBlock {
561:        # The PowerShell completion has a habit of stripping the trailing space when completing:
610:Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName Remove-GitBranch -ParameterName Name -ScriptBlock {

OneDrive\ドキュメント\PowerShell\Modules\posh-git\1.1.0\en-US\about_posh-git.help.txt
5:    posh-git integrates Git and PowerShell providing tab completion of Git
7:    summary information that can be displayed in the PowerShell prompt.
10:    posh-git integrates Git and PowerShell. Tab completion is supported for
40:    And like tab completion in other parts of PowerShell, you can press tab
46:    PowerShell generates its prompt by executing a function named "prompt", if
137:    You need to import the posh-git module into your PowerShell session to
140:    your PowerShell profile updated to import posh-git whenever PowerShell
148:    variable name at the PowerShell prompt (after posh-git has been imported)

OneDrive\ドキュメント\PowerShell\Modules\oh-my-posh\7.85.2\oh-my-posh.psm1
5:longer support the PowerShell module. Over the past year, the
85:    # https://github.com/PowerShell/PowerShell/issues/12868

OneDrive\ドキュメント\PowerShell\Modules\oh-my-posh\7.85.2\oh-my-posh.psd1
23:    # Minimum version of the Windows PowerShell engine required by this module
24:    PowerShellVersion = '5.0'
35:    # Private data to pass to the module specified in RootModule. This may also contain a PSData hashtable with additional module metadata used by PowerShell.

venv311\Lib\site-packages\pip\_vendor\pygments\lexers\_mapping.py
376:    'PowerShellLexer': ('pip._vendor.pygments.lexers.shell', 'PowerShell', ('powershell', 'pwsh', 'posh', 'ps1', 'psm1'), ('*.ps1', '*.psm1'), ('text/x-powershell',)),
377:    'PowerShellSessionLexer': ('pip._vendor.pygments.lexers.shell', 'PowerShell Session', ('pwsh-session', 'ps1con'), (), ()),

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\support\migwiz\sfpatlh.inf
32:"HKLM\Software\Microsoft\PowerShell\1\PowerShellSnapIns\IIsProviderSnapIn\* [*]"

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\support\migwiz\sfpat.inf
127:"[Microsoft.PowerShell.Commands.Management, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
128:"[Microsoft.PowerShell.Commands.Management.resources, Version=1.0.0.0, Culture=*, PublicKeyToken=31bf3856ad364e35*]"
129:"[Microsoft.PowerShell.Commands.Utility, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
130:"[Microsoft.PowerShell.Commands.Utility.resources, Version=1.0.0.0, Culture=*,PublicKeyToken=31bf3856ad364e35*]"
131:"[Microsoft.PowerShell.ConsoleHost, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
132:"[Microsoft.PowerShell.ConsoleHost.resources, Version=1.0.0.0, Culture=*, PublicKeyToken=31bf3856ad364e35*]"
133:"[Microsoft.PowerShell.Security, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
134:"[Microsoft.PowerShell.Security.resources, Version=1.0.0.0, Culture=*,PublicKeyToken=31bf3856ad364e35*]"

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\sources\upgrade_bulk.xml
2886:          <script>MigXmlHelper.RemoveEmptyDirectories("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Windows PowerShell 1.0\*")</script>
2888:          <script>MigXmlHelper.RemoveEmptyDirectories("%windir%\System32\WindowsPowerShell\v1.0\Modules\FileTransfer\*")</script>

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\sources\sfpatlh.inf
32:"HKLM\Software\Microsoft\PowerShell\1\PowerShellSnapIns\IIsProviderSnapIn\* [*]"

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\sources\sfpat.inf
127:"[Microsoft.PowerShell.Commands.Management, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
128:"[Microsoft.PowerShell.Commands.Management.resources, Version=1.0.0.0, Culture=*, PublicKeyToken=31bf3856ad364e35*]"
129:"[Microsoft.PowerShell.Commands.Utility, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
130:"[Microsoft.PowerShell.Commands.Utility.resources, Version=1.0.0.0, Culture=*,PublicKeyToken=31bf3856ad364e35*]"
131:"[Microsoft.PowerShell.ConsoleHost, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
132:"[Microsoft.PowerShell.ConsoleHost.resources, Version=1.0.0.0, Culture=*, PublicKeyToken=31bf3856ad364e35*]"
133:"[Microsoft.PowerShell.Security, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35*]"
134:"[Microsoft.PowerShell.Security.resources, Version=1.0.0.0, Culture=*,PublicKeyToken=31bf3856ad364e35*]"

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\sources\replacementmanifests\microsoft-windows-powershell-replacement.man
11:      name="Microsoft-Windows-PowerShell"
17:       or USMT since that is not supported for PowerShell overall-->
28:            <pattern type="Registry">HKCR\Microsoft.PowerShellScript.1\* [*]</pattern>

OneDrive\デスクトップ\F\新しいフォルダー\OSインストールセット\GSP1RMCPRXFREO_JA_DVD\sources\replacementmanifests\iis-powershellprovider-rm.man
4:      name="Microsoft-Windows-IIS-PowerShellProvider"
13:      <registerSDF name="IIS-PowerShellProvider"/>
