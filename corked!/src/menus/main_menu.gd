extends Control

func _ready() -> void:
	MenuMusic.play_menu_music()
	get_viewport().size_changed.connect(_fit_menu)
	# Wait for the containers to measure all five buttons before centering them.
	_fit_menu.call_deferred()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/lobby_menu.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/credits_menu.tscn")

## Open the reference version: no game, pause, or round-start footer.
func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/how_to_play.tscn")

## Keep the added fifth button on screen in smaller windows.
## Scale the whole menu together, leaving a 24-pixel margin on each side.
func _fit_menu() -> void:
	var menu := $MenuContainter as Control
	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu.size = menu.get_combined_minimum_size()
	var viewport := get_viewport_rect().size
	var factor := minf(1.0, minf((viewport.x - 48.0) / menu.size.x, (viewport.y - 48.0) / menu.size.y))
	menu.scale = Vector2.ONE * factor
	menu.position = (viewport - menu.size * factor) / 2.0
