extends Node


@onready var game: Node = get_parent()
@onready var RaceMenu: Node = game.get_node('UIPanel/UIlayer/RaceMenu')
@onready var RollRaceButton: Node = game.get_node('UIPanel/UIlayer/RollRaceButton')
@onready var PlayerLabel: Node = game.get_node('UIPanel/UIlayer/PlayerLabel')
@onready var PackContainer: Node = game.get_node('PackPanel/PackContainer')
@onready var MainDeckContainer: Node = game.get_node('MainDeckPanel/ScrollContainer/MainDeckContainer')
@onready var ExtraDeckContainer: Node = game.get_node('ExtraDeckPanel/ExtraDeckContainer')
@onready var TooltipArea: Node = game.get_node('ToolTipPanel/TooltipArea')
@onready var SaveDeckDialog: Node = game.get_node('SaveDeckDialog')

var cards:= {
	'Monsters': [],
	'Spells': [],
	'Extra': [],
	'Staples':[]
}
var cube : Cube = Cube.new()
var race: String
var pack: Array
var min_race_size := 100	
var playerList : Array[Player] = []
var playerDeck: Deck = Deck.new()



func _ready():
	EventBus.start_civil_war.connect(initialize)
	EventBus.card_hovered.connect(show_tooltip)
	EventBus.card_pressed.connect(card_pressed)
	EventBus.player_connected.connect(sync_state)

func initialize():
	cards = Globals.cards
	put_races_in_race_menu()
	roll_race()
	create_cube_and_pack()
	
func put_races_in_race_menu():
	for r in Globals.race_counts.keys():
		RaceMenu.add_item(r)

func roll_race():
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= min_race_size:
			eligible_races.append(race_name)
	race = eligible_races.pick_random()
	rpc("rpc_sync_race", race)
	
@rpc("any_peer","call_local")
func rpc_sync_race(new_race: String):
	race = new_race
	for i in range(RaceMenu.item_count):
		if RaceMenu.get_item_text(i) == race:
			RaceMenu.select(i)

func roll_pack(n=10):
	var new_pack = []
	
	while new_pack.size() < n:
		new_pack.append(int(cube.get_weighted_card()))
	rpc("rpc_sync_pack", new_pack)
	
@rpc("any_peer","call_local")
func rpc_sync_pack(new_pack):
	print(new_pack)
	pack = []
	for card_id in  new_pack:
		pack.append(Globals.cards_by_id[card_id])
	display_pack()
	
func display_pack():
	# Clear old children
	for child in PackContainer.get_children():
		child.queue_free()

	for card_data in pack:
		var card: Card = Globals.create_card(card_data)
		PackContainer.add_child(card)

func create_cube_and_pack():
	cube.create(race)
	roll_pack()
	

func show_tooltip(card_data: CardData):
	for child in TooltipArea.get_children():
		child.queue_free()

	var card: Card = Globals.create_card(card_data)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	TooltipArea.add_child(card)
	var scrollContainer = ScrollContainer.new()
	scrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var descriptionLabel = Label.new()
	descriptionLabel.text = card_data.description
	descriptionLabel.autowrap_mode = 3
	descriptionLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrollContainer.add_child(descriptionLabel)
	TooltipArea.add_child(scrollContainer)
		
func card_pressed(card:Card):
	if card.state == card.PACK:
		var card_index := card.get_index()
		rpc('rpc_remove_card_from_pack', card_index)
		add_card_to_deck(card)

@rpc("any_peer","call_remote")
func rpc_remove_card_from_pack(card_index: int):
	PackContainer.get_child(card_index).queue_free()
		
func add_card_to_deck(card: Card):
	# Move the card
	card.get_parent().remove_child(card)
	if card.card_data.extra_deck:
		playerDeck.extraDeck.append(card.card_data)
		ExtraDeckContainer.add_child(card)
		card.state = 3
	else:
		playerDeck.mainDeck.append(card.card_data)
		MainDeckContainer.add_child(card)
		card.state = 2
	
func add_card_data_to_deck(cardData:CardData):
	# Move the card
	var card: Card = Globals.create_card(cardData) 
	if card.card_data.extra_deck:
		playerDeck.extraDeck.append(card.card_data)
		ExtraDeckContainer.add_child(card)
		card.state = card.EXTRADECK
		
	else:
		playerDeck.mainDeck.append(card.card_data)
		MainDeckContainer.add_child(card)
		card.state = card.MAINDECK

func _on_roll_race_button_pressed() -> void:
	if multiplayer.is_server():
		roll_race()
	else:
		rpc_id(1, "rpc_request_new_cube") # host is peer 1

func _on_roll_pack_button_pressed():
	if multiplayer.is_server():
		roll_pack()
	else:
		rpc_id(1, "rpc_request_new_pack") # host is peer 1

@rpc("any_peer","call_remote")
func rpc_request_new_cube():
	if not multiplayer.is_server():
		return
	roll_race()
	

@rpc("any_peer","call_remote")
func rpc_request_new_pack():
	if not multiplayer.is_server():
		return
	roll_pack()

func _on_save_deck_pressed():
	print('save deck pressed')
	SaveDeckDialog.current_file = "[YuGiBoy]" + race + ".ydk"
	SaveDeckDialog.popup_centered()

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
	if multiplayer.is_server():
		race = RaceMenu.get_item_text(index)
		create_cube_and_pack()


func sync_state():
	print('this syncs')
	rpc("rpc_sync_race", race)
	var sync_pack = []
	for card in pack:
		sync_pack.append(card.id)
	rpc("rpc_sync_pack", sync_pack)

func show_cube_cards(n=100):
	var archetype = 'The Agent'
	var archetype_set = []
	playerDeck.clear()
	if race != 'Illusion':
		return
	print(cube['Monsters'].size())
	for cardtype in cube.keys():
		for cardData in cube[cardtype]:
			if cardData.archetype not in archetype_set:
				archetype_set.append(cardData.archetype)
			if n > 0:
				n -= 1
				add_card_data_to_deck(cardData)
				print(cardData.archetype)
	print(n)
	print(archetype_set)
