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
		var card_scene = CardDatabase.create_card_scene(card)
		packContainer.add_child(card_scene)

func clear():
	cards = []
	cardIDs = []
	for child in packContainer.get_children():
		child.queue_free()
