extends Control

@onready var reason_label: Label = %ReasonLabel
@onready var bottles_label: Label = %BottlesLabel
@onready var money_label: Label = %MoneyLabel
@onready var days_label: Label = %DaysLabel
@onready var last_truck_label: Label = %LastTruckLabel
@onready var new_game_button: Button = %NewGameButton

func _ready() -> void:
	reason_label.text = GameStats.loss_reason
	bottles_label.text = "Bottles sold: %d" % GameStats.bottles_sold
	money_label.text = "Money earned: %d" % GameStats.money_earned
	days_label.text = "Days survived: %d" % GameStats.days_survived
	last_truck_label.text = "Last truck: %d/%d bottles" % [GameStats.last_day_bottles, GameStats.last_day_quota]
	# So controller players can press the button without a mouse
	new_game_button.grab_focus()

## Moves focus and presses buttons with our own actions
func _process(_delta: float) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return

	if Input.is_action_just_pressed("left"):
		_move_focus(focused, SIDE_LEFT)
	elif Input.is_action_just_pressed("right"):
		_move_focus(focused, SIDE_RIGHT)
	elif Input.is_action_just_pressed("up"):
		_move_focus(focused, SIDE_TOP)
	elif Input.is_action_just_pressed("down"):
		_move_focus(focused, SIDE_BOTTOM)
	elif Input.is_action_just_pressed("interact") and focused is Button:
		focused.pressed.emit()

## Gives focus to the closest button in that direction, if there is one
func _move_focus(from: Control, side: Side) -> void:
	var next := from.find_valid_focus_neighbor(side)
	if next != null:
		next.grab_focus()

## Same players, fresh run
func _on_new_game_button_pressed() -> void:
	GameStats.reset()
	FermentationSettings.reset()
	Modifiers.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
