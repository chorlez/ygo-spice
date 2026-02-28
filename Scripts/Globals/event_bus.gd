extends Node

### CLIENT SIDE RPC'S
signal database_built()
signal player_connected(id:int)
signal card_hovered(card_id: int)
signal mouse_clicked(position:Vector2)
signal add_card_to_deck(card_data:CardData)
signal remove_card_from_deck(card_scene:CardScene)
signal card_right_clicked(card_scene:CardScene)
signal toggle_sort_mode()
signal clear_deck()
signal save_deck()
signal load_deck()

### SERVER SIDE RPC'S
@rpc("any_peer", 'call_local')
func request_cube():
	cube_requested.emit()
	
signal cube_requested()

@rpc("any_peer", 'call_local')
func open_pack():
	if multiplayer.is_server():
		pack_requested.emit()

signal pack_requested()

@rpc("any_peer", 'call_local')
func sync_pack(cardIDs:Array[int]):
	pack_created.emit(cardIDs)

signal pack_created(cardIDs:Array[int])

@rpc("any_peer", 'call_local')
func remove_card_from_pack(pack_index:int):
	card_removed_from_pack.emit(pack_index)

signal card_removed_from_pack(pack_index:int)

@rpc("any_peer", 'call_local')
func add_card_to_pack(card_id:int):
	card_added_to_pack.emit(card_id)

signal card_added_to_pack(card_id:int)

@rpc("any_peer", 'call_local')
func log_card_added(card_id: int, steam_name: String):
	card_add_log.emit(card_id, steam_name)

signal card_add_log(card_id: int, steam_name: String)

@rpc("any_peer", 'call_local')
func log_card_removed(card_id: int, steam_name: String):
	card_remove_log.emit(card_id, steam_name)

signal card_remove_log(card_id: int, steam_name: String)

@rpc("any_peer", 'call_local')
func on_cube_search_option_pressed(type:String, option:String, support_only: bool):
	cube_type_added.emit(type, option, support_only)

signal cube_type_added(type:String, option:String, support_only: bool)
