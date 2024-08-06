<img src="https://github.com/user-attachments/assets/601265bf-9a31-4eca-8fbf-7157949b88de" width="128" height="128"/>

# HIGHT
Hight Level Custom Multiplayer Implementation for Godot.

* Custom network implementation.
* Easy communication between player and room.
* Control and restriction of players between each other.

```gdscript
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
```


Output:

```
Connected from server.
Proxy created: 342691226
Game created: 170073168
Player joinned: 342691226
[Player:342691226] Joinned to game: 170073168
Player exited: 342691226:
		Reason: Exited from game.
Game removed: 170073168:
	Reason: (players_size < 1)! Closing...
[Player:342691226] Quitted from game: 170073168:
		Reason: Exited from game.
--- Debugging process stopped ---
```


```
Remote call functions (RPC) must be identical for both classes (Server & Client).
```

For better control over the implementation of "Custom Games", the server does not create a game or add a player by default.
Instead, use the "requested_*" signals to implement these functions.

"advanced_information" is extra information passed from a player to the server or vice versa. It can be used to complement the customization of a player registry or data submission.
