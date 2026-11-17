extends Control

@onready var player_slots: Array = [
	$CenterContainer/HBoxContainer/PlayerSlot1,
	$CenterContainer/HBoxContainer/PlayerSlot2,
	$CenterContainer/HBoxContainer/PlayerSlot3,
	$CenterContainer/HBoxContainer/PlayerSlot4
]


func _ready() -> void:
	MenuMusic.play_menu_music
	PlayerManager.clear()

	for i in range(player_slots.size()):
		var slot = player_slots[i]

		slot.player_number = i + 1
		slot.get_node("PlayerPlaque/PlayerLabel").text = "PLAYER %d" % (i + 1)

		slot.setup_character_preview()
		slot.set_joined(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	var device: int = PlayerManager.KEYBOARD if (
		event is InputEventKey or event is InputEventMouseButton
	) else event.device

	if event.is_action_pressed("interact"):
		var i: int = PlayerManager.join(device)

		if i != -1:
			player_slots[i].set_joined(true)
			get_viewport().set_input_as_handled()

	elif event.is_action_pressed("interact2"):
		var i: int = PlayerManager.leave(device)

		if i != -1:
			player_slots[i].set_joined(false)
			get_viewport().set_input_as_handled()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_start_game_button_pressed() -> void:
	if PlayerManager.player_count() == 0:
		return
	GameStats.reset()
	FermentationSettings.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
