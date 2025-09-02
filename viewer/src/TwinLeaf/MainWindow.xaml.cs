using System;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;
using Microsoft.Web.WebView2.Core;

namespace TwinLeaf;

public partial class MainWindow : Window
{
    private static readonly Uri ExternalHome = new("https://www.bing.com/");

    private const string LocalHomeHtml = @"<!doctype html>
<html lang='ja'>
<meta charset='utf-8'>
<meta http-equiv='X-UA-Compatible' content='IE=edge'>
<meta name='viewport' content='width=device-width,initial-scale=1'>
<title>TwinLeaf Home</title>
<style>
  html,body{height:100%;margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,'Noto Sans JP',sans-serif;background:#0b0f14;color:#e6e6e6}
  .wrap{height:100%;display:flex;align-items:center;justify-content:center}
  .card{width:min(680px,92%);padding:32px 24px;border-radius:14px;background:#121821;border:1px solid #1f2835;box-shadow:0 10px 30px rgba(0,0,0,.35)}
  h1{margin:0 0 16px;font-size:18px;letter-spacing:.4px;color:#9ad6ff}
  form{display:flex;gap:8px}
  input[type=text]{flex:1;font-size:16px;padding:12px 14px;border-radius:10px;border:1px solid #2a3648;background:#0e141c;color:#e6e6e6;outline:none}
  input[type=text]::placeholder{color:#8aa0b6}
  button{padding:12px 16px;border-radius:10px;border:1px solid #2a3648;background:#1b2736;color:#e6e6e6;font-size:14px;cursor:pointer}
  .hint{margin-top:10px;color:#8aa0b6;font-size:12px}
</style>
<div class='wrap'>
  <div class='card'>
    <h1>🔎 TwinLeaf — Quick Search</h1>
    <form onsubmit=""const q=document.getElementById('q').value.trim();
                       const url=q?(q.includes('://')||q.includes('.')?('https://'+q).replace(/^https?:\/\//,'https://'):'https://www.bing.com/search?q='+encodeURIComponent(q)):'https://www.bing.com/';
                       window.location.href=url; return false;"">
      <input id='q' type='text' placeholder='検索ワード or URL を入力して Enter' autofocus>
      <button type='submit'>Go</button>
    </form>
    <div class='hint'>Tips: スペースがあれば検索 / ドメインっぽければURLとして開きます。</div>
  </div>
</div>
</html>";

    private bool _isLocalHomeShown = false;

    public MainWindow()
    {
        InitializeComponent();

        this.Loaded += async (_, __) =>
        {
            try
            {
                App.Log("InitWebView start");
                if (App.WebEnv != null) await _web.EnsureCoreWebView2Async(App.WebEnv);
                else await _web.EnsureCoreWebView2Async();

                _web.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
                _web.CoreWebView2.Settings.AreDevToolsEnabled = true;

                _web.NavigationStarting += (_, e) =>
                {
                    if (!_isLocalHomeShown) Dispatcher.Invoke(() => AddressBar.Text = e.Uri);
                };
                _web.NavigationCompleted += (_, e) =>
                {
                    if (!_isLocalHomeShown) try { AddressBar.Text = _web.Source?.ToString() ?? ""; } catch { }
                };

                if (!string.IsNullOrWhiteSpace(App.StartupUrl))
                {
                    NavigateTo(App.StartupUrl!);
                }
                else
                {
                    ShowLocalHome();
                }

                App.Log("InitWebView ok");
            }
            catch (Exception ex)
            {
                App.Log("InitWebView ERR: " + ex);
                MessageBox.Show("WebView2 の初期化に失敗しました。\n" + ex.Message,
                    "TwinLeaf", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        };
    }

    private void ShowLocalHome()
    {
        try
        {
            _isLocalHomeShown = true;
            _web.NavigateToString(LocalHomeHtml);
            AddressBar.Text = "home:local";
        }
        catch { _isLocalHomeShown = false; _web.Source = ExternalHome; }
    }

    // Toolbar handlers
    private void Home_Click(object sender, RoutedEventArgs e)     => ShowLocalHome();
    private void Reload_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            if (_isLocalHomeShown) ShowLocalHome();
            else _web.Reload();
        }
        catch { }
    }
    private void Back_Click(object sender, RoutedEventArgs e)     { try { if (_web.CanGoBack) _web.GoBack(); } catch { } }
    private void Forward_Click(object sender, RoutedEventArgs e)  { try { if (_web.CanGoForward) _web.GoForward(); } catch { } }
    private void Go_Click(object sender, RoutedEventArgs e)       => NavigateTo(AddressBar.Text);

    private void AddressBar_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) { e.Handled = true; NavigateTo(AddressBar.Text); }
    }

    // 追加：キャッシュクリア＆再起動
    private void ClearCache_Click(object sender, RoutedEventArgs e)
    {
        var ans = MessageBox.Show(
            "WebView2 のキャッシュを削除して TwinLeaf を再起動します。\nよろしいですか？",
            "TwinLeaf", MessageBoxButton.YesNo, MessageBoxImage.Question);
        if (ans != MessageBoxResult.Yes) return;

        try
        {
            var exe = Process.GetCurrentProcess().MainModule?.FileName ?? "";
            var args = $"--profile {App.Profile} --reset-cache";
            Process.Start(new ProcessStartInfo(exe, args){ UseShellExecute = false });
        }
        catch { /* ignore */ }
        Application.Current.Shutdown();
    }

    // 外部から呼ばれる
    public void NavigateFromExternal(string? input)
    {
        _isLocalHomeShown = false;
        NavigateTo(input);
    }

    public void BringToFront()
    {
        try
        {
            if (WindowState == WindowState.Minimized) WindowState = WindowState.Normal;
            Activate();
            Topmost = true; Topmost = false;
        }
        catch { }
    }

    public void NavigateTo(string? input)
    {
        try
        {
            _isLocalHomeShown = false;
            var url = NormalizeToUrl(input ?? "");
            _web.Source = new Uri(url);
            AddressBar.Text = url;
        }
        catch
        {
            ShowLocalHome();
        }
    }

    private static string NormalizeToUrl(string s)
    {
        s = s.Trim();
        if (string.IsNullOrEmpty(s)) return ExternalHome.ToString();
        if (s.Contains(" ")) return $"https://www.bing.com/search?q={Uri.EscapeDataString(s)}";
        if (Regex.IsMatch(s, @"^[a-zA-Z][a-zA-Z0-9+\-.]*://")) return s;
        return "https://" + s;
    }
}
