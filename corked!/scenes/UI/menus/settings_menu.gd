extends Control


func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/UI/menus/main_menu.tscn")

func _on_volume_slider_value_changed(value: float) -> void:
    var volume_db = linear_to_db(value / 100.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)


func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
    if toggled_on:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
