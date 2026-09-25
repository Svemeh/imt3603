extends Control


# @onready var player_slots: Array = [
#	$CenterContainer/HBoxContainer/PlayerSlot1,
#	$CenterContainer/HBoxContainer/PlayerSlot2,
#	$CenterContainer/HBoxContainer/PlayerSlot3,
#	$CenterContainer/HBoxContainer/PlayerSlot4
#]


#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("ui_accept"):
#		join_next_player()


#func join_next_player() -> void:
#	for slot in player_slots:
#		if not slot.joined:
#			slot.set_joined(true)
#			return

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
