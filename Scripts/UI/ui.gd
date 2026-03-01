extends Control

@onready var RollPackButton = $UIPanel/VBoxContainer/TopUILayer/RollPackButton
@onready var SortModeButton = $UIPanel/VBoxContainer/TopUILayer/SortModeButton
@onready var ClearDeckButton = $UIPanel/VBoxContainer/TopUILayer/ClearDeck
@onready var SaveDeckButton = $UIPanel/VBoxContainer/TopUILayer/SaveDeck
@onready var LoadDeckButton = $UIPanel/VBoxContainer/TopUILayer/LoadDeck
@onready var LogLabel = $UIPanel/VBoxContainer/TopUILayer/LogLabel

@onready var CubeTypeMenu = $UIPanel/VBoxContainer/BottomUILayer/CubeTypeMenu
@onready var CubeTypeSearch = $UIPanel/VBoxContainer/BottomUILayer/CubeTypeSearch
@onready var CubeSearch = $UIPanel/VBoxContainer/BottomUILayer/CubeSearch
@onready var SupportToggle = $UIPanel/VBoxContainer/BottomUILayer/SupportToggle
@onready var RuleContainer = $UIPanel/VBoxContainer/BottomUILayer/RuleContainer
@onready var CubeLabel = $UIPanel/VBoxContainer/BottomUILayer/CubeLabel

var ygo_sort: bool = false
var log_card_id: int = -1
var cube = Globals.game.cube

func _ready() -> void:
	RollPackButton.pressed.connect(_on_roll_pack_pressed)
	SortModeButton.pressed.connect(_on_sort_mode_pressed)
	ClearDeckButton.pressed.connect(_on_clear_deck_pressed)
	SaveDeckButton.pressed.connect(_on_save_deck_pressed)
	LoadDeckButton.pressed.connect(_on_load_deck_pressed)
	CubeTypeSearch.editing_toggled.connect(_on_cube_type_search_pressed) 
	CubeSearch.editing_toggled.connect(_on_cube_search_pressed)
	
	EventBus.card_add_log.connect(log_card_added)
	EventBus.card_remove_log.connect(log_card_removed)
	EventBus.cube_type_added.connect(add_cube_type)
	LogLabel.mouse_entered.connect(_on_log_label_mouse_entered)
	EventBus.cube_changed.connect(update_cube_label)
	
	build_cube_menu()
	
	
func log_card_added(card_id: int, steam_name: String) -> void:
	var card_data = CardDatabase.get_card_by_id(card_id)
	log_card_id = card_id
	if card_data:
		LogLabel.text = "%s added %s to the deck" % [steam_name, card_data.name]
	else:
		LogLabel.text = "%s added an unknown card (ID: %d) to the deck" % [steam_name, card_id]

func log_card_removed(card_id: int, steam_name: String) -> void:
	var card_data = CardDatabase.get_card_by_id(card_id)
	log_card_id = card_id
	if card_data:
		LogLabel.text = "%s removed %s from the deck" % [steam_name, card_data.name]
	else:
		LogLabel.text = "%s removed an unknown card (ID: %d) from the deck" % [steam_name, card_id]

func build_cube_menu():
	var cube_types := Cube.cubetypes
	for cube_type in cube_types:
		CubeTypeMenu.add_item(cube_type)

func add_options_to_cube_type_search(query:String = "", vBox: VBoxContainer = null):
	for child in vBox.get_children():
		child.queue_free()
	var options = CardDatabase.get_dropdown_options(CubeTypeMenu.selected)
	for option in options:
		if query != "" and option.findn(query) == -1:
			continue
		var button = Button.new()
		button.text = option
		button.add_theme_font_size_override('font_size', 30)
		button.pressed.connect(_on_cube_search_option_pressed.bind(option))
		vBox.add_child(button)

func add_options_to_cube_search(query:String = "", vBox: VBoxContainer = null):
	for child in vBox.get_children():
		child.queue_free()
	for card in cube.cube:
		if query != "" and card.name.findn(query) == -1:
			continue
		var button = Button.new()
		button.text = card.name
		button.add_theme_font_size_override('font_size', 30)
		button.pressed.connect(_on_cube_search_option_pressed.bind(card.name))
		vBox.add_child(button)

func _on_cube_type_search_pressed(toggled_on) -> void:
	if toggled_on:
		var vb = _spawn_inline_results_container_below_lineedit(CubeTypeSearch)
		add_options_to_cube_type_search('', vb)
		CubeTypeSearch.text_changed.connect(add_options_to_cube_type_search.bind(vb))
		vb.tree_exited.connect(func():
			if CubeTypeSearch.text_changed.is_connected(add_options_to_cube_type_search):
				CubeTypeSearch.text_changed.disconnect(add_options_to_cube_type_search)
		)
func _on_cube_search_pressed(toggled_on) -> void:
	if toggled_on:
		var vb = _spawn_inline_results_container_below_lineedit(CubeSearch)
		add_options_to_cube_search(CubeSearch.text, vb)
		CubeSearch.text_changed.connect(add_options_to_cube_search.bind(vb))
		vb.tree_exited.connect(func():
			if CubeSearch.text_changed.is_connected(add_options_to_cube_search):
				CubeSearch.text_changed.disconnect(add_options_to_cube_search)
		)

func _on_cube_search_option_pressed(option):
	EventBus.on_cube_search_option_pressed.rpc(Cube.cubetypes[CubeTypeMenu.selected], option, SupportToggle.button_pressed)

func add_cube_type(type:String, option:String, support_only: bool):
	var button: Button = Button.new()
	button.text = "%s %s" % [option, 'Support' if support_only else '']
	button.add_theme_font_size_override('font_size', 25)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	RuleContainer.add_child(button)
	
	var sb := StyleBoxFlat.new()
	var colors: Dictionary[Variant, Variant] = {
		"Attribute": Color("#FF006E"),
		"Race": Color("#8338EC"),
		"Archetype": Color("#3A86FF")
	}
	sb.bg_color = colors[type] # Race color
	button.add_theme_stylebox_override("normal", sb)
	button.pressed.connect(remove_cube_type.bind(button))

func remove_cube_type(button: Button):
	EventBus.remove_cube_type.rpc(button.text)
	button.queue_free()

func update_cube_label(cube):
	CubeLabel.text = "CUBE: %d CARDS" % cube.cube.size()

func _on_log_label_mouse_entered() -> void:
	EventBus.card_hovered.emit(log_card_id)	

func _on_roll_pack_pressed() -> void:
	EventBus.open_pack.rpc()

func _on_sort_mode_pressed() -> void:
	EventBus.toggle_sort_mode.emit()

func _on_clear_deck_pressed() -> void:
	EventBus.clear_deck.emit()

func _on_save_deck_pressed() -> void:
	EventBus.save_deck.emit()

func _on_load_deck_pressed() -> void:
	EventBus.load_deck.emit()

func _spawn_inline_results_container_below_lineedit(lineedit: LineEdit) -> VBoxContainer:
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

	get_tree().get_root().add_child(panel)
	panel.add_child(sc)
	sc.add_child(vbox)
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

	# Optional: style/behaviour adjustments
	if sc is ScrollContainer:
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var closing_func: Callable = func(_pos):
		if panel.get_global_rect().has_point(_pos):
			return
		panel.queue_free()
		lineedit.release_focus()
		lineedit.unedit()

	EventBus.mouse_clicked.connect(closing_func)
	panel.tree_exited.connect(func():
		if EventBus.mouse_clicked.is_connected(closing_func):
			EventBus.mouse_clicked.disconnect(closing_func)
	)
		
	return vbox
