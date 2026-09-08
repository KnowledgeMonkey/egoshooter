using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;

internal static class ServerLauncher
{
    private static volatile bool stopping;
    private static string stopFile;

    private static int Main(string[] args)
    {
        Console.OutputEncoding = Encoding.UTF8;
        if (Array.IndexOf(args, "--help") >= 0 || Array.IndexOf(args, "-h") >= 0)
        {
            Console.WriteLine("BLOCKLINE Dedicated Server - Windows x64\n" +
                "Start-Server.exe [--config=C:\\Pfad\\server.json] [Optionen]\n" +
                "Optionen ueberschreiben die JSON-Datei fuer diesen Start:\n" +
                "  --name=MeinServer  --bind=0.0.0.0  --port=27840\n" +
                "  --mode=TDM|FFA  --max-players=8  --bots=8  --difficulty=0..3\n" +
                "  --score-limit=50  --time-limit=600  --round-delay=10\n" +
                "  --discovery=true|false  --run-for=Sekunden (optionaler Testlauf)\n" +
                "Bots fuellen bis zur angegebenen Gesamtspielerzahl auf.\n" +
                "Zeitangaben in Sekunden. Stoppen: Ctrl+C oder stop + Enter.\n" +
                "Ohne Optionen wird server.json neben der EXE verwendet.");
            return 0;
        }
        string root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
        string logs = Path.Combine(root, "logs");
        try
        {
            Directory.CreateDirectory(logs);
            File.WriteAllText(Path.Combine(logs, ".gdignore"), "");
            string engine = Path.Combine(root, "tools", "godot", "Godot_v4.5-stable_win64.exe");
            if (!File.Exists(engine) || !File.Exists(Path.Combine(root, "project.godot")))
                throw new IOException("Spielprojekt oder Engine fehlt. Bitte das gesamte Server-ZIP entpacken.");
            string config = Path.Combine(root, "server.json");
            var forwarded = new List<string>();
            foreach (string arg in args)
            {
                if (arg.StartsWith("--config=")) config = Path.GetFullPath(arg.Substring(9));
                else if (arg.StartsWith("--stop-file=") || arg == "--dedicated")
                    throw new ArgumentException("Reservierte Option: " + arg);
                else forwarded.Add(arg);
            }
            if (!File.Exists(config)) throw new FileNotFoundException("server.json fehlt: " + config);
            string session = DateTime.Now.ToString("yyyyMMdd-HHmmss") + "-" + Process.GetCurrentProcess().Id;
            stopFile = Path.Combine(logs, "server-" + session + ".stop");
            Console.CancelKeyPress += delegate(object sender, ConsoleCancelEventArgs e) { e.Cancel = true; RequestStop(); };
            Console.WriteLine("BLOCKLINE Dedicated Server\nKonfiguration: " + config + "\nProtokolle: " + logs);
            using (var job = new ChildJob())
            {
                Console.WriteLine("Pruefe Spielressourcen ...");
                string importLog = Path.Combine(logs, "server-import-" + session + ".log");
                int imported = Run(engine, "--headless --editor --import --quit --path " + Quote(root) +
                    " --log-file " + Quote(importLog), root, job, 180000, false);
                if (imported != 0 || stopping) return imported == 0 ? 0 : 1;
                string content = File.Exists(importLog) ? File.ReadAllText(importLog) : "SCRIPT ERROR: missing log";
                if (content.Contains("SCRIPT ERROR:") || content.Contains("Failed to load"))
                    throw new IOException("Ressourcenimport fehlgeschlagen. Details: " + importLog);
                string command = "--headless --max-fps 60 --path " + Quote(root) + " --log-file " +
                    Quote(Path.Combine(logs, "server-" + session + ".log")) + " -- --dedicated " +
                    Quote("--config=" + config) + " " + Quote("--stop-file=" + stopFile);
                foreach (string arg in forwarded) command += " " + Quote(arg);
                var input = new Thread(delegate()
                {
                    try
                    {
                        string line;
                        while ((line = Console.ReadLine()) != null)
                        {
                            if (line.Trim().Equals("stop", StringComparison.OrdinalIgnoreCase)) { RequestStop(); break; }
                            Console.WriteLine("Befehl: stop + Enter. Status wird alle 10 Sekunden ausgegeben.");
                        }
                    }
                    catch (IOException) { }
                });
                input.IsBackground = true;
                input.Start();
                return Run(engine, command, root, job, 0, true);
            }
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("SERVER START ERROR: " + error.Message);
            return 1;
        }
        finally
        {
            if (stopFile != null) { try { File.Delete(stopFile); } catch { } }
        }
    }

