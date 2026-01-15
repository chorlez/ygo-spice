extends Node

var cards: Array[CardData] = []
var staples: Array[CardData] = []
var race_counts = {}
var race_archetypes = {}

const IMAGE_BASE_URL := "https://images.ygoprodeck.com/images/cards/"
var CARDSCENE = preload("res://Card/card.tscn")

func create_card(card_data: CardData) -> Card:
	var card = CARDSCENE.instantiate()
	card.card_data = card_data
	if card_data.texture:
		card.texture = card_data.texture
	else:
		load_card_image_to_ui(card_data, card)
	return card

# Fetch the image live and assign it to a card immediately
func load_card_image_to_ui(card: CardData, CardObject: Card) -> void:

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


func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
