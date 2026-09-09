using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Threading.Tasks;
using System.Drawing;

internal static class Launcher
{
    [STAThread]
    private static int Main(string[] args)
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string logs = Path.Combine(root, "logs");
        bool verify = Array.IndexOf(args, "--verify") >= 0;
        bool offline = Array.IndexOf(args, "--offline") >= 0;
        bool updateOnly = Array.IndexOf(args, "--update-only") >= 0;
        bool local = Array.IndexOf(args, "--local") >= 0;
        Form window = null;
        Label label = null;
        try
        {
            Directory.CreateDirectory(logs);
            if (local && updateOnly) throw new ArgumentException("--local und --update-only können nicht zusammen verwendet werden.");
            if (!verify && !updateOnly)
            {
                Application.EnableVisualStyles();
                window = new Form { Text = "BLOCKLINE - Spielstart", ClientSize = new Size(520, 110),
                    StartPosition = FormStartPosition.CenterScreen, FormBorderStyle = FormBorderStyle.FixedDialog,
                    MaximizeBox = false, MinimizeBox = false, ControlBox = false };
                label = new Label { Left = 20, Top = 25, Width = 480, Height = 65, Text = "Bereite Spielstart vor ..." };
                window.Controls.Add(label);
                window.Show();
                Application.DoEvents();
            }
            Action<string> status = delegate(string message)
            {
                if (label != null) label.BeginInvoke((Action)delegate { label.Text = message; });
            };
            string engine = Path.Combine(root, "tools", "godot", "Godot_v4.5-stable_win64.exe");
            if (!File.Exists(engine))
                throw new FileNotFoundException("Godot fehlt: " + engine + "\nBitte den kompletten Spielordner verwenden.");
            string gameRoot = root;
            var update = Task.Factory.StartNew(delegate
            {
                if (local) { status("Starte lokalen Projektstand ..."); return root; }
                return Updater.Select(root, engine, delegate(string executable, string project)
                {
                    string updateLog = Path.Combine(logs, "update-import.log");
                    Run(executable, "--headless --editor --import --quit --path " + Quote(project) +
                        " --log-file " + Quote(updateLog), project, true);
                    CheckLog(updateLog);
                    string smokeLog = Path.Combine(logs, "update-verify.log");
                    Run(executable, "--headless --quit-after 5 --path " + Quote(project) +
                        " --log-file " + Quote(smokeLog), project, true);
                    CheckLog(smokeLog);
                }, status, offline);
            });
            while (!update.IsCompleted) { Application.DoEvents(); System.Threading.Thread.Sleep(30); }
            gameRoot = update.GetAwaiter().GetResult();
            if (updateOnly) return 0;
            if (!File.Exists(Path.Combine(gameRoot, "project.godot")))
                throw new FileNotFoundException("project.godot fehlt neben Start-Game.exe.");
            // Import classes/resources even on a fresh copy without .godot cache.
            string importLog = Path.Combine(logs, "import.log");
            if (label != null) { label.Text = "Bereite Spielressourcen vor ..."; Application.DoEvents(); }
            Run(engine, "--headless --editor --import --quit --path " + Quote(gameRoot.TrimEnd('\\')) +
                " --log-file " + Quote(importLog), gameRoot, true);
            CheckLog(importLog);
            string gameLog = Path.Combine(logs, "game.log");
            string arguments = "--path " + Quote(gameRoot.TrimEnd('\\')) + " --log-file " + Quote(gameLog);
            if (verify) arguments += " --headless --max-fps 60 --quit-after 120";
            Run(engine, arguments, gameRoot, verify);
            if (verify) CheckLog(gameLog);
            return 0;
        }
        catch (Exception error)
        {
            string details = error.Message + "\n\nDiagnose: " + logs;
            try { File.WriteAllText(Path.Combine(logs, "launcher-error.txt"), error.ToString()); } catch { }
            if (!verify && !updateOnly) MessageBox.Show(details, "BLOCKLINE konnte nicht starten", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
        finally { if (window != null) window.Dispose(); }
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
            var elapsed = Stopwatch.StartNew();
            while (!process.WaitForExit(50))
            {
                Application.DoEvents();
                if (elapsed.ElapsedMilliseconds > 90000)
                {
                    process.Kill();
                    process.WaitForExit();
                    throw new Exception("Godot hat innerhalb von 90 Sekunden nicht reagiert.");
                }
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
