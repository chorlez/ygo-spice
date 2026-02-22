extends Control

@onready var main_deck_container = $VBoxContainer/MainDeckPanel/ScrollContainer/MainDeckContainer
@onready var extra_deck_container = $VBoxContainer/ExtraDeckPanel/ScrollContainer/ExtraDeckContainer

var deck: Array[CardData] = []
var deck_card_ids: Array[int] = []
var main_deck: Array[CardData] = []
var extra_deck: Array[CardData] = []

func _ready() -> void:
	EventBus.add_card_to_deck.connect(add_card)
	EventBus.remove_card_from_deck.connect(remove_card)

func add_card(card:CardData) -> void:
	print("Adding card %s to deck" % card.name)
	deck.append(card)
	deck_card_ids.append(card.id)
	if card.is_extra_deck_monster():
		extra_deck.append(card)
		var card_scene = CardDatabase.create_card_scene(card, CardScene.EXTRADECK)
		extra_deck_container.add_child(card_scene)
	else:
		main_deck.append(card)
		var card_scene = CardDatabase.create_card_scene(card, CardScene.MAINDECK)
		main_deck_container.add_child(card_scene)

func remove_card(card_scene: CardScene):
	var card = card_scene.card_data
	print("Removing card %s from deck" % card.name)
	var index = deck.find(card)
	deck.remove_at(index)
	deck_card_ids.remove_at(index)
	if card.is_extra_deck_monster():
		index = extra_deck.find(card)
		extra_deck.remove_at(index)
		extra_deck_container.remove_child(card_scene)
	else:
		index = main_deck.find(card)
		main_deck.remove_at(index)
		main_deck_container.remove_child(card_scene)
