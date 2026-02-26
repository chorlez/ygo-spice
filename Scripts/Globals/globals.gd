extends Node

var game

var player: Player
var players: Array[Player] = []
var players_by_peer_id : Dictionary = {}

func _ready():
	EventBus.card_right_clicked.connect(print_card_details)

func print_card_details(card_scene:CardScene):
	card_scene.card_data.print_card_details()


func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	elif event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		EventBus.mouse_clicked.emit(event.position)
