class_name Item
extends RigidBody3D

## Shown in UI/debug prompts, e.g "Grapes"
@export var display_name: String = "item"

func get_display_name() -> String:
	return display_name

## False while the item is locked in place (e.g. a fermenting barrel)
var can_pick_up: bool = true

## False for items that may only be put down somewhere specific
## (e.g. the hammer, which only goes back on its shelf
var can_drop: bool = true

## Size of the wine spill made when the holder crashes. 0 = no spill.
## Override in items that spill differently (barrel, crate, tools)
func get_crash_spill_radius() -> float:
	return Spill.NORMAL_RADIUS

## Called right after a crash knocked this item out of the holder's hands
func on_crashed() -> void:
	pass
