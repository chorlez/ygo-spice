extends Node

var cards
var cube: Array[CardData] = []
@onready var RaceLabel = $RaceLabel
@onready var RollRaceButton = $RollRaceButton
@onready var PackContainer = get_parent().get_node('PackPanel/PackContainer')
var race: String
var min_race_size := 100	

func _ready():
	EventBus.start_civil_war.connect(initialize)

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
		print(child.name)
		child.queue_free()

	for card_data in pack:
		var card = Globals.create_card(card_data)
		PackContainer.add_child(card)



func _on_roll_race_button_pressed() -> void:
	create_cube()
	roll_pack()
