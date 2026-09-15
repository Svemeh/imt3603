extends Control

func _on_play_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")

func _on_quit_button_pressed() -> void:
    get_tree().quit()

func _on_credits_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/credits_menu.tscn")