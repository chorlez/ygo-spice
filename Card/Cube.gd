extends Node
class_name Cube

func _init():
	EventBus.request_cube.connect(_on_request_cube)
	

func _on_request_cube():
	print('Cube requested')
