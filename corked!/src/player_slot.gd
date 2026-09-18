extends Control

@onready var character_area: Control = $CharacterArea
@onready var join_label: Label = $JoinLabel

var joined := false

func _ready() -> void:
	set_joined(false)

func set_joined(value: bool) -> void:
	joined = value
	
	character_area.visible = joined
	join_label.visible = not joined