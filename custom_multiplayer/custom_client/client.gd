class_name CustomMultiplayerClient extends Node

const NOGAMEID := 0

enum DisconnectedReason {
	FailedConnect,
	ServerDisconnected,
}

signal was_connected
signal was_disconnected(reason : DisconnectedReason)

var host_address : String
var host_port : int
var is_in_game : int = NOGAMEID

func quit_game() -> void:
	if is_in_game != NOGAMEID:
		__request_quit_game.rpc_id(1, is_in_game)

func join_game(game_id : int) -> void:
	if is_in_game == NOGAMEID:
		__request_join_game.rpc_id(1, game_id)

func create_game(advance_information : Variant) -> void:
	__request_create_game.rpc_id(1, advance_information)

func _connected_to_server() -> void:
	was_connected.emit()

func _disconnected_from_server(reason : DisconnectedReason) -> void:
	queue_free()
	was_disconnected.emit(reason)

func _connect_to_host() -> void:
	var custom_network = ENetMultiplayerPeer.new()
	if custom_network.create_client(host_address, host_port) == OK:
		var custom_multiplayer = SceneMultiplayer.new()
		custom_multiplayer.root_path = get_path()
		custom_multiplayer.multiplayer_peer = custom_network
		
		get_tree().set_multiplayer(custom_multiplayer, get_path())
		
		multiplayer.connected_to_server.connect(_connected_to_server)
		multiplayer.server_disconnected.connect(func():
			_disconnected_from_server(DisconnectedReason.ServerDisconnected))
		multiplayer.connection_failed.connect(func():
			_disconnected_from_server(DisconnectedReason.FailedConnect))
			
		return
	
	queue_free()

func _disconnecting_from_host() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _init() -> void:
	tree_entered.connect(_connect_to_host)
	tree_exiting.connect(_disconnecting_from_host)
	
	name = "CustomRemoteClient"


signal joinned_game(game_id : int, game_advance_information : Variant)
signal quitted_game(game_id : int, reason : Variant)

signal player_joinned_game(game_id : int, player : int, player_advance_information : Variant)
signal player_quitted_game(game_id : int, player : int, reason : Variant)

signal custom_server_response(response : Variant)
signal custom_game_response(game_id : int, response : Variant)

@rpc("authority", "call_remote", "reliable")
func __joinned_from_game(game_id : int, game_advance_information : Variant) -> void:
	is_in_game = game_id
	joinned_game.emit(game_id, game_advance_information)

@rpc("authority", "call_remote", "reliable")
func __removed_from_game(game_id : int, reason : Variant) -> void:
	is_in_game = NOGAMEID
	quitted_game.emit(game_id, reason)

@rpc("authority", "call_remote", "reliable")
func __player_joinned_from_game(game_id : int, player : int, player_advance_information : Variant) -> void:
	player_joinned_game.emit(game_id, player, player_advance_information)

@rpc("authority", "call_remote", "reliable")
func __player_quitted_from_game(game_id : int, player : int, reason : Variant) -> void:
	player_quitted_game.emit

@rpc("authority", "call_remote", "reliable")
func __custom_server_response(response : Variant) -> void:
	custom_server_response.emit(response)

@rpc("authority", "call_remote", "reliable")
func __custom_game_response(game_id : int, response : Variant) -> void:
	custom_game_response.emit(game_id, response)


@rpc("any_peer", "call_remote", "reliable")
func __request_create_game(advance_information : Variant) -> void:
	return

@rpc("any_peer", "call_remote", "reliable")
func __request_join_game(game_id : int, advance_information : Variant) -> void:
	return

@rpc("any_peer", "call_remote", "reliable")
func __request_quit_game(game_id : int) -> void:
	return
