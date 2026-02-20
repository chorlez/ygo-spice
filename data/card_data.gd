extends Resource
class_name CardData

enum {
	MONSTER,
	SPELL,
	TRAP,
	EXTRA}
	
@export var id: int
@export var name: String
@export var type_name: String
@export var type: int
@export var race: String
@export var archetype: String
@export var level: int
@export var atk: int
@export var def: int
@export var description: String
@export var is_staple: bool = false

var texture: Texture2D = null


func _to_string() -> String:
	return name

func is_extra() -> bool:
	return type == CardData.EXTRA

func is_spell() -> bool:
	return type == CardData.SPELL

func is_trap() -> bool:
	return type == CardData.TRAP

func is_monster() -> bool:
	return type == CardData.MONSTER
	
func print_card_details():
	print("Card ID: %d" % id)
	print("Name: %s" % name)
	print("Type: %s" % type)
	print("Race: %s" % race)
	print("Archetype: %s" % archetype)
	print("Level: %d" % level)
	print("ATK: %d" % atk)
	print("DEF: %d" % def)
	print("Description: %s" % description)  
