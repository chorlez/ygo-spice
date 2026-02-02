extends Node
class_name Deck

var mainDeck: Array[CardData]
var extraDeck: Array[CardData]
# Deck sorting state: ADDED keeps insertion order, YUGI_ORDER shows monsters first (highest level), then spells, then others
enum DeckSort { ADDED, YUGI_ORDER }
var deck_sort_mode := DeckSort.ADDED


func clear():
	mainDeck = []
	extraDeck = []

func change_sort():
	deck_sort_mode = (deck_sort_mode + 1) % 2
	if deck_sort_mode == DeckSort.ADDED:
		return "ADDED"
	else:
		return "YUGI"

# Sorting helpers - non-destructive, return a new array for display
func sort_main_for_display() -> Array:
	# DeckSort is expected to be an int/enum value (0 == ADDED)
	if mainDeck == null:
		return []
	
	if deck_sort_mode == 0: # ADDED
		var deck_copy := mainDeck.duplicate()
		deck_copy.reverse()
		return deck_copy

	var monsters := []
	var spells := []
	var traps := []
	var staples := []
	var others := []

	for card_data in mainDeck:
		if card_data == null:
			continue
		# Determine if it's a monster: prefer 'level' > 0, fall back to type string check
		var is_monster := false
		if typeof(card_data.level) == TYPE_INT and int(card_data.level) > 0:
			is_monster = true
		elif String(card_data.type).to_lower().find("monster") != -1:
			is_monster = true

		if is_monster:
			monsters.append(card_data)
			continue

		var ttype := String(card_data.type).to_lower()
		if ttype.find("spell") != -1:
			spells.append(card_data)
			continue
		if ttype.find("trap") != -1:
			traps.append(card_data)
			continue

		# Check staple flag (CardData exports `is_staple` so this will normally exist)
		if typeof(card_data.is_staple) == TYPE_BOOL and card_data.is_staple:
			staples.append(card_data)
			continue

		others.append(card_data)

	# Sort monsters by level descending, then name
	var monster_cmp := Callable(self, "_sort_monsters")
	var name_cmp := Callable(self, "_sort_by_name")
	# Also reference clear() so static analyzer recognizes it as used
	monsters.sort_custom(monster_cmp)
	# Sort spells and traps alphabetically by name (case-insensitive)
	spells.sort_custom(name_cmp)
	traps.sort_custom(name_cmp)
	# reference the clear callable to avoid unused warnings (no-op)

	return monsters + spells + traps + staples + others

func sort_extra_for_display() -> Array:
	if deck_sort_mode == 0: # ADDED
		var extraCopy := extraDeck.duplicate()
		extraCopy.reverse()
		return extraCopy
	var extra := []
	var extra_cmp := Callable(self, "_sort_extra")
	extra = extraDeck.duplicate()
	extra.sort_custom(extra_cmp)
	return extra
	

func _sort_monsters(a: CardData, b: CardData) -> bool:
	# Level descending
	if a.level != b.level:
		return a.level > b.level

	# ATK descending
	if a.atk != b.atk:
		return a.atk > b.atk

	# Final tie-breaker: name
	return a.name < b.name
	
func _sort_by_name(a: CardData, b: CardData) -> bool:
	return a.name.to_lower() < b.name.to_lower()

func _sort_extra(a: CardData, b: CardData) -> bool:
	# 1️⃣ Type order
	var type_a := _extra_type_order(a)
	var type_b := _extra_type_order(b)
	if type_a != type_b:
		return type_a < type_b

	# 2️⃣ Level / Rank (DESC, if present)
	if a.level != b.level:
		return a.level > b.level

	# 3️⃣ ATK (DESC)
	if a.atk != b.atk:
		return a.atk > b.atk

	# 4️⃣ Name
	return a.name < b.name
	
func _extra_type_order(card: CardData) -> int:
	if card.type.contains("Fusion"):
		return 0
	if card.type.contains("Synchro"):
		return 1
	if card.type.contains("XYZ") or card.type.contains("Xyz"):
		return 2
	if card.type.contains("Link"):
		return 3
	return 99
