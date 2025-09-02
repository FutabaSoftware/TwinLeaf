$tool = "C:\Users\hiroy\Desktop\project-root\tools\Add-TwinLeaf-Utils.ps1"

$code = @'
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [switch]$Apply,
  [switch]$Build
)

# --- helpers -------------------------------------------------------
function Write-Step($msg){ Write-Host "[STEP] $msg" -ForegroundColor Cyan }
function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor DarkCyan }
function Write-Ok  ($msg){ Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Dr  ($msg){ Write-Host "[DRY]  $msg" -ForegroundColor Yellow }

function Ensure-Dir {
  param([string]$Path,[switch]$Do)
  if(Test-Path $Path){ return }
  if($Do){ New-Item -ItemType Directory -Force $Path | Out-Null; Write-Ok "mkdir $Path" }
  else   { Write-Dr "mkdir $Path" }
}

function Ensure-File {
  param([string]$Path,[string]$Content,[switch]$Do)
  if(Test-Path $Path){ Write-Info "exists: $Path"; return }
  if($Do){ $Content | Set-Content -LiteralPath $Path -Encoding UTF8; Write-Ok "create $Path" }
  else   { Write-Dr "create $Path" }
}

function Get-TwinLeafPaths {
  param([string]$Root)
  $projDir = Join-Path $Root "viewer\src\TwinLeaf"
  [pscustomobject]@{
    ProjDir   = $projDir
    UtilsDir  = Join-Path $projDir "Utils"
    LoggerCs  = Join-Path $projDir "Utils\Logger.cs"
    ThrottleCs= Join-Path $projDir "Utils\ThrottleDispatcher.cs"
    Csproj    = Join-Path $projDir "TwinLeaf.csproj"
  }
}

# --- contents ------------------------------------------------------
$loggerCs = @"
using System;
using System.IO;
using System.Text;
using System.Threading;

namespace TwinLeaf.Utils
{
    /// <summary>
    /// Very light file logger with simple rotation (2 MB).
    /// Thread-safe, UTF-8 (BOMなし), call-safe from any thread.
    /// </summary>
    public static class Logger
    {
        private static readonly object _sync = new object();
        private static string _logPath;

        public static void Init(string appName, string? baseDir = null)
        {
            var dir = baseDir ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), appName);
            Directory.CreateDirectory(dir);
            _logPath = Path.Combine(dir, "run.log");
            WriteLine("=== logger init " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        }

        public static void WriteLine(string message)
        {
            try
            {
                lock (_sync)
                {
                    if (string.IsNullOrEmpty(_logPath))
                    {
                        // default fallback location if Init() not called
                        var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TwinLeaf");
                        Directory.CreateDirectory(dir);
                        _logPath = Path.Combine(dir, "run.log");
                    }

                    RotateIfNeeded(_logPath, 2 * 1024 * 1024); // 2MB
                    var line = message?.Replace("\r","").Replace("\n"," ") ?? "";
                    File.AppendAllText(_logPath, line + Environment.NewLine, new UTF8Encoding(false));
                }
            }
            catch { /* swallow to never crash app on logging */ }
        }

        private static void RotateIfNeeded(string path, long maxBytes)
        {
            try
            {
                var fi = new FileInfo(path);
                if (fi.Exists && fi.Length > maxBytes)
                {
                    var bak = path + "." + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".bak";
                    File.Copy(path, bak, true);
                    File.WriteAllText(path, string.Empty, new UTF8Encoding(false));
                }
            }
            catch { }
        }
    }
}
"@

$throttleCs = @"
using System;
using System.Threading;
using System.Threading.Tasks;

namespace TwinLeaf.Utils
{
    /// <summary>
    /// Simple debounce/throttle helper for async or sync actions.
    /// Usage: var d = new ThrottleDispatcher(250); d.Debounce(() => DoWork());
    /// </summary>
    public sealed class ThrottleDispatcher : IDisposable
    {
        private readonly int _delayMs;
        private int _version;
        private CancellationTokenSource? _cts;

        public ThrottleDispatcher(int delayMs = 250)
        {
            _delayMs = Math.Max(0, delayMs);
        }

        public void Debounce(Action action)
        {
            var v = Interlocked.Increment(ref _version);
            _cts?.Cancel();
            var cts = new CancellationTokenSource();
            _cts = cts;

            Task.Run(async () =>
            {
                try
                {
                    await Task.Delay(_delayMs, cts.Token).ConfigureAwait(false);
                    if (v == _version && !cts.IsCancellationRequested)
                        action();
                }
                catch (OperationCanceledException) { }
            });
        }

        public void Debounce(Func<Task> actionAsync)
        {
            var v = Interlocked.Increment(ref _version);
            _cts?.Cancel();
            var cts = new CancellationTokenSource();
            _cts = cts;

            Task.Run(async () =>
            {
                try
                {
                    await Task.Delay(_delayMs, cts.Token).ConfigureAwait(false);
                    if (v == _version && !cts.IsCancellationRequested)
                        await actionAsync().ConfigureAwait(false);
                }
                catch (OperationCanceledException) { }
            });
        }

        public void Dispose()
        {
            _cts?.Cancel();
            _cts?.Dispose();
        }
    }
}
"@

# --- main ----------------------------------------------------------
Write-Step "resolve paths"
$paths = Get-TwinLeafPaths -Root $Root
if(-not (Test-Path $paths.ProjDir)){ throw "Project dir not found: $($paths.ProjDir)" }
if(-not (Test-Path $paths.Csproj)){ throw "csproj not found: $($paths.Csproj)" }

Write-Info ("ProjDir   : {0}" -f $paths.ProjDir)
Write-Info ("UtilsDir  : {0}" -f $paths.UtilsDir)
Write-Info ("Logger.cs : {0}" -f $paths.LoggerCs)
Write-Info ("Throttle  : {0}" -f $paths.ThrottleCs)
Write-Host  ("Apply     : {0}" -f $Apply.IsPresent)
Write-Host  ("Build     : {0}" -f $Build.IsPresent)

Write-Step "ensure Utils folder and files"
Ensure-Dir  -Path $paths.UtilsDir -Do:$Apply
Ensure-File -Path $paths.LoggerCs   -Content $loggerCs   -Do:$Apply
Ensure-File -Path $paths.ThrottleCs -Content $throttleCs -Do:$Apply

# SDK-style csproj は既定で **/*.cs を自動包含するため編集不要。
# 念のため存在チェックのみ
Write-Info "csproj auto-includes *.cs (no edit required): $($paths.Csproj)"

if($Build){
  Write-Step "dotnet build (Release)"
  $csproj = $paths.Csproj
  $p = Start-Process -FilePath "dotnet" -ArgumentList @("build", "`"$csproj`"", "-c", "Release") -PassThru -NoNewWindow -Wait
  if($p.ExitCode -ne 0){ throw "dotnet build failed ($($p.ExitCode))" }
  Write-Ok "build succeeded"
}

Write-Ok "done"
'@

# ASCIIで保存
Set-Content -LiteralPath $tool -Value $code -Encoding ascii
Write-Host "Saved: $tool"
