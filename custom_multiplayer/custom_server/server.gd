class_name CustomMultiplayerServer extends Node

signal proxy_created(network_id : int)
signal proxy_removed(network_id : int)

signal game_created(game_id : int)
signal game_removed(game_id : int, reason : Variant)

static var default_server : CustomMultiplayerServer

var server_port : int
var server_max : int
var proxys_map : Dictionary
var games_map : Dictionary
var reason_request_quit_game : Variant = "Exited from game."

func create_game(game : CustomMultiplayerGame, emptied_close_reason : Variant = "(players_size < 1)! Closing...") -> void:
	games_map[game.game_id] = game
	games_map[game.game_id].game_emptied.connect(func():
		remove_game(game.game_id, emptied_close_reason))
	game_created.emit(game.game_id)

func remove_game(game_id : int, reason : Variant = "Game closed.") -> void:
	if not game_id in games_map:
		return
	
	if not games_map[game_id] is CustomMultiplayerGame:
		return
	
	for player_id in games_map[game_id].players_map.keys():
		games_map[game_id].remove_player(player_id, reason)
	
	games_map[game_id].game_removed.emit()
	game_removed.emit(game_id, reason)
	games_map.erase(game_id)

func _create_proxy(peer : int) -> void:
	proxys_map[peer] = CustomMultiplayerProxy.new()
	proxys_map[peer].network_id = peer
	
	proxy_created.emit(proxys_map[peer].network_id)

func _remove_proxy(peer : int) -> void:
	if not peer in proxys_map:
		return
	
	if not proxys_map[peer] is CustomMultiplayerProxy:
		return
	
	proxys_map[peer].proxy_disconnected.emit()
	proxy_removed.emit(proxys_map[peer].network_id)
	proxys_map.erase(peer)

func _create_server() -> void:
	var custom_network = ENetMultiplayerPeer.new()
	if custom_network.create_server(server_port, server_max) == OK:
		var custom_multiplayer = SceneMultiplayer.new()
		custom_multiplayer.root_path = get_path()
		custom_multiplayer.multiplayer_peer = custom_network
		
		get_tree().set_multiplayer(custom_multiplayer, get_path())
		
		multiplayer.peer_connected.connect(_create_proxy)
		multiplayer.peer_disconnected.connect(_remove_proxy)
		
		
		return
	
	queue_free()

func _closing_server() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func _init() -> void:
	default_server = self
	
	server_port = 8081
	server_max = 4000
	
	proxys_map.clear()
	games_map.clear()
	
	tree_entered.connect(_create_server)
	tree_exiting.connect(_closing_server)
	
	name = "CustomRemoteServer"

@rpc("authority", "call_remote", "reliable")
func __joinned_from_game(game_id : int, game_advance_information : Variant) -> void:
	return

@rpc("authority", "call_remote", "reliable")
func __removed_from_game(game_id : int, reason : Variant) -> void:
	return

@rpc("authority", "call_remote", "reliable")
func __player_joinned_from_game(game_id : int, player : int, player_advance_information : Variant) -> void:
	return

@rpc("authority", "call_remote", "reliable")
func __player_quitted_from_game(game_id : int, player : int, reason : Variant) -> void:
	return

@rpc("authority", "call_remote", "reliable")
func __custom_server_response(response : Variant) -> void:
	return

@rpc("authority", "call_remote", "reliable")
func __custom_game_response(game_id : int, response : Variant) -> void:
	return

signal requested_create_game(network_id : int, advance_information : Variant)
signal requested_join_game(network_id : int, game_id : int, advance_information : Variant)

@rpc("any_peer", "call_remote", "reliable")
func __request_create_game(advance_information : Variant) -> void:
	var by = multiplayer.get_remote_sender_id()
	
	if by in proxys_map:
		if proxys_map[by].is_in_game == CustomMultiplayerProxy.NOID:
			requested_create_game.emit(by, advance_information)

@rpc("any_peer", "call_remote", "reliable")
func __request_join_game(game_id : int, advance_information : Variant) -> void:
	var by = multiplayer.get_remote_sender_id()
	
	if by in proxys_map:
		if proxys_map[by].is_in_game == CustomMultiplayerProxy.NOID:
			requested_join_game.emit(by, game_id, advance_information)

@rpc("any_peer", "call_remote", "reliable")
func __request_quit_game(game_id : int) -> void:
	var by = multiplayer.get_remote_sender_id()
	
	if game_id in games_map:
		if by in proxys_map:
			if proxys_map[by].is_in_game == game_id:
				games_map[game_id].remove_player(by, reason_request_quit_game)
					
