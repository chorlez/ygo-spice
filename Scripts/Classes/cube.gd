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

func _init(game_ref):
	game = game_ref
	EventBus.cube_requested.connect(_on_request_cube)
	
func _on_request_cube():
	print('Cube requested, building cube...')
	create_master_cube()

func create_master_cube():
	cube = []
	monsters = []
	spells = []
	traps = []
	extras = []
	staples = CardDatabase.staples
	
	for card in CardDatabase.cards_by_id.values():
		if card.type == CardData.MONSTER:
			monsters.append(card)
		elif card.type == CardData.SPELL:
			spells.append(card)
		elif card.type == CardData.TRAP:
			traps.append(card)
		elif card.type == CardData.EXTRA:
			extras.append(card)
	
	cube = monsters + spells + traps + extras + staples

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
