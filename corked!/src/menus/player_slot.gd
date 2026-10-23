extends Control

@export var player_number: int = 1

@onready var character_area: Control = $CharacterArea
@onready var join_plaque: Control = $JoinPlaque
@onready var player_label: Label = $PlayerPlaque/PlayerLabel
@onready var character_preview: Node3D = $CharacterArea/CharacterViewport/CharacterPreview

var joined: bool = false


func _ready() -> void:
	player_label.text = "PLAYER %d" % player_number
	setup_character_preview()
	set_joined(false)


func setup_character_preview() -> void:
	var wanted_model: String

	match player_number:
		1:
			wanted_model = "FarmerYellow"
		2:
			wanted_model = "FarmerPurple"
		3:
			wanted_model = "FarmerGreen"
		4:
			wanted_model = "FarmerBlue"
		_:
			wanted_model = "FarmerYellow"

	for child in character_preview.get_children():
		if child is Node3D and child.name.begins_with("Farmer"):
			child.visible = child.name == wanted_model


func set_joined(value: bool) -> void:
	joined = value

	character_area.visible = joined
	join_plaque.visible = not joined
