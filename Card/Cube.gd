extends Node
class_name Cube

var monsters: Array[CardData]
var spells: Array[CardData]
var traps: Array[CardData]
var extras: Array[CardData]
var staples: Array[CardData]

var cube: Array[CardData] # Combined array for searching

var type_weights := {
	"Monsters": 0.45,
	"Spells": 0.2,
	"Traps": 0.15,
	"Extra": 0.1,
	'Staples':0.1
}

# New properties to receive data from civil_war
var masterCube: Cube
var race: String = ""

# Cube searcher 
@export var search_input: LineEdit
@export var results_container: VBoxContainer

var max_results := 50
	


# Replace create to accept cards and race and build cube internally
func create(new_race: String, n_search_input: LineEdit, n_results_container: VBoxContainer):
	masterCube = Globals.masterCube
	race = new_race
	search_input = n_search_input
	search_input.text_changed.connect(_on_search_text_changed)
	results_container = n_results_container
	clear()
	add_race_cards_to_cube()
	add_support_cards_to_cube()
	add_staples_to_cube()
	# Build combined cube for searching
	cube = monsters + spells + traps + extras + staples
	

func clear():
	monsters.clear()
	spells.clear()
	traps.clear()
	extras.clear()
	staples.clear()

# Populate monster/extra pools from provided cards for the selected race
func add_race_cards_to_cube():
	for card in masterCube.monsters + masterCube.extras:
		if card.race == race:
			if not card.extra_deck:
				monsters.append(card)
			else:
				extras.append(card)

# Populate spell/support pool by matching race mentions and significant archetypes
func add_support_cards_to_cube():
	var archetype_counts := get_archetypes_for_race()
	var archetypes := filter_archetypes(archetype_counts)
	for card in masterCube.spells + masterCube.traps:
		if card_mentions_exact_race(card):
			spells.append(card)
		else:
			for archetype in archetypes:
				if card_mentions_archetype(card, archetype):
					spells.append(card)
					break

func card_mentions_exact_race(card: CardData) -> bool:
	if card.description == "":
		return false
	var text: String = card.description.to_lower()
	var target := race.to_lower()
	var pattern := "(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)"
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex.search(text) != null

func get_archetypes_for_race() -> Dictionary:
	var archetypes := {}
	for card in masterCube.monsters + masterCube.extras:
		if card.race != race:
			continue
		if card.archetype == "":
			continue
		if not archetypes.has(card.archetype):
			archetypes[card.archetype] = 0
		archetypes[card.archetype] += 1
	return archetypes

func filter_archetypes(archetypes: Dictionary, min_size := 5) -> Array:
	var result := []
	for archetype in archetypes.keys():
		if archetypes[archetype] >= min_size:
			result.append(archetype)
	return result

func card_mentions_archetype(card: CardData, archetype: String) -> bool:
	if card.description == "":
		return false
	var text := card.description.to_lower()
	var target := archetype.to_lower()
	var regex := RegEx.new()
	regex.compile("(^|[^a-zA-Z-])" + target + "([^a-zA-Z-]|$)")
	return regex.search(text) != null

func add_staples_to_cube():
	# copy staples list from provided cards
	staples = masterCube.staples.duplicate(true)

# Return an integer id for a randomly selected weighted card (by type)
func get_weighted_card() -> CardData:
	var roll := randf() # 0.0 – 1.0
	var cumulative := 0.0
	var chosen_type := ""
	for t in type_weights.keys():
		cumulative += type_weights[t]
		if roll < cumulative:
			chosen_type = t
			break

	# map the chosen_type to the corresponding array
	var pool := []
	match chosen_type:
		"Monsters":
			pool = monsters
		"Spells":
			pool = spells
		"Traps":
			pool = traps
		"Extra":
			pool = extras
		"Staples":
			pool = staples
		_:
			pool = monsters

	# If the selected pool is empty, pick any non-empty pool
	if pool == []:
		var non_empty := []
		if monsters.size() > 0:
			non_empty.append(monsters)
		if spells.size() > 0:
			non_empty.append(spells)
		if traps.size() > 0:
			non_empty.append(traps)
		if extras.size() > 0:
			non_empty.append(extras)
		if staples.size() > 0:
			non_empty.append(staples)
		if non_empty.size() == 0:
			pass
		pool = non_empty.pick_random()

	var cardData: CardData = pool.pick_random()
	# return id to match existing civil_war rpc_sync_pack expectations
	return cardData

func _on_search_text_changed(text):
	var query = text.strip_edges().to_lower()
	
	_clear_results()
	
	if query.is_empty():
		return
	
	var shown := 0
	
	for card in cube:
		if card.name.to_lower().contains(query):
			_add_result(card)
			shown += 1
			if shown >= max_results:
				break

func _clear_results():
	for child in results_container.get_children():
		child.queue_free()

func _add_result(card: CardData):
	var label := Label.new()
	label.text = card.name
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	results_container.add_child(label)
