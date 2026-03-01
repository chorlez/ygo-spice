extends Node
class_name Cube
var game

var cube: Array[CardData]
var monsters: Array[CardData]
var spells: Array[CardData]
var traps: Array[CardData]
var extras: Array[CardData]
var staples: Array[CardData]

const cubetypes: Array = ['Race','Attribute','Archetype']
var cube_build := {
	'Race': [],
	'Attribute': [],
	'Archetype': []
}

func _init(game_ref):
	game = game_ref
	EventBus.cube_requested.connect(_on_request_cube)
	EventBus.cube_type_added.connect(on_cube_type_added)
	EventBus.new_cube_build.connect(compose_cube)
	
func _on_request_cube():
	print('Cube requested, building cube...')
	create_master_cube()
	EventBus.cube_changed.emit(self)

func add_card_to_cube(card: CardData):
	if card.type == CardData.MONSTER:
		monsters.append(card)
	elif card.type == CardData.SPELL:
		spells.append(card)
	elif card.type == CardData.TRAP:
		traps.append(card)
	elif card.type == CardData.EXTRA:
		extras.append(card)
	cube.append(card)

func create_master_cube():
	clear()	
	for card in CardDatabase.cards_by_id.values():
		add_card_to_cube(card)
	
func compose_cube(build: Dictionary):
	cube_build = build
	print('Composing cube with current filters: %s' % str(cube_build))
	clear()
	# First Race
	for race in cube_build['Race']:
		if not race[1]: # support only
			add_race_cards_to_cube(race[0])
		add_race_support_cards_to_cube(race[0])
	# Then Attribute
	for attribute in cube_build['Attribute']:
		if not attribute[1]: # support only
			add_attribute_cards_to_cube(attribute[0])
		add_attribute_support_cards_to_cube(attribute[0])
	# Then Archetype
	for archetype in cube_build['Archetype']:
		if not archetype[1]: # support only
			add_archetype_cards_to_cube(archetype[0])
		add_archetype_support_cards_to_cube(archetype[0])
	EventBus.cube_changed.emit(self)
	

func on_cube_type_added(type:String, option:String, support_only: bool):
	print('Adding cube type filter: %s - %s' % [type, option])
	if type in cubetypes:
		cube_build[type].append([option, support_only])
	EventBus.sync_cube_build.rpc(cube_build)


func get_random_card_id() -> int:
	var card_distribution := {
		monsters: 0.45,
		spells: 0.2,
		traps: 0.15,
		extras: 0.1,
		staples:0.1
	}
	var rand := randf()
	var cumulative := 0.0
	for pool in card_distribution.keys():
		cumulative += card_distribution[pool]
		if rand < cumulative:
			var card = pool[randi() % pool.size()]
			return card.id
	print('Error: Random card selection failed, defaulting to random card from cube')
	return cube[randi() % cube.size()].id

func clear():
	cube = []
	monsters = []
	spells = []
	traps = []
	extras = []
	staples = CardDatabase.staples

# Populate monster/extra pools from provided cards for the selected race
func add_race_cards_to_cube(race):
	for card in CardDatabase.cards_by_race[race]:
		add_card_to_cube(card)

func add_race_support_cards_to_cube(race):
	for card in CardDatabase.cards:
		if card_mentions_word(card.description, race):
			add_card_to_cube(card)

func card_mentions_word(card_description: String, word: String) -> bool:
	var target := word.to_lower()
	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex.search(card_description.to_lower()) != null

func add_attribute_cards_to_cube(attribute):
	for card in CardDatabase.cards_by_attribute[attribute]:
		add_card_to_cube(card)

func add_attribute_support_cards_to_cube(attribute):
	for card in CardDatabase.cards:
		if card_mentions_word(card.description, attribute):
			add_card_to_cube(card)

func add_archetype_cards_to_cube(archetype):
	for card in CardDatabase.cards_by_archetype[archetype]:
		add_card_to_cube(card)

func add_archetype_support_cards_to_cube(archetype):
	for card in CardDatabase.cards:
		if card_mentions_word(card.description, archetype):
			add_card_to_cube(card)
