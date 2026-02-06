extends TextureRect
class_name Card

@export var card_data:CardData
enum {PACK,TOOLTIP,MAINDECK, EXTRADECK}
var state := PACK

func _on_mouse_entered() -> void:
	EventBus.card_hovered.emit(card_data)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			EventBus.card_pressed.emit(self, 0)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			EventBus.card_pressed.emit(self, 1)