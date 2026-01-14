extends Control

# THIS VERSION WILL ONLY HAVE ONE LOBBY AND AUTO CREATE / AUTO JOIN
var lobby_id := 0
var peer = SteamMultiplayerPeer.new()
var player_names: Array = []
var game_name:= "YugiBoy"


func _ready():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	Steam.steamInitEx()

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	open_lobby_list()
	# Check for players joining
	if is_multiplayer_authority():
		multiplayer.connect("peer_connected", _on_player_connected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()


func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game_tag", game_name, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies):
	print("Found %d lobbies" % lobbies.size())
	if lobbies.size() == 0:
		host_lobby()
	else:
		print("Joining lobby %s" % Steam.getLobbyData(lobbies[0], 'name'))
		join_lobby(lobbies[0])

func host_lobby():
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)  # triggers lobby_created

func join_lobby(id):
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
	else:
		print("Failed to create lobby! oh")

func _on_lobby_joined(slct_lobby_id, _permissions, _locked, response):
	if response != Steam.RESULT_OK:
		print("Failed to join lobby!")
		return

	var lobby_owner = Steam.getLobbyOwner(slct_lobby_id)
	if lobby_owner == Steam.getSteamID():
		EventBus.player_connected.emit(1, lobby_owner, Steam.getPersonaName())
		return
	lobby_id = slct_lobby_id
	print("Joined lobby %d successfully" % lobby_id)

	# Create multiplayer peer as CLIENT
	peer = SteamMultiplayerPeer.new()
	peer.create_client(lobby_owner)
	multiplayer.multiplayer_peer = peer
	
func _on_player_connected(id):
	var steam_id = peer.get_steam_id_for_peer_id(id)
	print("Player connected: %s" % Steam.getFriendPersonaName(steam_id))
	EventBus.player_connected.emit(id, steam_id, Steam.getFriendPersonaName(steam_id))
