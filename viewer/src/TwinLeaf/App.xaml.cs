using System;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.Web.WebView2.Core;

namespace TwinLeaf;

public partial class App : Application
{
    public static string Profile = "default";
    public static string BaseDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TwinLeaf");
    public static string LogPath => Path.Combine(BaseDir, "run.log");
    public static CoreWebView2Environment? WebEnv;
    public static string? StartupUrl;

    private static bool ResetCache = false;
    private static bool ExitRequest = false;

    private static Mutex? _singleMutex;
    private static readonly string _userSid = WindowsIdentity.GetCurrent().User?.Value ?? "nouser";
    private static string MutexName => $"TwinLeaf_Mutex_{_userSid}";
    private static string PipeName  => $"TwinLeaf_Pipe_{_userSid}";

    public static MainWindow? MainWin;

    protected override void OnStartup(StartupEventArgs e)
    {
        Directory.CreateDirectory(BaseDir);
        Log($"=== start {DateTime.Now:yyyy-MM-dd HH:mm:ss} ===");
        Log($"args : {string.Join(' ', e.Args)}");

        // 引数処理
        for (int i = 0; i < e.Args.Length; i++)
        {
            var a = e.Args[i];
            if (a == "--profile" && i + 1 < e.Args.Length) Profile = e.Args[++i];
            else if (a == "--url" && i + 1 < e.Args.Length) StartupUrl = e.Args[++i];
            else if (a == "--reset-cache") ResetCache = true;
            else if (a == "--exit") ExitRequest = true;
        }

        // 単一インスタンス
        bool createdNew;
        _singleMutex = new Mutex(true, MutexName, out createdNew);
        if (!createdNew)
        {
            try
            {
                if (ExitRequest)
                {
                    SendToPrimary("EXIT");
                }
                else
                {
                    string? url = ExtractUrlFromArgs(e.Args);
                    SendToPrimary(url);
                }
            }
            catch (Exception ex) { Log("Handoff ERR: " + ex); }
            Environment.Exit(0);
            return;
        }

        // WebView2 ユーザーデータ
        string userDataFolder = Path.Combine(BaseDir, Profile, "WebView2");
        if (ResetCache)
        {
            try
            {
                Log($"ResetCache: deleting {userDataFolder}");
                SafeDeleteDirectory(userDataFolder);   // ← 改良点：安全再帰削除（失敗はログしてスキップ）
            }
            catch (Exception ex) { Log("ResetCache ERR(top): " + ex); }
        }
        Directory.CreateDirectory(userDataFolder);
        Log($"UserDataFolder: {userDataFolder}");

        try
        {
            var opts = new CoreWebView2EnvironmentOptions();
            WebEnv = CoreWebView2Environment.CreateAsync(null, userDataFolder, opts).GetAwaiter().GetResult();
        }
        catch (Exception ex) { Log("CreateEnvironment ERR: " + ex); }

        base.OnStartup(e);

        var win = new MainWindow();
        MainWin = win;
        win.Show();

        // Pipeサーバ起動
        StartPipeServer();

        // 初回URLがあれば遷移
        if (!string.IsNullOrWhiteSpace(StartupUrl))
            try { MainWin?.NavigateFromExternal(StartupUrl!); } catch { }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        Log($"=== exit {DateTime.Now:yyyy-MM-dd HH:mm:ss} ===");
        _singleMutex?.ReleaseMutex();
        _singleMutex?.Dispose();
        base.OnExit(e);
    }

    public static void Log(string msg)
    {
        try { File.AppendAllText(LogPath, msg + Environment.NewLine); } catch { }
    }

    private static string? ExtractUrlFromArgs(string[] args)
    {
        for (int i = 0; i < args.Length; i++)
        {
            var a = args[i];
            if (a == "--url" && i + 1 < args.Length) return args[i + 1];
            if (LooksLikeUrl(a)) return a;
        }
        return null;
    }

    private static bool LooksLikeUrl(string s)
    {
        if (string.IsNullOrWhiteSpace(s)) return false;
        if (s.Contains(" ")) return false;
        return s.Contains("://") || s.Contains('.') || s.StartsWith("about:", StringComparison.OrdinalIgnoreCase);
    }

