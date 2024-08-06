class_name CustomMultiplayerMessageInterface extends Node

static var singleton : CustomMultiplayerMessageInterface

signal joinned_game(game_id : int, game_advance_information : Variant)
signal quitted_game(game_id : int, reason : Variant)

signal player_joinned_game(game_id : int, player : int, player_advance_information : Variant)
signal player_quitted_game(game_id : int, player : int, reason : Variant)

#WARNING: Read-only Client

@rpc("authority", "call_remote", "reliable")
func __joinned_from_game(game_id : int, game_advance_information : Variant) -> void:
	joinned_game.emit(game_id, game_advance_information)

@rpc("authority", "call_remote", "reliable")
func __removed_from_game(game_id : int, reason : Variant) -> void:
	quitted_game.emit(game_id, reason)

@rpc("authority", "call_remote", "reliable")
func __player_joinned_from_game(game_id : int, player : int, player_advance_information : Variant) -> void:
	player_joinned_game.emit(game_id, player, player_advance_information)

@rpc("authority", "call_remote", "reliable")
func __player_quitted_from_game(game_id : int, player : int, reason : Variant) -> void:
	player_quitted_game.emit(game_id, player, reason)

func _init() -> void:
	singleton = self
	
	name = "MessageRemote"
