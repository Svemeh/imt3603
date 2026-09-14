extends Node

@onready var hud = $Hud

var money: int = 0
var quota: int = 0

func _ready() -> void:
	hud.update_money(money)
	hud.update_quota(quota)

## Increments money up or down by x and refreshes the HUD.
func increment_money(x: int) -> void:
	money += x
	hud.update_money(money)

## Increments quota by x (e.g. from a valid delivery) and refreshes the HUD.
func increment_quota(x: int) -> void:
	quota += x
	hud.update_quota(quota)
