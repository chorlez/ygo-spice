extends Node

### CLIENT SIDE RPC'S
signal database_built()
signal card_hovered(card_data:CardData)


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
