class_name CustomMultiplayerProxy extends RefCounted

const NOID := 0

signal proxy_disconnected

var network_id : int = NOID
var is_in_game : int = NOID

func _init() -> void:
	return
