extends Node


@onready var RaceMenu: Node = get_node('UIPanel/MarginContainer/UIlayer/RaceMenu')
@onready var RollRaceButton: Node = get_node('UIPanel/MarginContainer/UIlayer/RollRaceButton')
@onready var DeckCountLabel: Node = $ToolTipPanel/TooltipArea/StatsBox/DeckCountLabel
@onready var LevelLabel: Node = $ToolTipPanel/TooltipArea/StatsBox/LevelLabel
@onready var CardDescriptionLabel: Node = $ToolTipPanel/TooltipArea/ScrollContainer/CardDescriptionLabel
@onready var LastAddedLabel: Node = get_node('UIPanel/MarginContainer/UIlayer/LastAddedLabel')
@onready var PackContainer: Node = get_node('PackPanel/PackContainer')
@onready var MainDeckContainer: Node = get_node('MainDeckPanel/ScrollContainer/MainDeckContainer')
@onready var ExtraDeckContainer: Node = get_node('ExtraDeckPanel/ScrollContainer/ExtraDeckContainer')
@onready var TooltipCard: Node = $ToolTipPanel/TooltipArea/TooltipCard
@onready var SaveDeckDialog: Node = get_node('SaveDeckDialog')
# optional sort-mode button (use get_node_or_null so it's safe if the scene doesn't have it yet)
@onready var SortModeButton: Button = get_node_or_null('UIPanel/MarginContainer/UIlayer/SortModeButton')
@onready var ClearDeckButton: Button = get_node('UIPanel/MarginContainer/UIlayer/ClearDeck')
@onready var LoadDeckButton: Button = get_node('UIPanel/MarginContainer/UIlayer/LoadDeck')
@onready var search_input: LineEdit = get_node_or_null('UIPanel/MarginContainer/UIlayer/SearchInput')

var cube : Cube = Cube.new()
var pack: Pack =  Pack.new()

var race: String

var min_race_size := 100	
var playerList : Array[Player] = []

var default_filename := ""

# The player whose deck is currently being displayed in the UI
var current_shown_player: Player = null
var current_added_card: CardData = null

func _ready():
	EventBus.start_civil_war.connect(initialize)
	EventBus.card_hovered.connect(show_tooltip)
	EventBus.card_pressed.connect(card_pressed)
	LastAddedLabel.mouse_entered.connect(_on_last_added_hovered)
	ClearDeckButton.pressed.connect(clear_deck)
	LoadDeckButton.pressed.connect(load_deck)
	# When a player is selected in the lobby, show their deck
	EventBus.player_selected.connect(on_player_selected)
	# Hook up sort button if present
	if SortModeButton:
		SortModeButton.pressed.connect(_on_sort_mode_button_pressed)
	# If we already know the local client player, show their deck by default

func initialize():
	put_races_in_race_menu()

	if not multiplayer.is_server():
		return
	EventBus.player_connected.connect(sync_state)
	
	roll_race_create_cube_create_pack()
	
func put_races_in_race_menu():
	for r in Globals.race_counts.keys():
		RaceMenu.add_item(r)

func roll_race_create_cube_create_pack():
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= min_race_size:
			eligible_races.append(race_name)
	race = eligible_races.pick_random()
	rpc("rpc_sync_create_cube", race)
	
	
@rpc("any_peer","call_local")
func rpc_sync_create_cube(new_race: String):
	race = new_race
	for i in range(RaceMenu.item_count):
		if RaceMenu.get_item_text(i) == race:
			RaceMenu.select(i)
	cube.create(race, search_input)
	if multiplayer.is_server():
		create_pack()

func create_pack():
	pack.create(cube)
	rpc("rpc_display_pack", pack.cardIDs)

@rpc("any_peer","call_local")
func rpc_display_pack(syncPack: Array[int]):
	for child in PackContainer.get_children():
		child.queue_free()
	for cardID in syncPack:
		var card: Card = Globals.create_card(Globals.cardData_by_id[cardID])
		PackContainer.add_child(card)

func show_tooltip(card_data: CardData):
	TooltipCard.card_data = card_data
	TooltipCard.texture = card_data.texture
	TooltipCard.state = Card.TOOLTIP
	CardDescriptionLabel.text = card_data.description
	LevelLabel.text = "Lvl: " + str(card_data.level) if card_data.is_monster else ""

		
