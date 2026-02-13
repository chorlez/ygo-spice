extends Node
class_name Cube

var cube: Array[CardData]
var monsters: Array[CardData]
var spells: Array[CardData]
var traps: Array[CardData]
var extras: Array[CardData]
var staples: Array[CardData]

static var cube_types: Array[String] = ["Race", "Archetype", "Attribute", "MasterCube"]

enum {
	Race,
	Archetype,
	Attribute,
	MasterCube,
	}


var cube_type: int
var game: Node
var masterCube: Cube

#Race cube
var race: String

# Archetype cube
var number_of_archetypes := 4
var archetypes := []


var type_weights := {
	"Monsters": 0.45,
	"Spells": 0.2,
	"Traps": 0.15,
	"Extra": 0.1,
	'Staples':0.1
}


# Cube searcher 
@export var search_input: LineEdit
@export var results_panel: Panel

var max_results := 50

# Replace create to accept cards and race and build cube internally
func _init(cubeType: int, n_game):
	cube_type = cubeType
	game = n_game
	if not cube_type == MasterCube:
		init_cube()
	
	match cube_type:
		MasterCube:
			create_master_cube()
		Race:
			create_race_cube()
		Archetype:
			create_archetype_cube()
		Attribute:
			create_attribute_cube()
	
	if multiplayer and multiplayer.is_server():
		EventBus.sync_cube.emit()
			

func create_master_cube():
	pass

func create_race_cube():
	game.race = game.race if game.race else roll_random_race()
	race = game.race
	add_race_cards_to_cube()
	add_race_support_cards_to_cube()
	add_staples_to_cube()
	# Build combined cube for searching
	combine_cube()

func create_archetype_cube():
	number_of_archetypes = game.ArchetypeCountMenu.get_selected() + 1
	game.archetypes = game.archetypes if game.archetypes else roll_random_archetypes()
	archetypes = game.archetypes
	spawn_archetype_dropdowns()
	add_archetype_cards_to_cube()
	add_staples_to_cube()
	combine_cube()
	

func create_attribute_cube():
	pass

func init_cube():
	masterCube = Globals.masterCube
	search_input = game.search_input
	search_input.set_meta("context", "cube_search")
	search_input.editing_toggled.connect(_on_editing_toggled.bind(search_input))
	search_input.text_changed.connect(_on_search_text_changed.bind(search_input))
	EventBus.mouse_clicked.connect(_on_search_focus_exited)

func combine_cube():
	cube = monsters + spells + traps + extras + staples

func clear():
	monsters.clear()
	spells.clear()
	traps.clear()
	extras.clear()
	staples.clear()


func roll_random_race() -> String:
	var eligible_races: Array = []
	for race_name in Globals.race_counts.keys():
		var count :int = Globals.race_counts[race_name]
		if count >= 20:
			eligible_races.append(race_name)
	var new_race = eligible_races.pick_random()
	game.change_selected_race(new_race)
	return new_race

func roll_random_archetypes() -> Array[String]:
	var eligible_archetypes: Array[String] = []
	for archetype_name in Globals.cardData_by_archetype.keys():
		var count :int = Globals.cardData_by_archetype[archetype_name].size()
		if count >= 15:
			eligible_archetypes.append(archetype_name)
	var new_archetypes : Array[String] = []
	while new_archetypes.size() < number_of_archetypes and eligible_archetypes.size() > 0:
		var archetype = eligible_archetypes.pick_random()
		new_archetypes.append(archetype)
		eligible_archetypes.erase(archetype)
	game.change_selected_archetypes(new_archetypes)
	return new_archetypes

# Populate monster/extra pools from provided cards for the selected race
func add_race_cards_to_cube():
	for card in masterCube.monsters + masterCube.extras:
		if card.race == race:
			if not card.extra_deck:
				monsters.append(card)
			else:
				extras.append(card)

				
# Populate spell/support pool by matching race mentions and significant archetypes
func add_race_support_cards_to_cube():
	var archetype_counts := get_archetypes_for_race()
	var archetypes := filter_archetypes(archetype_counts)
	for card in masterCube.spells:
		if card_mentions_exact_race(card):
			spells.append(card)
		else:
			for archetype in archetypes:
				if card_mentions_archetype(card, archetype):
					spells.append(card)
					break
	for card in masterCube.traps:
		if card_mentions_exact_race(card):
			traps.append(card)
		else:
			for archetype in archetypes:
				if card_mentions_archetype(card, archetype):
					traps.append(card)
					break

func add_archetype_cards_to_cube():
	for archetype in archetypes:
		for card in Globals.cardData_by_archetype[archetype]:
			match card.type:
				CardData.MONSTER:
					monsters.append(card)
				CardData.EXTRA:
					extras.append(card)
				CardData.SPELL:
					spells.append(card)
				CardData.TRAP:
					traps.append(card)

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

