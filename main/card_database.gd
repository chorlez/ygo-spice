extends Node

const API_URL := "https://db.ygoprodeck.com/api/v7/cardinfo.php?format=tcg"
const IMAGE_BASE_URL := "https://images.ygoprodeck.com/images/cards/"
var CARDSCENE: PackedScene = preload("res://Card/card.tscn")
@onready var HTTPRequestNode: HTTPRequest
var pendulum_filter :bool = true


# DATABASE
var cards_by_id : Dictionary = {}
var cards_by_race : Dictionary = {}
var cards_by_archetype : Dictionary = {}
var cards_by_attribute: Dictionary = {}
var cards_by_type: Dictionary = {}
var cards_by_name: Dictionary = {}

var staples: Array[CardData] = []

func _ready():
	fetch_card_database()

func fetch_card_database():
	print('Starting to fetch card database...')
	HTTPRequestNode = HTTPRequest.new()
	add_child(HTTPRequestNode)
	HTTPRequestNode.request_completed.connect(_on_http_request_completed)
	HTTPRequestNode.request(API_URL)

func _on_http_request_completed(_result, response_code, _headers, body):
	print("HTTP request completed with code %d" % response_code)
	if response_code != 200:
		push_error("Failed to fetch card data")
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("data"):
		push_error("Invalid JSON response")
		return
	
	build_card_database(json["data"])

func build_card_database(raw_cards: Array) -> void:
	print("Building card database with %d cards..." % raw_cards.size())
	for raw_card in raw_cards:
		var type_name : String = raw_card.get("type", "")
		var description : String = raw_card.get("desc", "")
		if pendulum_filter:
			if type_name.to_lower().find("pendulum") != -1 or description.to_lower().find("pendulum") != -1:
				continue
		var card_data := CardData.new()
		
		card_data.id = raw_card.get("id", 0)
		card_data.name = raw_card.get("name", "")
		card_data.race = raw_card.get("race", "")
		card_data.archetype = raw_card.get("archetype", "")
		card_data.level = get_int_or_zero(raw_card, "level")
		card_data.atk = get_int_or_zero(raw_card, "atk")
		card_data.def = get_int_or_zero(raw_card, "def")
		card_data.description = raw_card.get("desc", "")
		card_data.type_name = type_name
		card_data.type = CardData.EXTRA if (
							type_name.contains("Fusion") 
							or type_name.contains("Synchro")
							or type_name.contains("XYZ")
							or type_name.contains("Link")) else \
			CardData.MONSTER if type_name.contains("Monster") else \
			CardData.SPELL if type_name.contains("Spell") else \
			CardData.TRAP if type_name.contains("Trap") else 0
		
		cards_by_id[card_data.id] = card_data
		cards_by_name[card_data.name] = card_data
		cards_by_race[card_data.race] = cards_by_race.get(card_data.race, []) + [card_data]
		cards_by_archetype[card_data.archetype] = cards_by_archetype.get(card_data.archetype, []) + [card_data]
		cards_by_attribute[card_data.race] = cards_by_attribute.get(card_data.race, []) + [card_data]
		cards_by_type[card_data.type] = cards_by_type.get(card_data.type, []) + [card_data]
		
	juicy_staples()
	EventBus.database_built.emit()


func create_card_scene(card_data: CardData) -> Card:
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

func get_card_by_id(card_id: int) -> CardData:
	var card = cards_by_id.get(card_id)
	if card == null:
		print("Warning: Card ID %d not found in database" % card_id)
	return card

func juicy_staples() -> void:
	const STAPLE_CARDS := [
	# === MONSTERS ===
	"Effect Veiler",
	"D.D. Crow",
	"Ash Blossom & Joyous Spring",
	"Ghost Ogre & Snow Rabbit",
	"Maxx \"C\"",
	"Battle Fader",
	"Tragoedia",
	"Gorz the Emissary of Darkness",
	"Honest",
	"Dark Armed Dragon",
	"Chaos Sorcerer",
	"Black Luster Soldier - Envoy of the Beginning",
	"Breaker the Magical Warrior",
	"Spirit Reaper",
	"Thunder King Rai-Oh",
	"Card Trooper",
	"Kuriboh",
	"Treeborn Frog",
	"Glow-Up Bulb",
	
	# === SPELLS ===
	"Monster Reborn",
	"Pot of Greed",
	"Graceful Charity",
	"Raigeki",
	"Dark Hole",
	"Heavy Storm",
	"Mystical Space Typhoon",
	"Twin Twisters",
	"Cosmic Cyclone",
	"Book of Moon",
	"Enemy Controller",
	"Snatch Steal",
	"Mind Control",
	"Foolish Burial",
	"Lightning Vortex",
	"Forbidden Chalice",
	"Forbidden Lance",
	"Allure of Darkness",
	"Pot of Duality",
	"Upstart Goblin",
	"Called by the Grave",
	"Polymerization",
	"Super Polymerization",
	"Instant Fusion",
	"Terraforming",
	"Supply Squad",
	
	# === TRAPS ===
	"Mirror Force",
	"Torrential Tribute",
	"Solemn Judgment",
	"Solemn Warning",
	"Solemn Strike",
	"Bottomless Trap Hole",
	"Compulsory Evacuation Device",
	"Dimensional Prison",
	"Call of the Haunted",
	"Magic Cylinder",
	"Trap Dustshoot",
	"Mind Crush",
	"Phoenix Wing Wind Blast",
	"Ring of Destruction",
	"Fiendish Chain",
	"Lost Wind",
	"Ice Dragon's Prison",
	
	# === EXTRA DECK – XYZ ===
	"Number 101: Silent Honor ARK",
	"Castel, the Skyblaster Musketeer",
	"Tornado Dragon",
	"Evilswarm Exciton Knight",
	"Abyss Dweller",
	"Number 39: Utopia",
	"Number 41: Bagooska the Terribly Tired Tapir",
	"Leviair the Sea Dragon",
	
	# === EXTRA DECK – SYNCHRO ===
	"Black Rose Dragon",
	"Brionac, Dragon of the Ice Barrier",
	"Stardust Dragon",
	"Scrap Dragon",
	"Trishula, Dragon of the Ice Barrier",
	"Armory Arm",
	"Formula Synchron",
	"Ally of Justice Catastor",
	
	# === EXTRA DECK – LINK ===
	"Knightmare Phoenix",
	"Knightmare Cerberus",
	"Knightmare Unicorn",
	"Linkuriboh",
	"Relinquished Anima",
	"Accesscode Talker",
	"Borrelsword Dragon",
	"Apollousa, Bow of the Goddess",
	]
	for card_name in STAPLE_CARDS:
		if cards_by_name.has(card_name):
			var card_data = cards_by_name[card_name]
			card_data.is_staple = true
			staples.append(card_data)
		else:
			print("Warning: Staple card '%s' not found in database" % card_name)

func get_int_or_zero(dict: Dictionary, key: String) -> int:
	var value = dict.get(key)
	return value if value != null else 0
