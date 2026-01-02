extends Node

var cards
@onready var RaceLabel = $RaceLabel
@onready var RollRaceButton = $RollRaceButton
var race: String

func _ready():
	EventBus.start_civil_war.connect(initialize)

func initialize():
	cards = Globals.cards
	roll_race()
	roll_pack()

func roll_race():
	race = get_all_races().pick_random()
	RaceLabel.text = 'Race: ' + race

func roll_pack():
	var pack = get_random_cards_by_race((race))
	show_pack(pack)
	
func get_all_races():
	var races := {}
	for card in cards:
		if card.race:
			races[card.race] = true
	return races.keys()

func get_random_cards_by_race(race, count := 10) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in cards:
		if card.race == race:
			pool.append(card)
			pool.shuffle()
	return pool.slice(0, count)

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
	roll_race()
	roll_pack()
