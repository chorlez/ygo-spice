extends Node

const API_URL := "https://db.ygoprodeck.com/api/v7/cardinfo.php"
const CACHE_PATH := "res://data/cards.json"

var cards: Array = []

func _ready():
	fetch_from_api()

func fetch_from_api():
	$HTTPRequest.request(API_URL)

func _on_http_request_request_completed(result, response_code, headers, body):
	if response_code != 200:
		push_error("Failed to fetch card data")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("data"):
		push_error("Invalid JSON response")
		return

	cards.clear()
	for raw_card in json["data"]:
		cards.append(normalize_card(raw_card))

	save_cache()
	print("Loaded %d cards from API" % cards.size())
	Globals.cards = cards
	EventBus.start_civil_war.emit()

func save_cache():
	var file := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(cards, "\t"))
	file.close()

func load_from_cache():
	var file := FileAccess.open(CACHE_PATH, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()

	cards.clear()
	for card in json:
		cards.append(card)

	print("Loaded %d cards from cache" % cards.size())

func normalize_card(raw: Dictionary) -> CardData:
	var card := CardData.new()

	var card_type : String= raw.get("type", "")
	var is_extra :bool = (
		card_type.contains("Fusion")
		or card_type.contains("Synchro")
		or card_type.contains("XYZ")
		or card_type.contains("Link")
	)

	card.id = raw.get("id", 0)
	card.name = raw.get("name", "")
	card.type = card_type
	card.race = raw.get("race", "")
	card.archetype = raw.get("archetype", "")
	card.level = get_int_or_zero(raw, "level")
	card.atk = get_int_or_zero(raw, "atk")
	card.def = get_int_or_zero(raw, "def")
	card.extra_deck = is_extra

	return card

func get_int_or_zero(dict: Dictionary, key: String) -> int:
	var value = dict.get(key)
	return value if value != null else 0
