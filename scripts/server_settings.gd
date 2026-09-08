class_name ServerSettings
extends RefCounted

const DEFAULTS := {"server_name": "BLOCKLINE Dedicated", "bind": "0.0.0.0", "port": 27840,
	"mode": "TDM", "max_players": 8, "bots": 8, "difficulty": 1, "score_limit": 50,
	"time_limit": 600, "round_delay": 10, "discovery": true}
const RANGES := {"port": [1024, 65535], "max_players": [2, 8], "bots": [0, 8],
	"difficulty": [0, 3], "score_limit": [1, 200], "time_limit": [60, 1800], "round_delay": [3, 120]}
const OPTIONS := {"name": "server_name", "bind": "bind", "port": "port", "mode": "mode",
	"max-players": "max_players", "bots": "bots", "difficulty": "difficulty",
	"score-limit": "score_limit", "time-limit": "time_limit", "round-delay": "round_delay", "discovery": "discovery"}

static func validate(settings: Dictionary) -> String:
	for key in settings:
		if not DEFAULTS.has(key):
			return "Unbekannte Einstellung: " + str(key)
	for key in RANGES:
		var value = settings.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)):
			return "%s muss eine ganze Zahl sein." % key
		if value < RANGES[key][0] or value > RANGES[key][1]:
			return "%s muss zwischen %s und %s liegen." % [key, RANGES[key][0], RANGES[key][1]]
	if settings.bots > settings.max_players:
		return "bots darf max_players nicht uebersteigen."
	if settings.port == LanDiscovery.DISCOVERY_PORT:
		return "UDP 27841 ist fuer die LAN-Suche reserviert."
	if not settings.get("server_name") is String or settings.server_name.strip_edges().is_empty() or settings.server_name.length() > 40:
		return "server_name muss 1 bis 40 Zeichen enthalten."
	if not settings.get("bind") is String or not settings.bind.is_valid_ip_address() or settings.bind.contains(":"):
		return "bind muss eine lokale IPv4-Adresse sein (z.B. 0.0.0.0)."
	if settings.get("mode") not in ["TDM", "FFA"]:
		return "mode muss TDM oder FFA sein."
	if not settings.get("discovery") is bool:
		return "discovery muss true oder false sein."
	return ""

static func read(args: PackedStringArray) -> Dictionary:
	var path := "res://server.json"
	for arg in args:
		if arg.begins_with("--config="):
			path = arg.trim_prefix("--config=")
	if not FileAccess.file_exists(path):
		return {"error": "Konfiguration fehlt: " + path}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return {"error": "Ungueltiges JSON in " + path + ": " + parser.get_error_message()}
	var settings := DEFAULTS.duplicate()
	settings.merge(parser.data, true)
	var result := {"settings": settings, "error": "", "run_for": 0, "stop_file": ""}
	for arg in args:
		if arg == "--dedicated" or arg.begins_with("--config="):
			continue
		var split := arg.find("=")
		if not arg.begins_with("--") or split < 3:
			return {"error": "Option muss --name=wert verwenden: " + arg}
		var option := arg.substr(2, split - 2)
		var value := arg.substr(split + 1)
		if option == "stop-file":
			result.stop_file = value
		elif option == "run-for":
			if not value.is_valid_int() or int(value) < 1 or int(value) > 86400:
				return {"error": "run-for muss 1 bis 86400 Sekunden sein."}
			result.run_for = int(value)
		elif OPTIONS.has(option):
			var key: String = OPTIONS[option]
			if RANGES.has(key):
				if not value.is_valid_int():
					return {"error": option + " muss eine ganze Zahl sein."}
				settings[key] = int(value)
			elif key == "discovery":
				if value not in ["true", "false"]:
					return {"error": "discovery muss true oder false sein."}
				settings[key] = value == "true"
			else:
				settings[key] = value
		else:
			return {"error": "Unbekannte Option: " + option}
	result.error = validate(settings)
	return result
