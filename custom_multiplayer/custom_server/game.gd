class_name CustomMultiplayerGame extends RefCounted

signal game_removed()
signal game_emptied()

signal player_joinned(network_id : int, player_advance_info : Variant)
signal player_removed(network_id : int, reason : Variant)

var game_id : int
var players_map : Dictionary

func _init() -> void:
	game_id = randi()
	players_map.clear()

func add_player(player : CustomMultiplayerPlayer, proxy_disconnected_reason : Variant, game_advance_information : Variant, player_advance_information : Variant) -> void:
	if not player.proxy.network_id in players_map and player.proxy is CustomMultiplayerProxy:
		if player.proxy.is_in_game != CustomMultiplayerProxy.NOID:
			HIGHTUtils.pusherr("add_player", "The player is in another game.")
			return
		
		players_map[player.proxy.network_id] = player
		players_map[player.proxy.network_id].proxy.is_in_game = game_id
		players_map[player.proxy.network_id].proxy.proxy_disconnected.connect(func():
			remove_player(player.proxy.network_id, proxy_disconnected_reason))
		
		player_joinned.emit(player.proxy.network_id, player_advance_information)
		
		if CustomMultiplayerServer.default_server:
			CustomMultiplayerServer.default_server.__joinned_from_game.rpc_id(
				player.proxy.network_id, game_id, game_advance_information)
			
			for other in players_map:
				if other is CustomMultiplayerPlayer and other.proxy.network_id != player.proxy.network_id:
					CustomMultiplayerServer.default_server.__player_joinned_from_game.rpc_id(
						other.proxy.network_id, game_id, player.proxy.network_id, player_advance_information)

func remove_player(network_id : int, reason : Variant) -> void:
	if network_id in players_map:
		if players_map[network_id] is CustomMultiplayerPlayer:
			if players_map[network_id].proxy is CustomMultiplayerProxy:
				players_map[network_id].proxy.is_in_game = CustomMultiplayerProxy.NOID
				players_map[network_id].proxy = null
			
			players_map.erase(network_id)
			player_removed.emit(network_id, reason)
			
			if CustomMultiplayerServer.default_server:
				CustomMultiplayerServer.default_server.__removed_from_game.rpc_id(
					network_id, game_id, reason)
					
				for other in players_map:
					if other is CustomMultiplayerPlayer and other.proxy.network_id != network_id:
						CustomMultiplayerServer.default_server.__player_quitted_from_game.rpc_id(
							other.proxy.network_id, game_id, reason)
			
			if players_map.size() < 1:
				game_emptied.emit()
