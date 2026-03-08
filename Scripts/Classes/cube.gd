extends Node
class_name Cube
var game

var cube: Array[CardData]
var monsters: Array[CardData]
var spells: Array[CardData]
var traps: Array[CardData]
var extras: Array[CardData]
var staples: Array[CardData]

const cubetypes: Array = ['Race','Race Support','Race Archetypes','Attribute','Attribute Support','Attribute Archetypes','Archetype']
var cube_build := {
	'Race': [],
	'Race Support': [],
	'Attribute': [],
	'Attribute Support': [],
	'Archetype': []
}

func _init(game_ref):
	game = game_ref
	EventBus.cube_requested.connect(_on_request_cube)
	EventBus.cube_type_added.connect(on_cube_type_added)
	EventBus.cube_type_removed.connect(on_cube_type_removed)
	EventBus.new_cube_build.connect(compose_cube)
	EventBus.clear_cube.connect(create_master_cube)
	
	
func _on_request_cube():
	print('Cube requested, building cube...')
	create_master_cube()
	EventBus.cube_changed.emit()

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
	EventBus.cube_changed.emit()
	
func compose_cube(build: Dictionary):
	clear()
	cube_build = build
	print('Composing cube with current filters: %s' % str(cube_build))
	
	var has_filters := false
	for v in cube_build.values():
		if v.size() > 0:
			has_filters = true
			break

	if not has_filters:
		create_master_cube()
		return
	# First Race
	for race in cube_build['Race']:
		add_race_cards_to_cube(race)
		add_race_support_cards_to_cube(race)
	for race in cube_build['Race Support']:
		add_race_support_cards_to_cube(race)
	# Then Attribute
	for attribute in cube_build['Attribute']:
		add_attribute_cards_to_cube(attribute)
		add_attribute_support_cards_to_cube(attribute)
	for attribute in cube_build['Attribute Support']:
		add_attribute_support_cards_to_cube(attribute)
	# Then Archetype
	for archetype in cube_build['Archetype']:
		add_archetype_cards_to_cube(archetype)
		add_archetype_support_cards_to_cube(archetype)
	EventBus.cube_changed.emit()
	

func on_cube_type_added(type:String, option:String):
	print('Adding cube type filter: %s - %s' % [type, option])
	if type in cube_build.keys():
		cube_build[type].append(option)
	elif type.replace(' Archetypes','') in cube_build.keys():
		cube_build['Archetype'].append(option)
	EventBus.sync_cube_build.rpc(cube_build.duplicate_deep())

func on_cube_type_removed(type:String, option:String):
	print('Adding cube type filter: %s - %s' % [type, option])
	if cube_build[type].has(option): 
		cube_build[type].remove_at(cube_build[type].find(option))
		
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
		if rand < cumulative and pool.size() > 0:
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
	for key in cube_build.keys():
		cube_build[key] = []

# Populate monster/extra pools from provided cards for the selected race
func add_race_cards_to_cube(race):
	for card in CardDatabase.cards_by_race[race]:
		add_card_to_cube(card)

func add_race_support_cards_to_cube(race):
	for card in CardDatabase.cards:
		if card_mentions_unquoted_word(card.description, race):
			add_card_to_cube(card)

func add_attribute_cards_to_cube(attribute):
	for card in CardDatabase.cards_by_attribute[attribute]:
		add_card_to_cube(card)

func add_attribute_support_cards_to_cube(attribute):
	for card in CardDatabase.cards:
		if card_mentions_unquoted_word(card.description, attribute):
			add_card_to_cube(card)

func add_archetype_cards_to_cube(archetype):
	for card in CardDatabase.cards_by_archetype[archetype]:
		add_card_to_cube(card)

func add_archetype_support_cards_to_cube(archetype):
	for card in CardDatabase.cards:
		if card_mentions_word(card.description, archetype):
			add_card_to_cube(card)

func card_mentions_word(card_description: String, word: String) -> bool:
	var target := word.to_lower()
	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex.search(card_description.to_lower()) != null

func card_mentions_unquoted_word(card_description: String, word: String) -> bool:
	var text := card_description.to_lower()

	# Remove quoted segments first
	var quote_regex := RegEx.new()
	quote_regex.compile("\"[^\"]*\"")
	text = quote_regex.sub(text, "", true)

	var target := word.to_lower()
	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"

	var regex := RegEx.new()
	regex.compile(pattern)

	return regex.search(text) != null
