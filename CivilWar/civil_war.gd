extends Node

var cards
var cube: Array[CardData] = []
@onready var RaceLabel = $RaceLabel
@onready var RollRaceButton = $RollRaceButton
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
	for child in $PackContainer.get_children():
		child.queue_free()

	for card in pack:
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(200, 290)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand = true
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		$PackContainer.add_child(tex_rect)


		# Load the image live, auto-update TextureRect
		Globals.load_card_image_to_ui(card, tex_rect)



func _on_roll_race_button_pressed() -> void:
	create_cube()
