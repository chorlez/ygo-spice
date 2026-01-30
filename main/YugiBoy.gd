extends Node


@onready var RaceMenu: Node = get_node('UIPanel/MarginContainer/UIlayer/RaceMenu')
@onready var RollRaceButton: Node = get_node('UIPanel/MarginContainer/UIlayer/RollRaceButton')
@onready var PlayerLabel: Node = get_node('UIPanel/MarginContainer/UIlayer/PlayerLabel')
@onready var PackContainer: Node = get_node('PackPanel/PackContainer')
@onready var MainDeckContainer: Node = get_node('MainDeckPanel/ScrollContainer/MainDeckContainer')
@onready var ExtraDeckContainer: Node = get_node('ExtraDeckPanel/ExtraDeckContainer')
@onready var TooltipArea: Node = get_node('ToolTipPanel/TooltipArea')
@onready var SaveDeckDialog: Node = get_node('SaveDeckDialog')
# optional sort-mode button (use get_node_or_null so it's safe if the scene doesn't have it yet)
@onready var SortModeButton: Button = get_node_or_null('UIPanel/MarginContainer/UIlayer/SortModeButton')

var cube : Cube = Cube.new()
var pack: Pack =  Pack.new()

var race: String

var min_race_size := 100	
var playerList : Array[Player] = []

var default_filename := ""

# The player whose deck is currently being displayed in the UI
var current_shown_player: Player = null

# Deck sorting state: ADDED keeps insertion order, YUGI_ORDER shows monsters first (highest level), then spells, then others
enum DeckSort { ADDED, YUGI_ORDER }
var deck_sort_mode := DeckSort.ADDED

func _ready():
	EventBus.start_civil_war.connect(initialize)
	EventBus.card_hovered.connect(show_tooltip)
	EventBus.card_pressed.connect(card_pressed)
	# When a player is selected in the lobby, show their deck
	EventBus.player_selected.connect(on_player_selected)
	# Hook up sort button if present
	if SortModeButton:
		SortModeButton.pressed.connect(_on_sort_mode_button_pressed)
		update_sort_button_text()
	# If we already know the local client player, show their deck by default
	if Globals.client_player != null:
		show_player_deck()

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
	rpc("rpc_sync_race", race)
	create_cube_create_pack()
	
@rpc("any_peer","call_local")
func rpc_sync_race(new_race: String):
	race = new_race
	for i in range(RaceMenu.item_count):
		if RaceMenu.get_item_text(i) == race:
			RaceMenu.select(i)

func create_cube_create_pack():
	cube.create(race)
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
	for child in TooltipArea.get_children():
		child.queue_free()

	var card: Card = Globals.create_card(card_data)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.state = card.TOOLTIP
	TooltipArea.add_child(card)
	var scrollContainer = ScrollContainer.new()
	scrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var descriptionLabel = Label.new()
	descriptionLabel.text = card_data.description
	descriptionLabel.autowrap_mode = 3
	descriptionLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	descriptionLabel.add_theme_font_size_override('font_size',40)
	scrollContainer.add_child(descriptionLabel)
	TooltipArea.add_child(scrollContainer)
		
func card_pressed(card:Card):
	if card.state == card.PACK:
		var card_index_in_pack := card.get_index()
		rpc('rpc_add_card_from_pack_to_deck', card_index_in_pack, Globals.client_player.steam_id)


@rpc("any_peer","call_local")
func rpc_add_card_from_pack_to_deck(card_index: int, player_steam_id:int):
	var card = PackContainer.get_child(card_index)
	var player: Player = Globals.get_player_by_steam_id(player_steam_id)
	add_card_to_deck(card, player)



func add_card_to_deck(card: Card, player: Player):
	# Move the card
	if card.card_data.extra_deck:
		player.deck.extraDeck.append(card.card_data)
	else:
		player.deck.mainDeck.append(card.card_data)
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
func rpc_request_new_cube():
	if not multiplayer.is_server():
		return
	create_cube_create_pack()

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
	var ydk_text := build_ydk_string()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save deck")
		return

	file.store_string(ydk_text)
	file.close()

	print("Deck saved to:", path)

func build_ydk_string() -> String:
	var lines := []

	lines.append("#created by My Cube Draft App YuGiBoy")
	lines.append("#main")

	for card_node in MainDeckContainer.get_children():
		if card_node.card_data:
			lines.append(str(card_node.card_data.id))

	lines.append("#extra")

	for card_node in ExtraDeckContainer.get_children():
		if card_node.card_data:
			lines.append(str(card_node.card_data.id))

	lines.append("!side")

	return "\n".join(lines)
	
func _on_race_menu_item_selected(index: int) -> void:
	var race_to_sync = RaceMenu.get_item_text(index)
	rpc("rpc_sync_race", race_to_sync)
	rpc("rpc_request_new_cube")

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
	for card_data in current_shown_player.deck.sort_main_for_display(deck_sort_mode):
		var card_node: Card = Globals.create_card(card_data)
		card_node.state = card_node.MAINDECK
		MainDeckContainer.add_child(card_node)

	# Create visual nodes for extra deck
	for card_data in current_shown_player.deck.sort_extra_for_display(deck_sort_mode):
		var card_node: Card = Globals.create_card(card_data)
		card_node.state = card_node.EXTRADECK
		ExtraDeckContainer.add_child(card_node)



func _on_sort_mode_button_pressed() -> void:
	deck_sort_mode = (deck_sort_mode + 1) % 2
	update_sort_button_text()
	show_player_deck()

func update_sort_button_text() -> void:
	if not SortModeButton:
		return
	if deck_sort_mode == DeckSort.ADDED:
		SortModeButton.text = "Sort: Added"
	else:
		SortModeButton.text = "Sort: YGO"

func sync_state():
	rpc("rpc_sync_race", race)
	rpc("rpc_display_pack", pack.cardIDs)
