extends Node
class_name Pack

var cards: Array[CardData]
var cardIDs: Array[int]

var packSize:= 10

func create(cube: Cube):
	clear()
	while cards.size() < packSize:
		var cardData:CardData = cube.get_weighted_card()
		cards.append(cardData)
		cardIDs.append(cardData.id)

func clear():
	cards = []
	cardIDs = []
