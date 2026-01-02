extends Resource
class_name CardData

@export var id: int
@export var name: String
@export var type: String
@export var race: String
@export var archetype: String
@export var level: int
@export var atk: int
@export var def: int
@export var extra_deck: bool

var texture: Texture2D = null


func _to_string() -> String:
	return name
