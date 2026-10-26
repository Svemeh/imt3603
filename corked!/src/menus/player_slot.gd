extends Control

@export var player_number: int = 1

@onready var character_area: Control = $CharacterArea
@onready var join_plaque: Control = $JoinPlaque
@onready var player_label: Label = $PlayerPlaque/PlayerLabel
@onready var character_preview: Node3D = $CharacterArea/CharacterViewport/CharacterPreview

var joined: bool = false

var preview_model: Node3D
var preview_animation_player: AnimationPlayer
var idle_animation: String


func _ready() -> void:
	player_label.text = "PLAYER %d" % player_number
	setup_character_preview()
	set_joined(false)


func setup_character_preview() -> void:
	var wanted_model: String

	match player_number:
		1:
			wanted_model = "FarmerYellow"
			idle_animation = "shared/Idle_3"

		2:
			wanted_model = "FarmerPurple"
			idle_animation = "shared/Idle_3"

		3:
			wanted_model = "FarmerGreen"
			idle_animation = "Idle_3"

		4:
			wanted_model = "FarmerBlue"
			idle_animation = "shared/Idle_3"

		_:
			wanted_model = "FarmerYellow"
			idle_animation = "shared/Idle_3"

	preview_model = null
	preview_animation_player = null

	for child in character_preview.get_children():
		if child is Node3D and child.name.begins_with("Farmer"):
			child.visible = child.name == wanted_model

			if child.name == wanted_model:
				preview_model = child

	if preview_model != null:
		preview_animation_player = find_animation_player(preview_model)


func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		var anim_player := node as AnimationPlayer

		if anim_player.has_animation(idle_animation):
			return anim_player

	for child in node.get_children():
		var result := find_animation_player(child)

		if result != null:
			return result

	return null


func set_joined(value: bool) -> void:
	joined = value

	character_area.visible = joined
	join_plaque.visible = not joined

	if preview_animation_player == null:
		print("No AnimationPlayer found for Player ", player_number)
		return

	if joined:
		if preview_animation_player.has_animation(idle_animation):
			var animation := preview_animation_player.get_animation(idle_animation)

			animation.loop_mode = Animation.LOOP_LINEAR

			preview_animation_player.active = true
			preview_animation_player.play(idle_animation)

			print(
				"Player ",
				player_number,
				" playing ",
				idle_animation
			)
	else:
		preview_animation_player.stop()
