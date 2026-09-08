using System;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading;

// The bootstrap stays outside the version directories, so a running EXE never
// needs to replace itself. Only a validated, completely installed version is selected.
internal static class Updater
{
    internal const string Repository = "https://api.github.com/repos/KnowledgeMonkey/egoshooter";
    private static readonly Regex Commit = new Regex("^[0-9a-f]{40}$");

    internal static string Select(string root, string engine, Action<string, string> validate, Action<string> status, bool offline,
        Func<string> fetchVersion = null, Action<string, string> download = null)
    {
        string data = Path.Combine(root, ".updates");
        Directory.CreateDirectory(data);
        File.WriteAllText(Path.Combine(data, ".gdignore"), "");
        // Also prevents two launcher instances importing the same version together.
        using (var gate = new FileStream(Path.Combine(data, "update.lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None))
        {
            string current = ReadCurrent(root);
            if (offline) return current;
            string stage = null;
            try
            {
                status("Suche nach Updates auf GitHub ...");
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
                string json;
                if (fetchVersion != null) json = fetchVersion();
                else using (var client = new DownloadClient(10000))
                        json = client.DownloadString(Repository + "/commits/main");
                var match = Regex.Match(json, "\"sha\"\\s*:\\s*\"([0-9a-f]{40})\"");
                if (!match.Success) throw new InvalidDataException("GitHub hat keine gueltige Versionsnummer geliefert.");
                string sha = match.Groups[1].Value;
                string versions = Path.Combine(data, "versions");
                Directory.CreateDirectory(versions);
                string destination = Path.Combine(versions, sha);
                if (String.Equals(current, destination, StringComparison.OrdinalIgnoreCase))
                {
                    status("Das Spiel ist aktuell.");
                    return current;
                }
                stage = Path.Combine(data, "staging-" + Guid.NewGuid().ToString("N"));
                Directory.CreateDirectory(stage);
                string zip = Path.Combine(stage, "source.zip");
                status("Lade Spielversion " + sha.Substring(0, 8) + " herunter ...");
                if (download != null) download(sha, zip);
                else using (var client = new DownloadClient(120000))
                        client.DownloadFile("https://codeload.github.com/KnowledgeMonkey/egoshooter/zip/" + sha, zip);
                string content = Path.Combine(stage, "game");
                Extract(zip, content);
                if (!File.Exists(Path.Combine(content, "project.godot")) ||
                    !File.Exists(Path.Combine(content, "scenes", "main.tscn")))
                    throw new InvalidDataException("Das Update enthaelt kein vollstaendiges Spielprojekt.");
                status("Installiere und pruefe die neue Spielversion ...");
                validate(engine, content);
                // A previous interrupted activation may have left a valid directory here.
                // Never change an existing version: a game process may still use it.
                if (!Directory.Exists(destination)) Directory.Move(content, destination);
                else if (!File.Exists(Path.Combine(destination, "project.godot")))
                    throw new InvalidDataException("Vorhandener Versionsordner ist beschaedigt: " + destination);
                Activate(data, sha);
                Log(root, "Installiert: " + sha);
                return destination;
            }
            catch (Exception error)
            {
                Log(root, "Update nicht installiert; bisherige Version wird gestartet. " + error);
                status("Update nicht verfuegbar. Starte die bisherige Version ...");
                return current;
            }
            finally
            {
                if (stage != null && Directory.Exists(stage))
                {
                    try { Directory.Delete(stage, true); } catch { }
                }
            }
        }
    }

    internal static string ReadCurrent(string root)
    {
        string pointer = Path.Combine(root, ".updates", "current.txt");
        if (!File.Exists(pointer)) return root;
        string sha = File.ReadAllText(pointer).Trim();
        if (!Commit.IsMatch(sha)) return root;
        string selected = Path.Combine(root, ".updates", "versions", sha);
        return File.Exists(Path.Combine(selected, "project.godot")) ? selected : root;
    }

    internal static void Activate(string data, string sha)
    {
        if (!Commit.IsMatch(sha)) throw new InvalidDataException("Ungueltige Version.");
        string pointer = Path.Combine(data, "current.txt");
        string temp = Path.Combine(data, "current-" + Guid.NewGuid().ToString("N") + ".tmp");
        File.WriteAllText(temp, sha);
        if (File.Exists(pointer)) File.Replace(temp, pointer, Path.Combine(data, "previous.txt"));
        else File.Move(temp, pointer);
    }

    internal static void Extract(string archive, string target)
    {
        Directory.CreateDirectory(target);
        string prefix = Path.GetFullPath(target).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        string archiveRoot = null;
        long total = 0;
        using (var zip = ZipFile.OpenRead(archive))
        {
            if (zip.Entries.Count > 50000) throw new InvalidDataException("Zu viele Archivdateien.");
            foreach (var entry in zip.Entries)
            {
                string name = entry.FullName;
                int slash = name.IndexOf('/');
                if (slash <= 0 || name.Contains("\\") || name.Contains(":"))
                    throw new InvalidDataException("Ungueltiger Archivpfad.");
                string top = name.Substring(0, slash);
                if (archiveRoot == null) archiveRoot = top;
                if (archiveRoot != top) throw new InvalidDataException("Mehrere Archivwurzeln.");
                string relative = name.Substring(slash + 1);
                if (relative.Length == 0) continue;
                foreach (string part in relative.Split('/'))
                    if (part == ".." || part == "." || part.EndsWith(".") || part.EndsWith(" "))
                        throw new InvalidDataException("Unsicherer Archivpfad.");
                string path = Path.GetFullPath(Path.Combine(target, relative.Replace('/', Path.DirectorySeparatorChar)));
                if (!path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Archivpfad verlaesst den Zielordner.");
                if (((entry.ExternalAttributes >> 16) & 0xF000) == 0xA000)
                    throw new InvalidDataException("Symbolische Links sind nicht erlaubt.");
                total += entry.Length;
                if (total > 2L * 1024 * 1024 * 1024) throw new InvalidDataException("Update ist zu gross.");
                if (name.EndsWith("/")) Directory.CreateDirectory(path);
                else
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(path));
                    entry.ExtractToFile(path, false);
                }
            }
        }
    }

    internal static void Log(string root, string message)
    {
        try
        {
            Directory.CreateDirectory(Path.Combine(root, "logs"));
            File.AppendAllText(Path.Combine(root, "logs", "updater.log"), DateTime.Now.ToString("s") + " " + message + Environment.NewLine);
        }
        catch { }
    }

    private sealed class DownloadClient : WebClient
    {
        private readonly int timeout;
        internal DownloadClient(int timeout)
        {
            this.timeout = timeout;
            Headers[HttpRequestHeader.UserAgent] = "BLOCKLINE-Updater/1.0";
            Headers[HttpRequestHeader.Accept] = "application/vnd.github+json";
        }
        protected override WebRequest GetWebRequest(Uri address)
        {
            var request = base.GetWebRequest(address);
            request.Timeout = timeout;
            var http = request as HttpWebRequest;
            if (http != null) http.ReadWriteTimeout = timeout;
            return request;
        }
    }
}
