extends Control

var cube: Cube = Cube.new(self)

func _init():
	Globals.game = self
