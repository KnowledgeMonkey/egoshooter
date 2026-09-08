using System;
using System.IO;
using System.IO.Compression;

internal static class UpdaterTests
{
    static int checks;
    static void Check(bool value, string message)
    {
        if (!value) throw new Exception(message);
        checks++;
        Console.WriteLine("PASS: " + message);
    }
    static void Archive(string path, bool unsafePath)
    {
        using (var zip = ZipFile.Open(path, ZipArchiveMode.Create))
        {
            foreach (string file in new[] { "repo/project.godot", "repo/scenes/main.tscn", "repo/scripts/new.gd" })
                using (var writer = new StreamWriter(zip.CreateEntry(file).Open())) writer.Write("test");
            if (unsafePath)
                using (var writer = new StreamWriter(zip.CreateEntry("repo/../../escape.txt").Open())) writer.Write("bad");
        }
    }
    static int Main()
    {
        string root = Path.Combine(Path.GetTempPath(), "blockline-updater-test-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            File.WriteAllText(Path.Combine(root, "project.godot"), "local source");
            File.WriteAllText(Path.Combine(root, "personal.txt"), "keep");
            string a = new string('a', 40), b = new string('b', 40);
            Action<string> status = delegate { };
            Action<string, string> good = delegate(string engine, string path) { };
            Action<string, string> archive = delegate(string sha, string path) { Archive(path, false); };
            Func<string> versionA = delegate { return "{\"sha\":\"" + a + "\"}"; };
            Func<string> versionB = delegate { return "{\"sha\":\"" + b + "\"}"; };
            string first = Updater.Select(root, "", good, status, false, versionA, archive);
            Check(first != root && File.Exists(Path.Combine(first, "scripts", "new.gd")), "Fresh update installed and activated");
            Check(File.ReadAllText(Path.Combine(root, "project.godot")) == "local source" && File.Exists(Path.Combine(root, "personal.txt")), "Local source and personal files preserved");
            Check(Updater.Select(root, "", good, status, false, versionA, delegate { throw new Exception("Unexpected download"); }) == first,
                "Unchanged version retained");
            bool downloaded = false;
            Updater.Select(root, "", good, status, false, versionA, delegate { downloaded = true; });
            Check(!downloaded, "No download for unchanged version");
            Check(Updater.Select(root, "", good, status, true, delegate { throw new Exception("Unexpected network"); }, archive) == first, "Offline uses installed version");
            Check(Updater.Select(root, "", good, status, false, delegate { throw new IOException("Network unavailable"); }, archive) == first, "Network failure retains playable version");
            Check(Updater.Select(root, "", delegate { throw new Exception("Bad game import"); }, status, false, versionB, archive) == first && Updater.ReadCurrent(root) == first,
                "Failed game validation never activates update");
            Check(Updater.Select(root, "", good, status, false, versionB, delegate(string sha, string path) { File.WriteAllText(path, "truncated zip"); }) == first,
                "Interrupted or corrupt download retains installed version");
            Check(Updater.Select(root, "", good, status, false, versionB, delegate(string sha, string path) { Archive(path, true); }) == first && !File.Exists(Path.Combine(root, "escape.txt")),
                "Archive traversal rejected");
            Check(Directory.GetDirectories(Path.Combine(root, ".updates"), "staging-*").Length == 0, "Failed staging directories cleaned");
            File.WriteAllText(Path.Combine(first, "obsolete.txt"), "old");
            string second = Updater.Select(root, "", good, status, false, versionB, archive);
            Check(second != first && !File.Exists(Path.Combine(second, "obsolete.txt")), "Removed files do not leak into new version");
            Check(File.Exists(Path.Combine(first, "obsolete.txt")), "Previous version remains intact for running games");
            Check(File.ReadAllText(Path.Combine(root, ".updates", "previous.txt")) == a, "Previous version pointer retained");
            File.WriteAllText(Path.Combine(root, ".updates", "current.txt"), "../../outside");
            Check(Updater.ReadCurrent(root) == root, "Invalid pointer falls back to local game");
            Console.WriteLine(checks + " checks passed.");
            return 0;
        }
        finally { Directory.Delete(root, true); }
    }
}