func _on_search_text_changed(text, lineedit: LineEdit):
	var query = text.strip_edges().to_lower()
	if query.is_empty():
		return
	_clear_dropdown_results(lineedit.get_meta('results_vbox'))
	
	if lineedit.get_meta('context') == "cube_search":	
		for card in cube:
			if card.name.to_lower().contains(query):
				_add_card_to_cube_search(card)
	elif lineedit.get_meta('context') == "archetype_dropdown":
		for archetype in Globals.cardData_by_archetype.keys():
			if archetype.to_lower().contains(query):
				_add_archetype_to_search(archetype, lineedit)
		

func _clear_dropdown_results(results_container: VBoxContainer):
	if results_container:
		for child in results_container.get_children():
			child.queue_free()

func hide_results():
	if results_panel:
		results_panel.queue_free()
		results_panel = null
#		results_container = null

# Helper: spawn a ScrollContainer + VBoxContainer directly under the LineEdit
func _spawn_inline_results_container_below_lineedit(lineedit: LineEdit) -> void:
	# Find a parent to host Controls (prefer the LineEdit parent)
	var host := search_input.get_tree().get_root()

	# Create the scroll container and inner vbox
	var sc := ScrollContainer.new()
	sc.name = "SearchResultsScroll"
	var vbox := VBoxContainer.new()
	vbox.name = "SearchResultsVBox"
	var panel := Panel.new()
	panel.name = "SearchResultsPanel"
	
	# Create a flat style for the panel (grey background with rounded corners and border)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.DARK_SLATE_GRAY
	sb.border_color = Color(0, 0, 0, 0.6)
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)

	host.add_child(panel)
	panel.add_child(sc)
	sc.add_child(vbox)

	lineedit.set_meta('results_vbox', vbox)

	# Try to position the scroll container below the LineEdit.
	# Use rect_position/rect_size when available (Control), fallback to global_position.
	var margin := 10
	panel.global_position = lineedit.global_position + Vector2(0, lineedit.size.y + margin)
	# match width of the LineEdit and give a reasonable height
	panel.size = Vector2(750, 400)
	
	sc.set_offsets_preset(Control.PRESET_FULL_RECT)
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Expose the inner vbox as results_container for the rest of the code
	results_panel = panel

	# Optional: style/behaviour adjustments
	if sc is ScrollContainer:
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

func _on_editing_toggled(toggledOn:bool, lineedit: LineEdit):
	# If the user presses down arrow, focus the first result if it exists
	if toggledOn:
		_spawn_inline_results_container_below_lineedit(lineedit)
		if lineedit.get_meta('context') == "cube_search":
			for card in cube:
				_add_card_to_cube_search(card)
		elif lineedit.get_meta('context') == "archetype_dropdown":
			lineedit.text = ''
			for archetype in Globals.cardData_by_archetype.keys():
				_add_archetype_to_search(archetype, lineedit)

				
func _on_search_focus_exited(even_position: Vector2):	
	# Clear results when the search box loses focus
	if not results_panel:
		return
	if results_panel.get_global_rect().has_point(even_position):
		# Click was inside the panel → do nothing
		return
#	_clear_results()
	hide_results()
	search_input.release_focus()

func _add_card_to_cube_search(card: CardData):
	var button := Button.new()
	button.text = card.name
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.set_text_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	button.add_theme_font_size_override('font_size', 40)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(func():
		EventBus.card_hovered.emit(card)
		)

	search_input.get_meta('results_vbox').add_child(button)

func _add_archetype_to_search(archetype: String, lineedit: LineEdit):
	var button := Button.new()
	button.text = archetype
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_text_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	button.add_theme_font_size_override('font_size', 40)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(on_archetype_button_pressed.bind(archetype, lineedit))
	lineedit.get_meta('results_vbox').add_child(button)
	
func spawn_archetype_dropdowns():
	for child in game.ArchetypeContainer.get_children():
		child.queue_free()
	for i in range(number_of_archetypes):
		var lineedit = LineEdit.new()
		lineedit.text = archetypes[i]
		lineedit.add_theme_font_size_override('font_size', 35)
		lineedit.expand_to_text_length = true
		lineedit.set_meta("context", "archetype_dropdown")
		lineedit.editing_toggled.connect(_on_editing_toggled.bind(lineedit))
		lineedit.text_changed.connect(_on_search_text_changed.bind(lineedit))
		game.ArchetypeContainer.add_child(lineedit)

func on_archetype_button_pressed(archetype: String, lineedit: LineEdit):
	lineedit.text = archetype
	for i in range(number_of_archetypes):
		if lineedit == game.ArchetypeContainer.get_child(i):
			archetypes[i] = archetype
			break
	hide_results()
	EventBus.request_new_cube.emit(Archetype)
