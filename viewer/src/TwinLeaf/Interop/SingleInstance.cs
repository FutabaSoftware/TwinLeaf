using System;
using System.Threading;

namespace TwinLeaf.Interop
{
    // シンプルな単一インスタンス確保ヘルパー（Mutexのみ）
    internal static class SingleInstance
    {
        private const string MutexName = "TwinLeaf_SingleInstance_Mutex";

        public static bool TryAcquire(out Mutex? mutex)
        {
            mutex = null;
            try
            {
                bool createdNew;
                var m = new Mutex(true, MutexName, out createdNew);
                if (!createdNew)
                {
                    m.Dispose();
                    return false;
                }
                mutex = m;
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static void Release(Mutex? mutex)
        {
            try
            {
                if (mutex != null)
                {
                    mutex.ReleaseMutex();
                    mutex.Dispose();
                }
            }
            catch
            {
                // 無視
            }
        }
    }
}