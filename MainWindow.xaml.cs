using System;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;
using Microsoft.Web.WebView2.Core;

namespace TwinLeaf;

public partial class MainWindow : Window
{
    private static readonly Uri HomeUri = new("https://www.bing.com/");

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

                _web.NavigationStarting += (_, e) => Dispatcher.Invoke(() => AddressBar.Text = e.Uri);
                _web.NavigationCompleted += (_, e) =>
                {
                    try { AddressBar.Text = _web.Source?.ToString() ?? ""; } catch { }
                };

                if (!string.IsNullOrWhiteSpace(App.StartupUrl))
                    NavigateTo(App.StartupUrl!);
                else if (_web.Source == null)
                    _web.Source = HomeUri;

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

    // Toolbar handlers
    private void Home_Click(object sender, RoutedEventArgs e)     => NavigateTo(HomeUri.ToString());
    private void Reload_Click(object sender, RoutedEventArgs e)   { try { _web.Reload(); } catch { } }
    private void Back_Click(object sender, RoutedEventArgs e)     { try { if (_web.CanGoBack) _web.GoBack(); } catch { } }
    private void Forward_Click(object sender, RoutedEventArgs e)  { try { if (_web.CanGoForward) _web.GoForward(); } catch { } }
    private void Go_Click(object sender, RoutedEventArgs e)       => NavigateTo(AddressBar.Text);

    private void AddressBar_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) { e.Handled = true; NavigateTo(AddressBar.Text); }
    }

    // 外部から呼べる公開メソッド
    public void NavigateFromExternal(string? input) => NavigateTo(input);

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
            var url = NormalizeToUrl(input ?? "");
            _web.Source = new Uri(url);
        }
        catch { /* 無効な文字列は無視 */ }
    }

    private static string NormalizeToUrl(string s)
    {
        s = s.Trim();
        if (string.IsNullOrEmpty(s)) return HomeUri.ToString();
        if (s.Contains(" ")) return $"https://www.bing.com/search?q={Uri.EscapeDataString(s)}";
        if (Regex.IsMatch(s, @"^[a-zA-Z][a-zA-Z0-9+\-.]*://")) return s;
        return "https://" + s;
    }
}
