extends Node

signal start_civil_war

signal card_hovered(card_data:CardData)
# Include the Player who clicked the card so handlers know who acted
signal card_pressed(card:Card)

signal player_connected()

# Emitted when a player is selected in the lobby UI. Payload is the Steam display name (String).
signal player_selected(steam_name: String)
