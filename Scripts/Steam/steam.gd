extends Node

var game_name:= "YugiBoy"
var lobby_id := 0
var peer

func _ready():
	print("Initializing Steam...")
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	Steam.steamInitEx()
	
	multiplayer.connect("peer_connected", _on_player_connected)
	multiplayer.connect("peer_disconnected", _on_peer_disconnected)
	
	find_or_create_lobby()


func find_or_create_lobby():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game_tag", game_name, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.lobby_match_list.connect(_on_lobbies_found)
	Steam.requestLobbyList()

func _on_lobbies_found(lobbies):
	print("Found %d lobbies" % lobbies.size())
	if lobbies.size() == 0:
		host_lobby()
	else:
		print("Joining lobby %s" % Steam.getLobbyData(lobbies[0], 'name'))
		join_lobby(lobbies[0])

func host_lobby():
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func join_lobby(id):
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.joinLobby(id)

func _on_lobby_created(result, id):

	if result == Steam.RESULT_OK:
		lobby_id = id

		Steam.setLobbyData(lobby_id, "name", "%s's Lobby" % Steam.getPersonaName())
		Steam.setLobbyData(lobby_id, "game_tag", game_name)
		Steam.setLobbyJoinable(lobby_id, true)
		
		peer = SteamMultiplayerPeer.new()
		peer.create_host(0)
		multiplayer.multiplayer_peer = peer
		
		print("Lobby created successfully with ID %d" % lobby_id)
	sync_players()

func _on_lobby_joined(slct_lobby_id, _permissions, _locked, response):
	if response != Steam.RESULT_OK:
		print("Failed to join lobby!")
		return
	lobby_id = slct_lobby_id

	var lobby_owner = Steam.getLobbyOwner(slct_lobby_id)
	print("Joined lobby %d successfully" % lobby_id)

	# Create multiplayer peer as CLIENT
	peer = SteamMultiplayerPeer.new()
	peer.create_client(lobby_owner)
	multiplayer.multiplayer_peer = peer

func _on_player_connected(id):
	if not multiplayer.is_server():
		return
	sync_players.rpc()

func _on_peer_disconnected(id):
	pass

@rpc("any_peer", 'call_local')
func sync_players():
	if not Globals.player:
		var steam_id = peer.get_steam_id_for_peer_id(multiplayer.get_unique_id())
		var steam_name = Steam.getFriendPersonaName(steam_id)
		Globals.player = Player.new(multiplayer.get_unique_id(), steam_id, steam_name)
		Globals.players.append(Globals.player)
		Globals.players_by_peer_id[multiplayer.get_unique_id()] = Globals.player
	for peer_id in multiplayer.get_peers():
		if Globals.players_by_peer_id.has(peer_id):
			continue
		var steam_id = peer.get_steam_id_for_peer_id(peer_id)
		var steam_name = Steam.getFriendPersonaName(steam_id)
		var new_player = Player.new(peer_id, steam_id, steam_name)
		Globals.players.append(new_player)
		Globals.players_by_peer_id[peer_id] = new_player



func _process(_delta: float) -> void:
	Steam.run_callbacks()
