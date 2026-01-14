extends Node

var cards
var cube: Array[CardData] = []
@onready var game = get_parent()
@onready var RaceLabel = game.get_node('UIPanel/UIlayer/RaceLabel')
@onready var RollRaceButton = game.get_node('UIPanel/UIlayer/RollRaceButton')
@onready var PlayerLabel = game.get_node('UIPanel/UIlayer/PlayerLabel')
@onready var PackContainer = game.get_node('PackPanel/PackContainer')
@onready var MainDeckContainer = game.get_node('MainDeckPanel/MainDeckContainer')
@onready var ExtraDeckContainer = game.get_node('ExtraDeckPanel/ExtraDeckContainer')
@onready var TooltipArea = game.get_node('ToolTipPanel/TooltipArea')
var race: String
var min_race_size := 100	

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
	add_staples_to_cube()


func roll_race():
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= min_race_size:
			eligible_races.append(race_name)
	race = eligible_races.pick_random()
	RaceLabel.text = 'Race: ' + race

func roll_pack(n=10):
	var pack: Array[CardData] = []
	while pack.size() < n:
		var card : CardData = cube.pick_random()
		pack.append(card)
	show_pack(pack)
	
func add_race_cards_to_cube():
	for card in cards:
		if card.race == race:
			cube.append(card)

func add_staples_to_cube():
	cube += Globals.staples


func show_pack(pack: Array[CardData]):
	# Clear old children
	for child in PackContainer.get_children():
		child.queue_free()

	for card_data in pack:
		var card = Globals.create_card(card_data)
		PackContainer.add_child(card)

func show_tooltip(card_data: CardData):
	for child in TooltipArea.get_children():
		child.queue_free()
	
	var card = Globals.create_card(card_data)
	TooltipArea.add_child(card)

func card_pressed(card):
	if card.state == 0:
		card.get_parent().remove_child(card)
		if card.card_data.extra_deck:
			ExtraDeckContainer.add_child(card)
			card.state = 3
		else:
			MainDeckContainer.add_child(card)
			card.state = 2
			

func _on_roll_race_button_pressed() -> void:
	create_cube()
	roll_pack()

func _on_player_connected(peer_id:int, steam_id:int, player_name:String) -> void:
	print("Player connected: %s" % player_name)
	PlayerLabel.text = player_name