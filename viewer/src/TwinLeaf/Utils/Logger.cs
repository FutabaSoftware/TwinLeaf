using System;
using System.IO;

namespace TwinLeaf.Utils
{
    internal static class Logger
    {
        private static readonly object _lock = new object();
        private static readonly string LogDir =
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TwinLeaf");
        private static readonly string LogPath = Path.Combine(LogDir, "run.log");

        public static string LogFilePath => LogPath;

        public static void Info(string message)  => Write("INFO",  message);
        public static void Warn(string message)  => Write("WARN",  message);
        public static void Error(string message) => Write("ERROR", message);

        public static void Error(Exception ex, string? message = null)
        {
            var body = (message == null) ? ex.ToString() : (message + " | " + ex);
            Write("ERROR", body);
        }

        private static void Write(string level, string message)
        {
            try
            {
                Directory.CreateDirectory(LogDir);
                var line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {level} {message}";
                lock (_lock)
                {
                    File.AppendAllText(LogPath, line + Environment.NewLine);
                }
            }
            catch
            {
                // ログ失敗は黙殺（アプリ動作を止めない）
            }
        }
    }
}