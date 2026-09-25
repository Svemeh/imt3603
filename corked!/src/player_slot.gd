extends Control

@export var player_number: int = 1

@onready var character_area: Control = $CharacterArea
@onready var join_plaque: Control = $JoinPlaque
@onready var player_label: Label = $PlayerPlaque/PlayerLabel


var joined: bool = false


func _ready() -> void:
	player_label.text = "PLAYER %d" % player_number
	set_joined(false)


func set_joined(value: bool) -> void:
	joined = value

	character_area.visible = joined
	join_plaque.visible = not joined