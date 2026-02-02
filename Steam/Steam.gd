extends Control

# THIS VERSION WILL ONLY HAVE ONE LOBBY AND AUTO CREATE / AUTO JOIN
var lobby_id := 0
var peer = SteamMultiplayerPeer.new()
var lobby_died := false

var game_name:= "YugiBoy"
var player_list = []

@onready var Game:= get_parent()
@onready var ReconnectButton := Game.get_node('UIPanel/MarginContainer/UIlayer/ReconnectButton')

func _ready():
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	Steam.steamInitEx()

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	find_or_create_lobby()

	multiplayer.connect("peer_connected", _on_player_connected)
	multiplayer.connect("peer_disconnected", _on_peer_disconnected)
	multiplayer.connect("connection_failed", _on_connection_failed)
	multiplayer.connect("server_disconnected",_on_server_disconnected)
	

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func find_or_create_lobby():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game_tag", game_name, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies):
	print("Found %d lobbies" % lobbies.size())
	if lobbies.size() == 0 or lobby_died:
		host_lobby()
		lobby_died = false
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
	lobby_id = slct_lobby_id

	var lobby_owner = Steam.getLobbyOwner(slct_lobby_id)

	ReconnectButton.visible = false
	if lobby_owner == Steam.getSteamID():
		get_lobby_players()
		return

	print("Joined lobby %d successfully" % lobby_id)

	# Create multiplayer peer as CLIENT
	peer = SteamMultiplayerPeer.new()
	peer.create_client(lobby_owner)
	multiplayer.multiplayer_peer = peer

func get_lobby_players():
	player_list = [{'peer_id':get_tree().get_multiplayer().get_unique_id(), 'steam_id':Steam.getSteamID(), 'steam_name':Steam.getPersonaName()}]
	var names:= Steam.getPersonaName() + ' | '
	for peer_id in multiplayer.get_peers():
		var steam_id = peer.get_steam_id_for_peer_id(peer_id)
		var steam_name = Steam.getFriendPersonaName(steam_id)
		player_list.append({'peer_id':peer_id, 'steam_id':steam_id, 'steam_name':steam_name})
		names += steam_name + ' | '
	print('I fetched player names: ', names)
	
	# Ensure Globals.playerList contains Player objects for every lobby player
	for pinfo in player_list:
		var found: Player = null
		for existing in Globals.playerList:
			if existing.steam_id == pinfo['steam_id']:
				found = existing
				break
		if found != null:
			# Update peer_id and name in case they changed
			found.peer_id = pinfo['peer_id']
			found.player_name = pinfo['steam_name']
		else:
			# Create new Player and initialize its Deck
			var new_player: Player = Player.new()
			new_player.steam_id = pinfo['steam_id']
			new_player.player_name = pinfo['steam_name']
			new_player.peer_id = pinfo['peer_id']
			new_player.deck = Deck.new()
			Globals.playerList.append(new_player)
			if pinfo['steam_id'] == Steam.getSteamID():
				Globals.client_player = new_player
	
	create_player_buttons()

func create_player_buttons():
	var player_container = Game.get_node('UIPanel/MarginContainer/UIlayer/PlayerContainer')
	var existing_buttons = player_container.get_children()
	for btn in existing_buttons:
		btn.queue_free()
	
	# Create one toggle button per player, connect pressed to a handler that will emit EventBus.player_selected
	for player in player_list:
		var btn = Button.new()
		btn.text = player['steam_name']
		btn.toggle_mode = true
		# Pass steam_name and the button as extra args to the handler by binding them to the callable
		btn.connect("pressed", Callable(self, "_on_player_button_pressed").bind(player['steam_name'], btn))
		btn.add_theme_font_size_override("font_size", 40)
		player_container.add_child(btn)
		
		# If this button corresponds to the local player, press it and emit selection immediately
		if player['steam_id'] == Steam.getSteamID():
			btn.set_pressed(true)
			# ensure UI and listeners react to this selection
			_on_player_button_pressed(player['steam_name'], btn)
	

func _on_player_button_pressed(steam_name: String, btn: Button) -> void:
	# Ensure only one button is pressed at a time
	var player_container = Game.get_node('UIPanel/MarginContainer/UIlayer/PlayerContainer')
	for child in player_container.get_children():
		if child is Button and child != btn:
			child.set_pressed(false)
	# Ensure the pressed button stays pressed
	btn.set_pressed(true)
	# Emit the selection for other systems (e.g., to display that player's deck)
	EventBus.player_selected.emit(steam_name)


func _on_player_connected(id):
	var steam_id = peer.get_steam_id_for_peer_id(id)
	print("Player connected: %s" % Steam.getFriendPersonaName(steam_id))
	EventBus.player_connected.emit()
	get_lobby_players()

func _on_peer_disconnected(id: int):
	get_lobby_players()
	var steam_id = peer.get_steam_id_for_peer_id(id)
	print("Player diconnected: %s" % Steam.getFriendPersonaName(steam_id))
	
func _on_connection_failed():
	get_lobby_players()
	ReconnectButton.visible = true
	print('Connection Failed')

func _on_server_disconnected():
	lobby_died = true
	lobby_id = 0
	get_lobby_players()
	ReconnectButton.visible = true
	print('server disconnected')

func _on_reconnect_pressed():
	find_or_create_lobby()
