class_name Barrel
extends Item

## How many grape-juice units the barrel can hold
@export var MAX_CAPACITY: int = 4

## Grape juice units currently stored- 1 press/stomped grape = 1 unit
var juice_amount: int = 0

func _ready() -> void:
	display_name = "Barrel"

func current_juice_amount() -> int:
	return juice_amount

## Adds amount of units of grape juice. Does not clamp, stomping station
## should check max_capacity (or the current juice amount)
func add_juice(amount: int) -> void:
	juice_amount += amount

func get_display_name() -> String:
	return "%s (%d/%d)" % [display_name, juice_amount, MAX_CAPACITY]
