extends TextureRect
class_name CardScene

@export var card_data:CardData
enum {PACK,TOOLTIP,MAINDECK, EXTRADECK}
@export var state := PACK

func _on_mouse_entered() -> void:
	EventBus.card_hovered.emit(card_data)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if state == PACK:
				add_self_from_pack_to_deck()
			elif state == MAINDECK or state == EXTRADECK:
				remove_self_from_deck()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			EventBus.card_right_clicked.emit(self)

func add_self_from_pack_to_deck() -> void:
	var pack_index := get_index()
	print("Adding card %s to deck from pack index %d" % [card_data.name, pack_index])
	EventBus.remove_card_from_pack.rpc(pack_index)
	EventBus.add_card_to_deck.emit(card_data)

func remove_self_from_deck() -> void:
	print("Removing card %s from deck" % card_data.name)
	EventBus.remove_card_from_deck.emit(self)
