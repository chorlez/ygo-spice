extends Node

const SETTINGS_PATH := "user://settings.cfg"

var config := ConfigFile.new()

func _ready():
	load_settings()


func load_settings():
	var err = config.load(SETTINGS_PATH)

	if err != OK:
		print("No settings file found. Creating default settings.")
		create_default_settings()
		save_settings()
	else:
		print("Settings loaded.")


func create_default_settings():
	config.set_value("deck", "last_save_path", "user://")


func save_settings():
	config.save(SETTINGS_PATH)


func get_last_deck_path() -> String:
	return config.get_value("deck", "last_save_path", "user://")


func set_last_deck_path(path: String):
	config.set_value("deck", "last_save_path", path)
	save_settings()
