extends Node

@onready var CubeTypeMenu: Node = $UIPanel/MarginContainer/UIlayer/CubeTypeMenu
@onready var RaceCubeContainer: Node = $UIPanel/MarginContainer/UIlayer/RaceCube
@onready var RaceMenu: Node = get_node('UIPanel/MarginContainer/UIlayer/RaceCube/RaceMenu')
@onready var ArchetypeCubeContainer: Node = $UIPanel/MarginContainer/UIlayer/ArchetypeCube
@onready var ArchetypeCountMenu: Node = $UIPanel/MarginContainer/UIlayer/ArchetypeCube/ArchetypeCountMenu
@onready var ArchetypeContainer: Node = $UIPanel/MarginContainer/UIlayer/ArchetypeCube/ArchetypeContainer
@onready var RandomCubeButton: Node = get_node('UIPanel/MarginContainer/UIlayer/RandomCubeButton')
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

var cube : Cube
var pack: Pack = Pack.new()

var race: String
var archetypes: Array[String] = []

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
	EventBus.request_new_cube.connect(_on_cube_requested)
	LastAddedLabel.mouse_entered.connect(_on_last_added_hovered)
	ClearDeckButton.pressed.connect(clear_deck)
	LoadDeckButton.pressed.connect(load_deck)
	RandomCubeButton.pressed.connect(_on_random_cube_button_pressed)
	CubeTypeMenu.item_selected.connect(_on_cubetype_menu_item_selected)
	ArchetypeCountMenu.item_selected.connect(_on_archetype_count_menu_item_selected)
	# When a player is selected in the lobby, show their deck
	EventBus.player_selected.connect(on_player_selected)
	# Hook up sort button if present
	if SortModeButton:
		SortModeButton.pressed.connect(_on_sort_mode_button_pressed)
	# If we already know the local client player, show their deck by default

func initialize():
	populate_menus()

	if not multiplayer.is_server():
		return
	EventBus.player_connected.connect(sync_state)
	
	create_cube.rpc()

@rpc("any_peer","call_local")
func create_cube(cube_type: int = CubeTypeMenu.get_selected_id()):
	RaceCubeContainer.visible = cube_type == Cube.Race
	ArchetypeCubeContainer.visible = cube_type == Cube.Archetype
	cube = Cube.new(cube_type, self)
	update_deck_count_label()
	if multiplayer.is_server():
		create_pack()

@rpc("any_peer","call_local")
func create_pack():
	if not multiplayer.is_server():
		return
	pack.create(cube)
	display_pack.rpc(pack.cardIDs)

@rpc("any_peer","call_local")
func display_pack(syncPack: Array[int]):
	for child in PackContainer.get_children():
		child.queue_free()
	for cardID in syncPack:
		var card: Card = Globals.create_card(Globals.cardData_by_id[cardID])
		PackContainer.add_child(card)

func card_pressed(card:Card, index: int):
	if index == 0: # left click
		if card.state == card.PACK:
			var card_index_in_pack := card.get_index()
			add_card_from_pack_to_deck.rpc(card_index_in_pack, Globals.client_player.steam_id)
		elif card.state == card.MAINDECK or card.EXTRADECK:
			return_card_from_deck_to_pack(card)
	elif index == 1: # right click
		print("Right clicked on card: %s" % card.card_data.name)
		card.card_data.print_card_details()

@rpc("any_peer","call_local")
func add_card_from_pack_to_deck(card_index: int, player_steam_id:int):
	var card = PackContainer.get_child(card_index)
	var player: Player = Globals.get_player_by_steam_id(player_steam_id)
	add_card_to_deck(card, player)
	update_log.rpc(card.card_data.id, player.player_name, "added")


func add_card_to_deck(card: Card, player: Player):
	# Move the card
	player.deck.add(card.card_data)
	card.queue_free()
	show_player_deck()

func return_card_from_deck_to_pack(card:Card):
	add_card_to_pack.rpc(card.card_data.id)
	Globals.client_player.deck.remove(card.card_data)
	card.queue_free()
	update_log.rpc(card.card_data.id, Globals.client_player.player_name,  "returned")

		
