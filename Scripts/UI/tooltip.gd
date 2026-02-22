extends Control

@onready var card_scene = $ToolTipPanel/TooltipArea/TooltipCard
@onready var card_description = $ToolTipPanel/TooltipArea/ScrollContainer/CardDescriptionLabel
@onready var deck_count_label = $ToolTipPanel/TooltipArea/StatsBox/DeckCountLabel
@onready var level_label = $ToolTipPanel/TooltipArea/StatsBox/LevelLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.card_hovered.connect(_on_card_hovered)


func _on_card_hovered(card:CardData):
	pass
	
