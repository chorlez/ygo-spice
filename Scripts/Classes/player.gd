class_name Player

var steam_id:int
var steam_name:String
var peer_id:int

func _init(peer_id_:int, steam_id_:int, steam_name_:String) -> void:
	peer_id = peer_id_
	steam_id = steam_id_
	steam_name = steam_name_
