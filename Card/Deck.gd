extends Node
class_name Deck

var mainDeck: Array[CardData]
var extraDeck: Array[CardData]

func clear():
	mainDeck = []
	extraDeck = []