extends Control

@onready var reason_label: Label = %ReasonLabel
@onready var bottles_label: Label = %BottlesLabel
@onready var money_label: Label = %MoneyLabel
@onready var days_label: Label = %DaysLabel
@onready var last_truck_label: Label = %LastTruckLabel

func _ready() -> void:
	reason_label.text = GameStats.loss_reason
	bottles_label.text = "Bottles sold: %d" % GameStats.bottles_sold
	money_label.text = "Money earned: %d" % GameStats.money_earned
	days_label.text = "Days survived: %d" % GameStats.days_survived
	last_truck_label.text = "Last truck: %d/%d bottles" % [GameStats.last_day_bottles, GameStats.last_day_quota]

## Same players, fresh run
func _on_new_game_button_pressed() -> void:
	GameStats.reset()
	FermentationSettings.reset()
	Modifiers.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
