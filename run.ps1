# --- run.ps1 (project-root 蟆ら畑繝ｻ繝ｭ繧ｰ縺ｯ蟶ｸ縺ｫ繝励Ο繧ｸ繧ｧ繧ｯ繝育峩荳九↓菴懈・) ---
$ErrorActionPreference = 'Stop'

# 1) 繝励Ο繧ｸ繧ｧ繧ｯ繝医Ν繝ｼ繝茨ｼ・sproj繧定・蜍戊ｧ｣豎ｺ・亥､ｧ蟆乗枚蟄怜ｷｮ繧ょ精蜿趣ｼ・$projRoot = Split-Path -Parent $PSCommandPath
if (-not $projRoot) { $projRoot = (Get-Location).Path }

$csproj = Get-ChildItem -Path $projRoot -Filter *.csproj | Select-Object -First 1
if (-not $csproj) { throw "縺薙・繝輔か繝ｫ繝縺ｫ .csproj 縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ・・projRoot" }

# 2) 繝ｭ繧ｰ險ｭ螳夲ｼ亥ｸｸ縺ｫ繝励Ο繧ｸ繧ｧ繧ｯ繝育峩荳具ｼ・$log = Join-Path $projRoot 'run.log'
"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] run.ps1 start" | Out-File -FilePath $log -Encoding UTF8

# 3) 繝薙Ν繝会ｼ・elease・・"[$(Get-Date -Format 'HH:mm:ss')] build start: $($csproj.Name)" | Out-File $log -Append
dotnet build $csproj.FullName -c Release | Tee-Object -FilePath $log -Append | Out-Null
"[$(Get-Date -Format 'HH:mm:ss')] build done" | Out-File $log -Append

# 4) 螳溯｡後ヵ繧｡繧､繝ｫ縺ｮ迚ｹ螳・$exe = Join-Path $projRoot 'bin\Release\net8.0-windows\TwinLeafApp.exe'
if (-not (Test-Path $exe)) { throw "EXE 縺瑚ｦ九▽縺九ｊ縺ｾ縺帙ｓ・・exe" }

# 5) 譌｢蟄倥・繝ｭ繧ｻ繧ｹ繧呈祉髯､・井ｻｻ諢擾ｼ壹さ繝｡繝ｳ繝医い繧ｦ繝亥庄・・Get-Process TwinLeafApp -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 6) 蠑墓焚繧偵◎縺ｮ縺ｾ縺ｾ霆｢騾・ｼ育┌縺代ｌ縺ｰ --profile default・・$appArgs = if ($args.Count) { $args -join ' ' } else { '--profile default' }
"[$(Get-Date -Format 'HH:mm:ss')] run: $exe $appArgs" | Out-File $log -Append

# 7) 襍ｷ蜍包ｼ磯撼蜷梧悄・峨ょ､ｱ謨励＠縺溘ｉ萓句､問・繝ｭ繧ｰ縺ｫ霈峨ｋ
$proc = Start-Process -FilePath $exe -ArgumentList $appArgs -PassThru

# 8) 繝ｭ繧ｰ繧定・蜍輔〒髢九￥・医・繝ｭ繧ｸ繧ｧ繧ｯ繝育峩荳九・ run.log 繧帝幕縺擾ｼ・Start-Process notepad $log

