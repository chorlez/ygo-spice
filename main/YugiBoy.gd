extends Control

var cube: Cube = Cube.new(self)
@onready var pack = $SceneContainer/HBoxContainer/VBoxContainer/Pack

func _init():
	Globals.game = self
	EventBus.database_built.connect(_on_database_built)

func _on_database_built():
	print('Database built, requesting cube...')
	EventBus.request_cube.rpc()
	EventBus.open_pack.rpc()
