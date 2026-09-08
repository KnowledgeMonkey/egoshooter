using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Launcher
{
    [STAThread]
    private static int Main(string[] args)
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string logs = Path.Combine(root, "logs");
        bool verify = Array.IndexOf(args, "--verify") >= 0;
        try
        {
            Directory.CreateDirectory(logs);
            string engine = Path.Combine(root, "tools", "godot", "Godot_v4.5-stable_win64.exe");
            if (!File.Exists(engine))
                throw new FileNotFoundException("Godot fehlt: " + engine + "\nBitte den kompletten Spielordner verwenden.");
            if (!File.Exists(Path.Combine(root, "project.godot")))
                throw new FileNotFoundException("project.godot fehlt neben Start-Game.exe.");
            // Import classes/resources even on a fresh copy without .godot cache.
            string importLog = Path.Combine(logs, "import.log");
            Run(engine, "--headless --editor --import --quit --path " + Quote(root.TrimEnd('\\')) +
                " --log-file " + Quote(importLog), root, true);
            CheckLog(importLog);
            string gameLog = Path.Combine(logs, "game.log");
            string arguments = "--path " + Quote(root.TrimEnd('\\')) + " --log-file " + Quote(gameLog);
            if (verify) arguments += " --headless --max-fps 60 --quit-after 120";
            Run(engine, arguments, root, verify);
            if (verify) CheckLog(gameLog);
            return 0;
        }
        catch (Exception error)
        {
            string details = error.Message + "\n\nDiagnose: " + logs;
            try { File.WriteAllText(Path.Combine(logs, "launcher-error.txt"), error.ToString()); } catch { }
            if (!verify) MessageBox.Show(details, "BLOCKLINE konnte nicht starten", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    private static string Quote(string value) { return "\"" + value + "\""; }

    private static void Run(string file, string args, string directory, bool wait)
    {
        var info = new ProcessStartInfo(file, args);
        info.WorkingDirectory = directory;
        info.UseShellExecute = false;
        info.CreateNoWindow = true;
        using (var process = Process.Start(info))
        {
            if (!wait) return;
            if (!process.WaitForExit(90000))
            {
                process.Kill();
                throw new Exception("Godot hat innerhalb von 90 Sekunden nicht reagiert.");
            }
            if (process.ExitCode != 0)
                throw new Exception("Godot wurde mit Fehlercode " + process.ExitCode + " beendet.");
        }
    }

    private static void CheckLog(string path)
    {
        if (!File.Exists(path)) throw new Exception("Godot hat kein Startprotokoll erzeugt.");
        string contents = File.ReadAllText(path);
        if (contents.Contains("SCRIPT ERROR:") || contents.Contains("Failed to load"))
            throw new Exception("Godot meldet einen Ressourcen- oder Scriptfehler. Details in " + path);
    }
}
