class_name Barrel
extends Item

## How many grape-juice units the barrel can hold
@export var MAX_CAPACITY: int = 4

## Grape juice units currently stored- 1 press/stomped grape = 1 unit
var juice_amount: int = 0

## True once the barrel holds finished wine instead of juice
var is_wine: bool = false

func _ready() -> void:
	display_name = "Barrel"

## Adds amount of units of grape juice. Does not clamp, stomping station
## should check max_capacity (or the current juice amount)
func add_juice(amount: int) -> void:
	juice_amount += amount
	print("Barrel juice: ", juice_amount, "/", MAX_CAPACITY)

func get_display_name() -> String:
	var name_text := "Wine barrel" if is_wine else display_name
	return "%s (%d/%d)" % [name_text, juice_amount, MAX_CAPACITY]
