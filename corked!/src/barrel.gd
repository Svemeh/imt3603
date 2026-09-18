class_name barrel
extends Item

## How many grape-juice units the barrel can hold
const MAX_CAPACITY: int = 4

## Grape juice units currently stored- 1 press/stomped grape = 1 unit
@export var juice_amount: int = 0

func _ready() -> void:
	display_name = "Barrel"

func is_full() -> bool:
	return juice_amount >= MAX_CAPACITY

## Adds amount units of grape juice, clamped so the barrel never exceeds
## MAX_CAPACITY. Returns how much actually fit, so a future pressing station can
## tell if it tried to add more than there was room for
func add_juice(amount: int) -> int:
	var remaining_capacity := MAX_CAPACITY - juice_amount
	var added := clampi(amount, 0, remaining_capacity)
	juice_amount += added
	return added

func get_display_name() -> String:
	return "%s (%d/%d) % [display_name, juice_amount, MAX_CAPACITY]"
