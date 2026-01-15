extends Node


@onready var game: Node = get_parent()
@onready var RaceLabel: Node = game.get_node('UIPanel/UIlayer/RaceLabel')
@onready var RollRaceButton: Node = game.get_node('UIPanel/UIlayer/RollRaceButton')
@onready var PlayerLabel: Node = game.get_node('UIPanel/UIlayer/PlayerLabel')
@onready var PackContainer: Node = game.get_node('PackPanel/PackContainer')
@onready var MainDeckContainer: Node = game.get_node('MainDeckPanel/MainDeckContainer')
@onready var ExtraDeckContainer: Node = game.get_node('ExtraDeckPanel/ExtraDeckContainer')
@onready var TooltipArea: Node = game.get_node('ToolTipPanel/TooltipArea')

var cards
var cube: Array[CardData] = []
var race: String
var min_race_size := 100	
var playerList : Array[Player] = []


func _ready():
	EventBus.start_civil_war.connect(initialize)
	EventBus.card_hovered.connect(show_tooltip)
	EventBus.card_pressed.connect(card_pressed)
	EventBus.player_connected.connect(_on_player_connected)

func initialize():
	cards = Globals.cards
	create_cube()
	roll_pack()

func create_cube():
	roll_race()
	cube.clear()
	add_race_cards_to_cube()
	add_support_cards_to_cube()
	# add_staples_to_cube()


func roll_race():
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= min_race_size:
			eligible_races.append(race_name)
	race = eligible_races.pick_random()
	rpc("rpc_sync_race", race)

func roll_pack(n=10):
	var pack: Array[int] = []
	while pack.size() < n:
		var card : CardData = cube.pick_random()
		pack.append(card.id)
	rpc("rpc_sync_pack", pack)
	
func add_race_cards_to_cube():
	for card in cards:
		if card.race == race:
			cube.append(card)

func add_support_cards_to_cube():
	var archetype_counts := get_archetypes_for_race()
	var archetypes := filter_archetypes(archetype_counts)
	for card in cards:
		if not card.type.contains("Monster"):
			if card_mentions_exact_race(card):
				cube.append(card)
				
			for archetype in archetypes:
				if card_mentions_archetype(card, archetype):
					cube.append(card)
					

func card_mentions_exact_race(card: CardData) -> bool:
	var text: String = card.description.to_lower()
	var target := race.to_lower()

	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"

	var regex := RegEx.new()
	regex.compile(pattern)

	return regex.search(text) != null

func get_archetypes_for_race() -> Dictionary:
	var archetypes := {}

	for card in cards:
		if not card.type.contains("Monster"):
			continue
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
	cube += Globals.staples


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
	TooltipArea.add_child(card)

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
		create_cube()
		roll_pack()
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

	create_cube()
	roll_pack()

@rpc("any_peer","call_remote")
func rpc_request_new_pack():
	if not multiplayer.is_server():
		return

	roll_pack()

@rpc("any_peer","call_local")
func rpc_sync_race(new_race: String):
	race = new_race
	RaceLabel.text = 'Race: ' + race

@rpc("any_peer","call_local")
func rpc_sync_pack(new_pack):
	var pack: Array[CardData] = []
	for card_id in new_pack:
		pack.append(Globals.cards_by_id[card_id])
	show_pack(pack)

@rpc("any_peer","call_remote")
func rpc_remove_card_from_pack(card_index: int):
	PackContainer.get_child(card_index).queue_free()

func _on_player_connected(peer_id:int, steam_id:int, player_name:String) -> void:
	var new_player = Player.new()
	new_player.peer_id = peer_id
	new_player.steam_id = steam_id
	new_player.player_name = player_name
	playerList.append(new_player)

	var player_names: Array = []
	for player in playerList:
		player_names.append(player.player_name)

	PlayerLabel.text = '\n'.join(player_names)


