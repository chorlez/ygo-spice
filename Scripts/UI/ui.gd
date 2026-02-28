extends Control

@onready var RollPackButton = $UIPanel/VBoxContainer/TopUILayer/RollPackButton
@onready var SortModeButton = $UIPanel/VBoxContainer/TopUILayer/SortModeButton
@onready var ClearDeckButton = $UIPanel/VBoxContainer/TopUILayer/ClearDeck
@onready var SaveDeckButton = $UIPanel/VBoxContainer/TopUILayer/SaveDeck
@onready var LoadDeckButton = $UIPanel/VBoxContainer/BottomUILayer/LoadDeck

@onready var LogLabel = $UIPanel/VBoxContainer/BottomUILayer/LogLabel

var ygo_sort: bool = false
var log_card_id: int = -1

func _ready() -> void:
	RollPackButton.pressed.connect(_on_roll_pack_pressed)
	SortModeButton.pressed.connect(_on_sort_mode_pressed)
	ClearDeckButton.pressed.connect(_on_clear_deck_pressed)
	SaveDeckButton.pressed.connect(_on_save_deck_pressed)
	LoadDeckButton.pressed.connect(_on_load_deck_pressed)
	
	EventBus.card_add_log.connect(log_card_added)
	EventBus.card_remove_log.connect(log_card_removed)
	LogLabel.mouse_entered.connect(_on_log_label_mouse_entered)
	
	
func log_card_added(card_id: int, steam_name: String) -> void:
	var card_data = CardDatabase.get_card_by_id(card_id)
	log_card_id = card_id
	if card_data:
		LogLabel.text = "%s added %s to the deck" % [steam_name, card_data.name]
	else:
		LogLabel.text = "%s added an unknown card (ID: %d) to the deck" % [steam_name, card_id]

func log_card_removed(card_id: int, steam_name: String) -> void:
	var card_data = CardDatabase.get_card_by_id(card_id)
	log_card_id = card_id
	if card_data:
		LogLabel.text = "%s removed %s from the deck" % [steam_name, card_data.name]
	else:
		LogLabel.text = "%s removed an unknown card (ID: %d) from the deck" % [steam_name, card_id]

func _on_log_label_mouse_entered() -> void:
	EventBus.card_hovered.emit(log_card_id)	

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
