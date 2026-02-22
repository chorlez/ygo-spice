extends Control
class_name Pack
var game
var cube:Cube

var cards: Array[CardData]
var cardIDs: Array[int]
var packSize:= 12

@onready var packContainer = $PackPanel/PackContainer

func _ready():
	game = Globals.game
	cube = game.cube
	EventBus.pack_requested.connect(create)
	EventBus.pack_created.connect(fetch_pack)
	EventBus.card_removed_from_pack.connect(remove_card_from_pack)
	assert(cube != null, 'Error: Cube reference is null in Pack')
	assert(packContainer != null, 'Error: PackContainer reference is null in Pack')

	
func create():
	clear()
	var pack: Array[int] = []
	while pack.size() < packSize:
		pack.append(cube.get_random_card_id())
	print('Pack created with card IDs: ' + str(pack))	
	EventBus.sync_pack.rpc(pack)

func fetch_pack(pack:Array[int]):
	print('Pack received: ' + str(pack))
	clear()
	for card_id in pack:
		var cardData:CardData = CardDatabase.get_card_by_id(card_id)
		cardIDs.append(card_id)
		cards.append(cardData)
	display()

func display():
	print('Displaying pack')
	for card in cards:
		var card_scene = CardDatabase.create_card_scene(card, CardScene.PACK)
		packContainer.add_child(card_scene)

func remove_card_from_pack(pack_index:int):
	if pack_index < 0 or pack_index >= cards.size():
		push_error("Invalid pack index: %d" % pack_index)
		return
	var removed_card = cards[pack_index]
	print('Removing card from pack: ' + removed_card.name)
	cards.remove_at(pack_index)
	cardIDs.remove_at(pack_index)
	var child_to_remove = packContainer.get_child(pack_index)
	if child_to_remove != null:
		child_to_remove.queue_free()
	else:
		push_error("No child found at index %d in packContainer" % pack_index)

func clear():
	cards = []
	cardIDs = []
	for child in packContainer.get_children():
		child.queue_free()
