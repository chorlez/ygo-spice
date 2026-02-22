extends Control

@onready var RollPackButton = $UIPanel/MarginContainer/VBoxContainer/TopUILayer/RollPackButton

func _ready() -> void:
	RollPackButton.pressed.connect(_on_roll_pack_pressed)

func _on_roll_pack_pressed() -> void:
	EventBus.open_pack.rpc()
