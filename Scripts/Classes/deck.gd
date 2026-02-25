extends Control

@onready var main_deck_container = $VBoxContainer/MainDeckPanel/ScrollContainer/MainDeckContainer
@onready var extra_deck_container = $VBoxContainer/ExtraDeckPanel/ScrollContainer/ExtraDeckContainer
@onready var DeckFileDialog = $DeckFileDialog

var deck: Array[CardData] = []
var deck_card_ids: Array[int] = []
var main_deck: Array[CardData] = []
var extra_deck: Array[CardData] = []

var default_filename: String = '[YugiBoy]Deck.ydk'
var backup_file_name: String = '[YugiBoy]Backup.ydk'

var ygo_sort: bool = false


func _ready() -> void:
	EventBus.add_card_to_deck.connect(add_card)
	EventBus.remove_card_from_deck.connect(remove_card)
	EventBus.toggle_sort_mode.connect(toggle_sort_mode)
	EventBus.clear_deck.connect(clear_deck)
	EventBus.load_deck.connect(_on_load_deck_pressed)
	EventBus.save_deck.connect(_on_save_deck_pressed)
	DeckFileDialog.dir_selected.connect(_on_deck_file_dialog_dir_selected)
	DeckFileDialog.file_selected.connect(_on_deck_file_dialog_file_selected)

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
	display_deck()

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
	display_deck()


func display_deck():
	clear_display()
	for card in get_main_deck_sorted():
		var card_scene = CardDatabase.create_card_scene(card, CardScene.MAINDECK)
		main_deck_container.add_child(card_scene)
	for card in get_extra_deck_sorted():
		var card_scene = CardDatabase.create_card_scene(card, CardScene.EXTRADECK)
		extra_deck_container.add_child(card_scene)

func clear_deck():
	deck.clear()
	deck_card_ids.clear()
	main_deck.clear()
	extra_deck.clear()
	clear_display()

func clear_display():
	for child in main_deck_container.get_children():
		child.queue_free()
	for child in extra_deck_container.get_children():
		child.queue_free()

func toggle_sort_mode():
	ygo_sort = !ygo_sort
	display_deck()

# Sorting helpers - non-destructive, return a new array for display
func get_main_deck_sorted() -> Array[CardData]:
	# DeckSort is expected to be an int/enum value (0 == ADDED)
	if main_deck == null:
		return []
	
	if !ygo_sort: # ADDED
		var deck_copy := main_deck.duplicate()
		deck_copy.reverse()
		return deck_copy

	var monsters : Array[CardData]= []
	var spells : Array[CardData]= []
	var traps : Array[CardData]= []

	for card_data in main_deck:
		if card_data == null:
			continue
		# Determine if it's a monster: prefer 'level' > 0, fall back to type string check
		if card_data.is_monster():
			monsters.append(card_data)
			continue

		elif card_data.is_spell():
			spells.append(card_data)
			continue
		elif card_data.is_trap():
			traps.append(card_data)
			continue
		else:
			push_error("Unexpected card type for card %s: type %d" % [card_data.name, card_data.type])

	# Sort monsters by level descending, then name
	var monster_cmp := Callable(self, "_sort_monsters")
	var name_cmp := Callable(self, "_sort_by_name")
	# Also reference clear() so static analyzer recognizes it as used
	monsters.sort_custom(monster_cmp)
	# Sort spells and traps alphabetically by name (case-insensitive)
	spells.sort_custom(name_cmp)
	traps.sort_custom(name_cmp)
	# reference the clear callable to avoid unused warnings (no-op)

	return monsters + spells + traps

func get_extra_deck_sorted() -> Array[CardData]:
	if !ygo_sort: # ADDED
		var extraCopy := extra_deck.duplicate()
		extraCopy.reverse()
		return extraCopy
	var extra := []
	var extra_cmp := Callable(self, "_sort_extra")
	extra = extra_deck.duplicate()
	extra.sort_custom(extra_cmp)
	return extra

func load_deck(path):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to load deck")
		return

	var current_section := ""
	clear_deck()
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		if line.begins_with("#"):
			current_section = line.to_lower()
			continue
		if line.begins_with("!side"):
			current_section = "!side"
			continue
		
		var card_id := int(line)
		var card_data = CardDatabase.get_card_by_id(card_id)
		
		if not card_data:
			continue
		add_card(card_data)

	file.close()



func _on_save_deck_pressed():
	DeckFileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	default_filename = "[YuGiBoy]" + 'implement' + ".ydk"
	DeckFileDialog.current_dir = Settings.get_last_deck_path()
	DeckFileDialog.current_file = default_filename
	DeckFileDialog.popup_centered()

func _on_load_deck_pressed():
	DeckFileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	DeckFileDialog.current_dir = Settings.get_last_deck_path()
	DeckFileDialog.popup_centered()

func _on_deck_file_dialog_dir_selected(dir):
	if DeckFileDialog.current_file.is_empty():
		DeckFileDialog.current_file = default_filename

func _on_deck_file_dialog_file_selected(path: String):
	var dir := path.get_base_dir()
	var file_name := path.get_file()
	Settings.set_last_deck_path(dir)
	if DeckFileDialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		load_deck(path)
	else:
#		save_deck_to_path(path)
		pass
