extends Node

signal start_civil_war

signal card_hovered(card_data:CardData)
# Include the Player who clicked the card so handlers know who acted
# 0: left click, 1: right click
signal card_pressed(card:Card, button_index:int)

signal player_connected()

# Emitted when a player is selected in the lobby UI. Payload is the Steam display name (String).
signal player_selected(steam_name: String)

signal mouse_clicked(event_position: Vector2)

signal request_new_cube(cube_type: int)
signal sync_state()
