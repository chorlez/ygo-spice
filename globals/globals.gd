extends Node

@onready var masterCube: Cube = Cube.new(Cube.MasterCube, self)
var race_counts := {}
var race_archetypes: Dictionary[Variant, Variant] = {}
var cardData_by_id: Dictionary[Variant, Variant] = {}
var cardData_by_archetype: Dictionary[String, Array] = {}
var playerList : Array[Player] = []

# The currently selected player in the lobby UI (set by Steam.gd when a player button is pressed)
var client_player: Player = null

const IMAGE_BASE_URL := "https://images.ygoprodeck.com/images/cards/"
var CARDSCENE: PackedScene = preload("res://Card/card.tscn")

func create_card(card_data: CardData) -> Card:
	var card: Node = CARDSCENE.instantiate()
	card.card_data = card_data
	if card_data.texture:
		card.texture = card_data.texture
	else:
		load_card_image_to_ui(card_data, card)
	return card

# Fetch the image live and assign it to a card immediately
func load_card_image_to_ui(card: CardData, CardObject: Card) -> void:
	if card.texture:
		CardObject.texture = card.texture
		return

	var http := HTTPRequest.new()
	add_child(http)

	# Callback when HTTP request finishes
	http.request_completed.connect(
		func(_result, response_code, _on_lobby_match_listheaders, body):
			if not card or not CardObject:
				return
			if response_code != 200:
				push_error("Failed to download image for card %d" % card.id)
				http.queue_free()
				return

			var img := Image.new()
			var err := img.load_jpg_from_buffer(body)
			if err != OK:
				push_error("Failed to decode image for card %d" % card.id)
				http.queue_free()
				return

			var tex := ImageTexture.create_from_image(img)
			card.texture = tex
			CardObject.texture = tex

			http.queue_free()
	)

	var url := IMAGE_BASE_URL + str(card.id) + ".jpg"
	http.request(url)

func get_player_by_steam_id(player_steam_id: int) -> Player:
	for player in playerList:
		if player.steam_id == player_steam_id:
			return player
	return null

func get_player_by_steam_name(steam_name: String) -> Player:
	for player in playerList:
		if player.player_name == steam_name:
			return player
	return null

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	elif event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		EventBus.mouse_clicked.emit(event.position)
