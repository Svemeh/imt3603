extends Node

@onready var hud = $Hud
@onready var round_timer: RoundTimer = $RoundTimer

var money: int = 0
var quota: int = 0

func _ready() -> void:
	hud.update_money(money)
	hud.update_quota(quota)
	round_timer.round_ended.connect(_on_round_timer_round_ended)
	round_timer.start_round()

## Increments money up or down by x and refreshes the HUD.
func increment_money(x: int) -> void:
	money += x
	hud.update_money(money)

## Increments quota by x (e.g. from a valid delivery) and refreshes the HUD.
func increment_quota(x: int) -> void:
	quota += x
	hud.update_quota(quota)

## Called when a round's timer hits zero. Ends the game.
func _on_round_timer_round_ended() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/menus/game_over.tscn")
