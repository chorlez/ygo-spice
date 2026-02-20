extends Control

var cube: Cube = Cube.new()

func _init():
	EventBus.database_built.connect(_on_database_built)

func _on_database_built():
	EventBus.rpc_signal("request_cube")
