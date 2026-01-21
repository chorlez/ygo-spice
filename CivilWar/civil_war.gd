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
var cube := {
	'Monsters': [],
	'Spells': [],
	'Extra': [],
	'Staples':[]
}
var race: String
var min_race_size := 100	
var playerList : Array[Player] = []

var type_weights := {
	"Monsters": 0.45,
	"Spells": 0.35,
	"Extra": 0.1,
	'Staples':0.1
}

func _ready():
	EventBus.start_civil_war.connect(initialize)
	EventBus.card_hovered.connect(show_tooltip)
	EventBus.card_pressed.connect(card_pressed)

func initialize():
	cards = Globals.cards
	put_races_in_race_menu()
	roll_race()
	

func create_cube():
	cube = {
		'Monsters': [],
		'Spells': [],
		'Extra': [],
		'Staples':[]
	}
	add_race_cards_to_cube()
	add_support_cards_to_cube()
	add_staples_to_cube()
	
	roll_pack()


func roll_race():
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= min_race_size:
			eligible_races.append(race_name)
	race = eligible_races.pick_random()
	rpc("rpc_sync_race", race)
	create_cube()

func roll_pack(n=10):
	var pack: Array[int] = []
	while pack.size() < n:
		var roll := randf() # 0.0 – 1.0
		var cumulative := 0.0
		var typ := ''
		for t in ["Monsters", "Spells", "Extra", "Staples"]:
			if roll >= cumulative:
				typ = t
			cumulative += type_weights[t]
		var card : CardData = cube[typ].pick_random()
		pack.append(card.id)
	rpc("rpc_sync_pack", pack)
	
func add_race_cards_to_cube():
	for card in cards['Monsters'] + cards['Extra']:
		if card.race == race:
			if not card.extra_deck:
				cube['Monsters'].append(card)
			else:
				cube['Extra'].append(card)

func add_support_cards_to_cube():
	var archetype_counts := get_archetypes_for_race()
	var archetypes := filter_archetypes(archetype_counts)
	for card in cards['Spells']:
		if card_mentions_exact_race(card):
			cube['Spells'].append(card)
			
		for archetype in archetypes:
			if card_mentions_archetype(card, archetype):
				cube['Spells'].append(card)
					

func card_mentions_exact_race(card: CardData) -> bool:
	var text: String = card.description.to_lower()
	var target := race.to_lower()

	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"

	var regex := RegEx.new()
	regex.compile(pattern)

	return regex.search(text) != null

func get_archetypes_for_race() -> Dictionary:
	var archetypes := {}

	for card in cards['Monsters'] + cards['Extra']:
		if card.race != race:
			continue
		if card.archetype == "":
			continue

		if not archetypes.has(card.archetype):
			archetypes[card.archetype] = 0
		archetypes[card.archetype] += 1

	return archetypes

func filter_archetypes(archetypes: Dictionary, min_size := 5) -> Array:
	var result := []

	for archetype in archetypes.keys():
		if archetypes[archetype] >= min_size:
			result.append(archetype)

	return result

func card_mentions_archetype(card: CardData, archetype: String) -> bool:
	if card.description == "":
		return false

	var text := card.description.to_lower()
	var target := archetype.to_lower()

	var regex := RegEx.new()
	# Match whole archetype name, not inside other words or hyphenated races
	regex.compile("(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)")

	return regex.search(text) != null

func add_staples_to_cube():
	cube['Staples'] = cards['Staples']
	


func show_pack(pack: Array[CardData]):
	# Clear old children
	for child in PackContainer.get_children():
		child.queue_free()

	for card_data in pack:
		var card: Card = Globals.create_card(card_data)
		PackContainer.add_child(card)

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

func put_races_in_race_menu():
	for r in Globals.race_counts.keys():
		RaceMenu.add_item(r)
		
func card_pressed(card):
	if card.state == 0:
		var card_index = card.get_index()
		rpc('rpc_remove_card_from_pack', card_index)
		card.get_parent().remove_child(card)
		if card.card_data.extra_deck:
			ExtraDeckContainer.add_child(card)
			card.state = 3
		else:
			MainDeckContainer.add_child(card)
			card.state = 2
			

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

@rpc("any_peer","call_local")
func rpc_sync_race(new_race: String):
	race = new_race
	for i in range(RaceMenu.item_count):
		if RaceMenu.get_item_text(i) == race:
			RaceMenu.select(i)

@rpc("any_peer","call_local")
func rpc_sync_pack(new_pack):
	var pack: Array[CardData] = []
	for card_id in new_pack:
		pack.append(Globals.cards_by_id[card_id])
	show_pack(pack)

@rpc("any_peer","call_remote")
func rpc_remove_card_from_pack(card_index: int):
	PackContainer.get_child(card_index).queue_free()

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


func _on_race_menu_item_selected(index: int) -> void:
	if multiplayer.is_server():
		race = RaceMenu.get_item_text(index)
		create_cube()
