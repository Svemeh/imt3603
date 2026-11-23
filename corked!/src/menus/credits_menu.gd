extends Control


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
