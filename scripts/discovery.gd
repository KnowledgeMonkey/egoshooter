class_name LanDiscovery
extends Node

const DISCOVERY_PORT := 27841
var game: Node3D
var listener := PacketPeerUDP.new()
var sender := PacketPeerUDP.new()
var servers := {}
var elapsed := 0.0
var available := false

func _ready() -> void:
	# A dedicated server only advertises; leave the receive port to local clients.
	available = not game.dedicated and listener.bind(DISCOVERY_PORT, "0.0.0.0") == OK
	sender.set_broadcast_enabled(true)
	sender.set_dest_address("255.255.255.255", DISCOVERY_PORT)

func _process(dt: float) -> void:
	elapsed += dt
	if elapsed > 1:
		elapsed = 0
		if game.active and game.is_host and game.config.get("discovery", true):
			var humans := 0
			for p: Fighter in game.players.values():
				if not p.bot:
					humans += 1
			var info := {"protocol": "BLOCKLINE_1", "name": game.config.server_name, "players": humans,
				"max": game.config.max_players, "mode": game.config.mode, "port": game.port}
			sender.put_packet(JSON.stringify(info).to_utf8_buffer())
		for address in servers.keys():
			if Time.get_ticks_msec() - servers[address].seen > 3500:
				servers.erase(address)
	while available and listener.get_available_packet_count() > 0:
		var bytes := listener.get_packet()
		var address := listener.get_packet_ip()
		if bytes.size() > 1024:
			continue
		var info = JSON.parse_string(bytes.get_string_from_utf8())
		if info is Dictionary and info.get("protocol", "") == "BLOCKLINE_1":
			info["seen"] = Time.get_ticks_msec()
			info["ip"] = address
			servers[address] = info

func _exit_tree() -> void:
	listener.close()
	sender.close()
