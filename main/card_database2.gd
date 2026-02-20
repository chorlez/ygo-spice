extends Node

const API_URL := "https://db.ygoprodeck.com/api/v7/cardinfo.php?format=tcg"
const CACHE_PATH := "res://data/cards.json"
var use_pendulum :bool = false

@onready var cube := Globals.masterCube

func _ready():
	fetch_from_api()
	
func fetch_from_api():
	$HTTPRequest.request(API_URL)


func _on_http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_error("Failed to fetch card data")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json.has("data"):
		push_error("Invalid JSON response")
		return

	for raw_card in json["data"]:
		normalize_card(raw_card)

	#save_cache()
	EventBus.start_civil_war.emit()

func normalize_card(raw: Dictionary) -> void:
	var card := CardData.new()

	var card_type : String= raw.get("type", "")
	card.typename = card_type
	card.type = CardData.EXTRA if (
							card_type.contains("Fusion") 
							or card_type.contains("Synchro")
							or card_type.contains("XYZ")
							or card_type.contains("Link")) else \
		CardData.MONSTER if card_type.contains("Monster") else \
		CardData.SPELL if card_type.contains("Spell") else \
		CardData.TRAP if card_type.contains("Trap") else 0
			
	card.id = raw.get("id", 0)
	card.name = raw.get("name", "")
	
	card.race = raw.get("race", "")
	card.archetype = raw.get("archetype", "")
	card.level = get_int_or_zero(raw, "level")
	card.atk = get_int_or_zero(raw, "atk")
	card.def = get_int_or_zero(raw, "def")
	card.description = raw.desc
	
	# Check pendulum filter
	if not use_pendulum:
		if 'pendulum' in card_type.to_lower()  or card.description.to_lower().find("pendulum") != -1:
			return
	### DISTRIBUTE CARDS TO PROPER LOCATIONS
	if card.name in juicy_staples():
		card.is_staple = true
		cube.staples.append(card)
		
	elif card.type == CardData.MONSTER:
		cube.monsters.append(card)
		if card.race in Globals.race_counts:
			Globals.race_counts[card.race] += 1
		else:
			Globals.race_counts[card.race] = 1
	elif card.type == CardData.EXTRA:
		cube.extras.append(card)
		#Keep count of race
		if card.race in Globals.race_counts:
			Globals.race_counts[card.race] += 1
		else:
			Globals.race_counts[card.race] = 1
	elif card.type == CardData.SPELL:
		cube.spells.append(card)
	elif card.type == CardData.TRAP:
		cube.traps.append(card)
	# Index by ID
	Globals.cardData_by_id[card.id] = card
	if card.archetype != "":
		Globals.cardData_by_archetype[card.archetype] = [card] if not Globals.cardData_by_archetype.has(card.archetype) else Globals.cardData_by_archetype[card.archetype] + [card]
	
func get_int_or_zero(dict: Dictionary, key: String) -> int:
	var value = dict.get(key)
	return value if value != null else 0


func juicy_staples():
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
	"Magic Cilinder",
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
	return STAPLE_CARDS
