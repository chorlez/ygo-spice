extends Node
class_name Pack2

var cards: Array[CardData]
var cardIDs: Array[int]

var packSize:= 10

func create(cube: Cube):
	clear()
	while cards.size() < packSize:
		var cardData:CardData = cube.get_weighted_card()
		cards.append(cardData)
		cardIDs.append(cardData.id)

func add_card_by_id(card_id:int):
	var cardData:CardData = Globals.cardData_by_id.get(card_id)
	if cardData:
		cards.append(cardData)
		cardIDs.append(cardData.id)

func remove(card:CardData):
	var index := cards.find(card)
	if index != -1:
		cards.remove_at(index)
		cardIDs.remove_at(index)

func clear():
	cards = []
	cardIDs = []
