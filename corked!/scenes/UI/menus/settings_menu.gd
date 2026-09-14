extends Control


@onready var volume_slider: HSlider = $SettingsContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_toggle: CheckButton = $SettingsContainer/FullscreenContainer/FullscreenToggle


func _ready() -> void:
    var master_bus_index = AudioServer.get_bus_index("Master")
    var current_volume_db = AudioServer.get_bus_volume_db(master_bus_index)

    volume_slider.value = db_to_linear(current_volume_db) * 100.0

    fullscreen_toggle.button_pressed = (
        DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    )


func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/UI/menus/main_menu.tscn")


func _on_volume_slider_value_changed(value: float) -> void:
    var volume_db = linear_to_db(value / 100.0)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

    $SettingsContainer/VolumeContainer/VolumeValueLabel.text = str(roundi(value)) + "%"

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
    if toggled_on:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)