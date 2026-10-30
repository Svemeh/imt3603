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