    private static void SendToPrimary(string? payload)
    {
        using var client = new NamedPipeClientStream(".", PipeName, PipeDirection.Out, PipeOptions.Asynchronous);
        client.Connect(1000);
        using var w = new StreamWriter(client, new UTF8Encoding(false)) { AutoFlush = true };
        w.WriteLine(payload ?? "");
    }

    private static void StartPipeServer()
    {
        Task.Run(async () =>
        {
            while (true)
            {
                try
                {
                    using var server = new NamedPipeServerStream(PipeName, PipeDirection.In, 1,
                        PipeTransmissionMode.Byte, PipeOptions.Asynchronous);
                    await server.WaitForConnectionAsync();
                    using var r = new StreamReader(server, Encoding.UTF8);
                    var line = await r.ReadLineAsync();

                    Current?.Dispatcher.Invoke(() =>
                    {
                        try
                        {
                            if (line != null && line.Trim().Equals("EXIT", StringComparison.OrdinalIgnoreCase))
                            {
                                Log("Pipe: EXIT received");
                                Current?.Shutdown();
                                return;
                            }

                            if (MainWin != null)
                            {
                                MainWin.BringToFront();
                                if (!string.IsNullOrWhiteSpace(line))
                                    MainWin.NavigateFromExternal(line!);
                            }
                        }
                        catch (Exception ex) { Log("Pipe dispatch ERR: " + ex); }
                    });
                }
                catch (Exception ex)
                {
                    Log("Pipe server ERR: " + ex);
                    await Task.Delay(500);
                }
            }
        });
    }

    // ===== 安全削除ユーティリティ（ここから） =====

    // ディレクトリ以下を「可能な範囲で」削除する。失敗はログしてスキップ。
    private static void SafeDeleteDirectory(string dir)
    {
        if (!Directory.Exists(dir)) return;

        // ファイル削除
        foreach (var file in EnumerateSafe(() => Directory.EnumerateFiles(dir)))
            SafeDeleteFile(file);

        // サブディレクトリ再帰
        foreach (var sub in EnumerateSafe(() => Directory.EnumerateDirectories(dir)))
            SafeDeleteDirectory(sub);

        // 自身の削除（空でなくても Directory.Delete(dir, true) を使わない）
        TryDeleteDirectory(dir);
    }

    private static void SafeDeleteFile(string path)
    {
        // ReadOnly 属性を落としてから削除
        try
        {
            var attr = File.GetAttributes(path);
            if ((attr & FileAttributes.ReadOnly) != 0)
                File.SetAttributes(path, attr & ~FileAttributes.ReadOnly);
        }
        catch { /* 属性取得失敗は無視 */ }

        for (int i = 0; i < 5; i++)
        {
            try
            {
                File.Delete(path);
                return;
            }
            catch (IOException)                { Thread.Sleep(200); }
            catch (UnauthorizedAccessException){ Thread.Sleep(200); }
            catch (Exception ex) { Log($"ResetCache File ERR: {path} {ex.GetType().Name}"); return; }
        }
        Log("ResetCache File SKIP (locked): " + path);
    }

    private static void TryDeleteDirectory(string dir)
    {
        for (int i = 0; i < 5; i++)
        {
            try
            {
                // ここでは中身を消し終えている前提なので false
                Directory.Delete(dir, false);
                return;
            }
            catch (IOException)                { Thread.Sleep(200); }
            catch (UnauthorizedAccessException){ Thread.Sleep(200); }
            catch (Exception ex) { Log($"ResetCache Dir ERR: {dir} {ex.GetType().Name}"); return; }
        }
        // 中に誰かが作った残骸が居る等で空でなければ、最終フォールバックで再帰削除を試す
        try { Directory.Delete(dir, true); } catch { /* 最終失敗は黙ってスキップ */ }
    }

    // 列挙時の例外を吸収して空列挙を返す
    private static System.Collections.Generic.IEnumerable<string> EnumerateSafe(Func<System.Collections.Generic.IEnumerable<string>> f)
    {
        try { return f(); } catch { return Array.Empty<string>(); }
    }
}
