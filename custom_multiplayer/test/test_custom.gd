extends Node

class MyMessage extends CustomMultiplayerMessageInterface:
	func _init() -> void:
		super._init()

class MyPlayer extends CustomMultiplayerPlayer:
	func _init() -> void:
		super._init()

class MyGame extends CustomMultiplayerGame:
	func _init() -> void:
		super._init()

class MyClient extends CustomMultiplayerClient:
	func _init() -> void:
		super._init()

class MyProxy extends CustomMultiplayerProxy:
	func _init() -> void:
		super._init()

class MyServer extends CustomMultiplayerServer:
	func _init() -> void:
		super._init()


static var message : MyMessage
static var server : MyServer
static var client : MyClient

func _enter_tree() -> void:
	server = MyServer.new()
	server.server_port = 8081
	server.server_max = 4000
	
	server.game_created.connect(func(game_id : int):
		print("Game created: %s" % game_id))
	server.game_removed.connect(func(game_id : int, reason : Variant):
		print("Game removed: %s:\n\tReason: %s" % [game_id, reason]))
	
	server.proxy_created.connect(func(network_id : int):
		print("Proxy created: %s" % network_id))
	
	server.proxy_removed.connect(func(network_id : int):
		print("Proxy removed: %s" % network_id))
	
	server.requested_create_game.connect(func(network_id : int, advance_information : Variant):
		var player = MyPlayer.new()
		player.proxy = server.proxys_map[network_id]
		
		var game = MyGame.new()
		game.player_joinned.connect(func(network_id : int):
			print("Player joinned: %s" % network_id))
		game.player_removed.connect(func(network_id : int, reason : Variant):
			print("Player exited: %s:\n\t\tReason: %s" % [network_id, reason]))
		
		server.create_game(game)
		game.add_player(player, "Disconnected.", {}, {}))
	
	server.requested_join_game.connect(func(network_id : int, game_id : int, advance_information : Variant):
		var player = MyPlayer.new()
		player.proxy = server.proxys_map[network_id]
		
		server.games_map[game_id].add_player(player, "Disconncted.", {}, {}))
	
	add_child(server)
	
	client = MyClient.new()
	client.host_address = "127.0.0.1"
	client.host_port = 8081
	
	client.was_connected.connect(func():
		print("Connected from server."))
	client.was_disconnected.connect(func(reason : MyClient.DisconnectedReason):
		print("Disconncted from server: ReasonID -> %s" % reason))
	
	client.joinned_game.connect(func(game_id : int, advance_info: Variant):
		print("[Player:%s] Joinned to game: %s" % [client.multiplayer.get_unique_id(), game_id]))
	client.quitted_game.connect(func(game_id : int, reason : Variant):
		print("[Player:%s] Quitted from game: %s:\n\t\tReason: %s" % [client.multiplayer.get_unique_id(), game_id, reason]))
	
	add_child(client)
	
	await get_tree().create_timer(1.0).timeout
	client.create_game({})
	await get_tree().create_timer(1.0).timeout
	client.quit_game()

func _exit_tree() -> void:
	return
