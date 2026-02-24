extends Control

@onready var RollPackButton = $UIPanel/MarginContainer/VBoxContainer/TopUILayer/RollPackButton
@onready var SortModeButton = $UIPanel/MarginContainer/VBoxContainer/TopUILayer/SortModeButton
@onready var ClearDeckButton = $UIPanel/MarginContainer/VBoxContainer/TopUILayer/ClearDeck
@onready var SaveDeckButton = $UIPanel/MarginContainer/VBoxContainer/TopUILayer/SaveDeck
@onready var LoadDeckButton = $UIPanel/MarginContainer/VBoxContainer/BottomUILayer/LoadDeck

var ygo_sort: bool = false

func _ready() -> void:
	RollPackButton.pressed.connect(_on_roll_pack_pressed)
	SortModeButton.pressed.connect(_on_sort_mode_pressed)
	ClearDeckButton.pressed.connect(_on_clear_deck_pressed)
	SaveDeckButton.pressed.connect(_on_save_deck_pressed)
	LoadDeckButton.pressed.connect(_on_load_deck_pressed)
	

func _on_roll_pack_pressed() -> void:
	EventBus.open_pack.rpc()

func _on_sort_mode_pressed() -> void:
	EventBus.toggle_sort_mode.emit()

func _on_clear_deck_pressed() -> void:
	EventBus.clear_deck.emit()

func _on_save_deck_pressed() -> void:
	EventBus.save_deck.emit()

func _on_load_deck_pressed() -> void:
	EventBus.load_deck.emit()