@rpc("any_peer","call_local")
func add_card_to_pack(card_id: int):
	var cardData:CardData = Globals.cardData_by_id.get(card_id)
	if cardData:
		var card: Card = Globals.create_card(cardData)
		PackContainer.add_child(card)




func add_card_data_to_deck(cardData:CardData, player:Player):
	if cardData.extra_deck:
		player.deck.extraDeck.append(cardData)
	else:
		player.deck.mainDeck.append(cardData)
	show_player_deck()

func show_tooltip(card_data: CardData):
	TooltipCard.card_data = card_data
	Globals.load_card_image_to_ui(card_data, TooltipCard)
	TooltipCard.state = Card.TOOLTIP
	CardDescriptionLabel.text = card_data.description
	LevelLabel.text = "Lvl: " + str(card_data.level) + ' ' if card_data.is_monster else ""


func _on_cubetype_menu_item_selected(index: int) -> void:
	change_selected_cubetype.rpc(index)
	create_cube.rpc(index)


func _on_race_menu_item_selected(index: int) -> void:
	var race_to_sync = RaceMenu.get_item_text(index)
	change_selected_race.rpc(race_to_sync)
	create_cube.rpc(Cube.Race)
	
func _on_roll_pack_button_pressed():
	create_pack.rpc()
		
func _on_random_cube_button_pressed() -> void:
	race = ''
	archetypes = []
	create_cube.rpc()

func _on_archetype_count_menu_item_selected(index: int) -> void:
	archetypes = []
	create_cube.rpc(Cube.Archetype)

func _on_cube_requested(index: int):
	create_cube.rpc(index)

@rpc("any_peer","call_local")
func change_selected_cubetype(index: int):
	CubeTypeMenu.select(index)

@rpc("any_peer","call_local")
func change_selected_race(new_race: String):
	race = new_race
	var popup = RaceMenu.get_popup()
	
	for i in popup.item_count:
		if popup.get_item_text(i) == new_race:
			RaceMenu.select(i)
			break

@rpc("any_peer","call_local")
func change_selected_archetypes(new_archetypes: Array[String]):
	archetypes = new_archetypes
	# no need to sync archetype selection in the UI since it's always derived from

func _on_save_deck_pressed():
	default_filename = "[YuGiBoy]" + race + ".ydk"
	SaveDeckDialog.current_dir = Settings.get_last_deck_path()
	SaveDeckDialog.current_file = default_filename
	SaveDeckDialog.popup_centered()

func _on_save_deck_dialog_dir_selected(dir):
	if SaveDeckDialog.current_file.is_empty():
		SaveDeckDialog.current_file = default_filename

func _on_save_deck_dialog_file_selected(path: String):
	var dir := path.get_base_dir()
	Settings.set_last_deck_path(dir)
	current_shown_player.deck.save(path)
	


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
	var cube_count := cube.cube.size() if cube else 0
	var main_count := current_shown_player.deck.mainDeck.size()
	var extra_count := current_shown_player.deck.extraDeck.size()
	DeckCountLabel.text = "Cube: %d | Deck: %d | Main: %d | Extra: %d" % [cube_count, main_count + extra_count, main_count, extra_count]
	
@rpc("any_peer","call_local")
func update_log(card_id: int, player:String, action: String):
	var card = Globals.cardData_by_id.get(card_id)
	var cardname = card.name if card else "Unknown Card"
	LastAddedLabel.text = "%s %s: %s" % [player, action, cardname]
	current_added_card = card
	
func _on_last_added_hovered():
	EventBus.card_hovered.emit(current_added_card)
	
func sync_state():
	rpc("rpc_sync_race", race)
	rpc("rpc_display_pack", pack.cardIDs)

func load_deck():
	Globals.client_player.deck.load_deck()
	show_player_deck()

func populate_menus():
	for r in Globals.race_counts.keys():
		RaceMenu.add_item(r)
	for c in Cube.cube_types:
		if c != 'MasterCube':
			CubeTypeMenu.add_item(c)
