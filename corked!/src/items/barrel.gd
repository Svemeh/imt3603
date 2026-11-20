class_name Barrel
extends Item

## How many grape-juice units the barrel can hold
@export var MAX_CAPACITY: int = 4

## Juice (or wine) units currently stored. Changing it updates the liquid
## visual automatically, so stations can just set it or subtract from it.
var juice_amount: int = 0:
	set(value):
		juice_amount = value
		if is_node_ready():
			update_liquid_visual()

## True once the barrel holds finished wine instead of juice.
## Changing it updates the liquid colour automatically.
var is_wine: bool = false:
	set(value):
		is_wine = value
		if is_node_ready():
			update_liquid_visual()

# LIQUID VISUAL
@export var empty_liquid_y: float = -0.35
@export var full_liquid_y: float = 0.279
## Colour of grape juice from the stomping station
@export var juice_color: Color = Color(0.6509804, 0, 0.4862745)
## Colour of finished wine from the fermentation station
@export var wine_color: Color = Color(0.45, 0.02, 0.07)
## Seconds the liquid takes to rise or drop to its new level
@export var fill_tween_time: float = 0.5

@onready var liquid: MeshInstance3D = $Liquid
@onready var fill_label: Label3D = $FillLabel

## This barrel's own copy of the liquid material
var _liquid_material: StandardMaterial3D = null
## Tween currently moving the liquid level
var _liquid_tween: Tween = null

func _ready() -> void:
	display_name = "Barrel"
	# Every barrel shares the same material in barrel.tscn. Make a copy so
	# changing the colour here only affects this barrel.
	_liquid_material = liquid.get_surface_override_material(0).duplicate() as StandardMaterial3D
	liquid.set_surface_override_material(0, _liquid_material)
	update_liquid_visual(true)

## Adds amount of units of grape juice. Does not clamp, stomping station
## should check max_capacity (or the current juice amount)
func add_juice(amount: int) -> void:
	juice_amount += amount
	print("Barrel juice: ", juice_amount, "/", MAX_CAPACITY)

## Sets liquid colour and height to match juice_amount and is_wine.
## instant = true skips the smooth rise/drop.
func update_liquid_visual(instant: bool = false) -> void:
	_liquid_material.albedo_color = wine_color if is_wine else juice_color
	fill_label.text = "%d/%d" % [juice_amount, MAX_CAPACITY]

	if _liquid_tween:
		_liquid_tween.kill()

	if juice_amount <= 0:
		# Empty barrel: hide the liquid and reset it to the bottom
		liquid.visible = false
		liquid.position.y = empty_liquid_y
		return

	liquid.visible = true

	var fill_ratio: float = clampf(float(juice_amount) / float(MAX_CAPACITY), 0.0, 1.0)
	var target_y: float = lerp(empty_liquid_y, full_liquid_y, fill_ratio)

	if instant or not is_inside_tree():
		liquid.position.y = target_y
		return

	_liquid_tween = create_tween()
	_liquid_tween.tween_property(liquid, "position:y", target_y, fill_tween_time)

func get_display_name() -> String:
	var name_text := "Wine barrel" if is_wine else display_name
	return "%s (%d/%d)" % [name_text, juice_amount, MAX_CAPACITY]

## A barrel with liquid makes a big spill, an empty one makes none
func get_crash_spill_radius() -> float:
	return Spill.BIG_RADIUS if juice_amount > 0 else 0.0

## Loses 2 units when knocked out of someone's hands (empty if it had 1 or 2)
func on_crashed() -> void:
	juice_amount = maxi(juice_amount - 2, 0)
	if juice_amount == 0:
		is_wine = false
