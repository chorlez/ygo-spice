extends TextureRect
class_name CardScene

@export var card_data:CardData
enum CardState {PACK,TOOLTIP,MAINDECK, EXTRADECK}
const PACK: int = CardState.PACK
const TOOLTIP: int = CardState.TOOLTIP
const MAINDECK: int = CardState.MAINDECK
const EXTRADECK: int = CardState.EXTRADECK

@export var state : CardState


func _on_mouse_entered() -> void:
	EventBus.card_hovered.emit(card_data.id)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if state == PACK:
				move_from_pack_to_deck()
			elif state == MAINDECK or state == EXTRADECK:
				move_from_deck_to_pack()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			EventBus.card_right_clicked.emit(self)

func move_from_pack_to_deck() -> void:
	var pack_index := get_index()
	print("Adding card %s to deck from pack index %d" % [card_data.name, pack_index])
	EventBus.remove_card_from_pack.rpc(pack_index)
	EventBus.add_card_to_deck.emit(card_data)
	EventBus.log_card_added.rpc(card_data.id, Globals.player.steam_name)

func move_from_deck_to_pack() -> void:
	print("Removing card %s from deck" % card_data.name)
	EventBus.remove_card_from_deck.emit(self)
	EventBus.add_card_to_pack.rpc(card_data.id)
	EventBus.log_card_removed.rpc(card_data.id, Globals.player.steam_name)