func card_pressed(card:Card, index: int):
	if index == 0: # left click
		if card.state == card.PACK:
			var card_index_in_pack := card.get_index()
			rpc('rpc_add_card_from_pack_to_deck', card_index_in_pack, Globals.client_player.steam_id)
	elif index == 1: # right click
		print("Right clicked on card: %s" % card.card_data.name)
		card.card_data.print_card_details()


@rpc("any_peer","call_local")
func rpc_add_card_from_pack_to_deck(card_index: int, player_steam_id:int):
	var card = PackContainer.get_child(card_index)
	var player: Player = Globals.get_player_by_steam_id(player_steam_id)
	add_card_to_deck(card, player)
	update_last_added_card(card, player)


func add_card_to_deck(card: Card, player: Player):
	# Move the card
	player.deck.add(card.card_data)
	card.queue_free()
	show_player_deck()

func add_card_data_to_deck(cardData:CardData, player:Player):
	if cardData.extra_deck:
		player.deck.extraDeck.append(cardData)
	else:
		player.deck.mainDeck.append(cardData)
	show_player_deck()

func _on_roll_race_button_pressed() -> void:
	rpc("rpc_request_random_cube")

@rpc("any_peer","call_local")
func rpc_request_random_cube():
	if not multiplayer.is_server():
		return
	roll_race_create_cube_create_pack()

func _on_roll_pack_button_pressed():
	rpc( "rpc_request_new_pack")

@rpc("any_peer","call_local")
func rpc_request_new_pack():
	if not multiplayer.is_server():
		return
	create_pack()

func _on_save_deck_pressed():
	default_filename = "[YuGiBoy]" + race + ".ydk"
	SaveDeckDialog.current_file = default_filename
	SaveDeckDialog.popup_centered()

func _on_save_deck_dialog_dir_selected(dir):
	if SaveDeckDialog.current_file.is_empty():
		SaveDeckDialog.current_file = default_filename

func _on_save_deck_dialog_file_selected(path: String):
	current_shown_player.deck.save(path)

	
func _on_race_menu_item_selected(index: int) -> void:
	var race_to_sync = RaceMenu.get_item_text(index)
	rpc("rpc_sync_create_cube", race_to_sync)

func on_player_selected(steam_name: String) -> void:
	# Find the Player instance by name and display their deck
	current_shown_player = Globals.get_player_by_steam_name(steam_name)
	show_player_deck()

func show_player_deck() -> void:
	# Clear current UI
	for child in MainDeckContainer.get_children():
		child.queue_free()
	for child in ExtraDeckContainer.get_children():
		child.queue_free()


	# Create visual nodes for main deck (use sorted display order so we don't mutate player's deck)
	for card_data in current_shown_player.deck.sort_main_for_display():
		var card_node: Card = Globals.create_card(card_data)
		card_node.state = card_node.MAINDECK
		MainDeckContainer.add_child(card_node)

	# Create visual nodes for extra deck
	for card_data in current_shown_player.deck.sort_extra_for_display():
		var card_node: Card = Globals.create_card(card_data)
		card_node.state = card_node.EXTRADECK
		ExtraDeckContainer.add_child(card_node)
	
	update_deck_count_label()

func clear_deck():
	current_shown_player.deck.clear()
	show_player_deck()

func _on_sort_mode_button_pressed() -> void:
	var mode = current_shown_player.deck.change_sort()
	SortModeButton.text = "Sort: " + mode
	show_player_deck()


func update_deck_count_label():
	var main_count := current_shown_player.deck.mainDeck.size()
	var extra_count := current_shown_player.deck.extraDeck.size()
	DeckCountLabel.text = "Deck: %d | Main: %d | Extra: %d" % [main_count + extra_count, main_count, extra_count]
	
func update_last_added_card(card: Card, player:Player):
	LastAddedLabel.text = "%s added: %s" % [player.player_name, card.card_data.name]
	current_added_card = card.card_data
	
func _on_last_added_hovered():
	EventBus.card_hovered.emit(current_added_card)
	
func sync_state():
	rpc("rpc_sync_race", race)
	rpc("rpc_display_pack", pack.cardIDs)

func load_deck():
	Globals.client_player.deck.load_deck()
	show_player_deck()
