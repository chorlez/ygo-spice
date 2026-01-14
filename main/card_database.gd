extends Node

const API_URL := "https://db.ygoprodeck.com/api/v7/cardinfo.php?format=tcg"
const STAPLE_API_URL := "https://db.ygoprodeck.com/api/v7/cardinfo.php?staple=yes"
const CACHE_PATH := "res://data/cards.json"

var cards: Array[CardData] = []
var staple_ids : Array[int] = []
var staples_fetched := false


func _ready():
	fetch_staples()
	
func fetch_from_api():
	$HTTPRequest.request(API_URL)

func fetch_staples():
	$HTTPRequest.request(STAPLE_API_URL)

func _on_http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_error("Failed to fetch card data")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("data"):
		push_error("Invalid JSON response")
		return

	# If this is the staple request
	if staples_fetched == false:
		staples_fetched = true
		for raw_card in json["data"]:
			staple_ids.append(int(raw_card.get("id")))

		# Now fetch all cards
		$HTTPRequest.request(API_URL)
		return

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
	card.is_staple = card.id in staple_ids
	card.description = raw.desc
	if card.is_staple:
		Globals.staples.append(card)
	
	# Count races
	if card.type.contains("Monster"):
		#Keep count of race
		if card.race in Globals.race_counts:
			Globals.race_counts[card.race] += 1
		else:
			Globals.race_counts[card.race] = 1
		
	return card

func get_int_or_zero(dict: Dictionary, key: String) -> int:
	var value = dict.get(key)
	return value if value != null else 0
