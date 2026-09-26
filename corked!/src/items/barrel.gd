class_name Barrel
extends Item

## How many grape-juice units the barrel can hold
@export var MAX_CAPACITY: int = 4

## Grape juice units currently stored
var juice_amount: int = 0

## True once the barrel holds finished wine instead of juice
var is_wine: bool = false

# LIQUID VISUAL
@export var empty_liquid_y: float = -0.35
@export var full_liquid_y: float = 0.279

@onready var liquid: MeshInstance3D = $Liquid

func _ready() -> void:
	display_name = "Barrel"
	update_liquid_visual()

## Adds amount of units of grape juice. Does not clamp, stomping station
## should check max_capacity (or the current juice amount)
func add_juice(amount: int) -> void:
	juice_amount += amount

	update_liquid_visual()

	print("Barrel juice: ", juice_amount, "/", MAX_CAPACITY)


func update_liquid_visual() -> void:
	if juice_amount <= 0:
		liquid.visible = false
		return

	liquid.visible = true

	var fill_ratio: float = float(juice_amount) / float(MAX_CAPACITY)

	liquid.position.y = lerp(
		empty_liquid_y,
		full_liquid_y,
		fill_ratio
	)


func get_display_name() -> String:
	var name_text := "Wine barrel" if is_wine else display_name
	return "%s (%d/%d)" % [name_text, juice_amount, MAX_CAPACITY]