    private static void RequestStop()
    {
        if (stopping) return;
        stopping = true;
        Console.WriteLine("Server wird beendet ...");
        try { if (stopFile != null) File.WriteAllText(stopFile, "stop"); } catch { }
    }

    private static int Run(string executable, string arguments, string root, ChildJob job, int timeout, bool server)
    {
        var info = new ProcessStartInfo(executable, arguments) { WorkingDirectory = root,
            UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
        using (var child = new Process { StartInfo = info })
        {
            child.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { if (server && e.Data != null) Console.WriteLine(e.Data); };
            child.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { if (e.Data != null) Console.Error.WriteLine(e.Data); };
            child.Start();
            try { job.Assign(child); } catch { child.Kill(); throw; }
            child.BeginOutputReadLine();
            child.BeginErrorReadLine();
            var timer = Stopwatch.StartNew();
            Stopwatch shutdown = null;
            while (!child.WaitForExit(100))
            {
                if (stopping && shutdown == null) shutdown = Stopwatch.StartNew();
                if ((timeout > 0 && timer.ElapsedMilliseconds > timeout) ||
                    (shutdown != null && (!server || shutdown.ElapsedMilliseconds > 10000)))
                {
                    child.Kill();
                    child.WaitForExit();
                    if (stopping) return 0;
                    throw new TimeoutException("Ressourcenimport hat das Zeitlimit ueberschritten.");
                }
            }
            child.WaitForExit(); // Drain redirected output callbacks.
            return child.ExitCode;
        }
    }

    // Windows command-line escaping; no shell ever interprets user values.
    private static string Quote(string value)
    {
        var result = new StringBuilder("\"");
        int slashes = 0;
        foreach (char c in value)
        {
            if (c == '\\') { slashes++; continue; }
            result.Append('\\', c == '"' ? slashes * 2 + 1 : slashes);
            result.Append(c);
            slashes = 0;
        }
        result.Append('\\', slashes * 2);
        return result.Append('"').ToString();
    }

    // Closing the console or terminating the launcher also stops its engine.
    private sealed class ChildJob : IDisposable
    {
        private SafeFileHandle handle;
        [StructLayout(LayoutKind.Sequential)] private struct BasicLimits
        {
            public long ProcessTime, JobTime;
            public uint Flags;
            public UIntPtr MinWorking, MaxWorking;
            public uint ActiveProcesses;
            public UIntPtr Affinity;
            public uint Priority, Scheduling;
        }
        [StructLayout(LayoutKind.Sequential)] private struct IoCounters
        { public ulong ReadOps, WriteOps, OtherOps, ReadBytes, WriteBytes, OtherBytes; }
        [StructLayout(LayoutKind.Sequential)] private struct ExtendedLimits
        {
            public BasicLimits Basic;
            public IoCounters Io;
            public UIntPtr ProcessMemory, JobMemory, PeakProcessMemory, PeakJobMemory;
        }
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateJobObject(IntPtr attributes, string name);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetInformationJobObject(SafeFileHandle job, int infoClass, ref ExtendedLimits info, uint size);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AssignProcessToJobObject(SafeFileHandle job, IntPtr process);
        internal ChildJob()
        {
            handle = CreateJobObject(IntPtr.Zero, null);
            var limits = new ExtendedLimits();
            limits.Basic.Flags = 0x2000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
            if (handle.IsInvalid || !SetInformationJobObject(handle, 9, ref limits, (uint)Marshal.SizeOf(limits)))
            { handle.Dispose(); throw new IOException("Windows-Prozessverwaltung konnte nicht initialisiert werden."); }
        }
        internal void Assign(Process child)
        {
            if (!AssignProcessToJobObject(handle, child.Handle))
                throw new IOException("Engine konnte nicht an den Serverstarter gebunden werden.");
        }
        public void Dispose() { handle.Dispose(); }
    }
}
