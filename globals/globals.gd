extends Node

var cards

const IMAGE_BASE_URL := "https://images.ygoprodeck.com/images/cards/"

# Fetch the image live and assign it to a TextureRect immediately
func load_card_image_to_ui(card: CardData, tex_rect: TextureRect) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	# Callback when HTTP request finishes
	http.request_completed.connect(
		func(result, response_code, headers, body):
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
			tex_rect.texture = tex

			http.queue_free()
	)

	var url := IMAGE_BASE_URL + str(card.id) + ".jpg"
	http.request(url)
