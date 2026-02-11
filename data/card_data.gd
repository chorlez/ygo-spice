extends Resource
class_name CardData

@export var id: int
@export var name: String
@export var typename: String
enum {
	MONSTER,
	SPELL,
	TRAP,
	EXTRA}
@export var type: int
@export var race: String
@export var archetype: String
@export var level: int
@export var atk: int
@export var def: int
@export var extra_deck: bool
@export var description: String
@export var is_staple: bool = false
@export var is_monster: bool = false

var texture: Texture2D = null


func _to_string() -> String:
	return name

func print_card_details():
	print("Card ID: %d" % id)
	print("Name: %s" % name)
	print("Type: %s" % type)
	print("Race: %s" % race)
	print("Archetype: %s" % archetype)
	print("Level: %d" % level)
	print("ATK: %d" % atk)
	print("DEF: %d" % def)
	print("Extra Deck: %s" % str(extra_deck))
	print("Description: %s" % description)  
