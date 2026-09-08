class_name LanDiscovery
extends Node

const DISCOVERY_PORT := 27841
var game: Node3D
var listener := PacketPeerUDP.new()
var sender := PacketPeerUDP.new()
var servers := {}
var elapsed := 0.0
var available := false
var probes := {}

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
			sender.set_dest_address("255.255.255.255", DISCOVERY_PORT)
			sender.put_packet(JSON.stringify(info).to_utf8_buffer())
		for address in servers.keys():
			if Time.get_ticks_msec() - servers[address].seen > 3500:
				servers.erase(address)
	while available and listener.get_available_packet_count() > 0:
		var bytes := listener.get_packet()
		var address := listener.get_packet_ip()
		var reply_port := listener.get_packet_port()
		if bytes.size() > 1024:
			continue
		var info = JSON.parse_string(bytes.get_string_from_utf8())
		if info is Dictionary and info.get("protocol", "") == "BLOCKLINE_1":
			if not info.get("port") is float and not info.get("port") is int:
				continue
			if int(info.port) < 1024 or int(info.port) > 65535:
				continue
			var key := address + ":" + str(int(info.port))
			info["ping"] = servers.get(key, {}).get("ping", -1)
			info["seen"] = Time.get_ticks_msec()
			info["ip"] = address
			servers[key] = info
			var nonce := str(Time.get_ticks_usec())
			probes[nonce] = {"key": key, "ip": address, "port": reply_port, "sent": Time.get_ticks_msec()}
			sender.set_dest_address(address, reply_port)
			sender.put_packet(JSON.stringify({"kind": "ping", "nonce": nonce}).to_utf8_buffer())
	for nonce in probes.keys():
		if Time.get_ticks_msec() - probes[nonce].sent > 3000:
			probes.erase(nonce)
	while sender.get_available_packet_count() > 0:
		var bytes := sender.get_packet()
		var ip := sender.get_packet_ip()
		var reply_port := sender.get_packet_port()
		if bytes.size() > 256: continue
		var packet = JSON.parse_string(bytes.get_string_from_utf8())
		if not packet is Dictionary: continue
		var nonce := str(packet.get("nonce", "")).left(32)
		if packet.get("kind") == "ping" and game.active and game.is_host:
			sender.set_dest_address(ip, reply_port)
			sender.put_packet(JSON.stringify({"kind": "pong", "nonce": nonce}).to_utf8_buffer())
		elif packet.get("kind") == "pong" and probes.has(nonce):
			var probe: Dictionary = probes[nonce]
			if ip == probe.ip and reply_port == probe.port and servers.has(probe.key):
				servers[probe.key].ping = Time.get_ticks_msec() - probe.sent
				probes.erase(nonce)

func _exit_tree() -> void:
	listener.close()
	sender.close()
