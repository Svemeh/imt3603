class_name Item
extends RigidBody3D

## Shown in UI/debug prompts, e.g "Grapes"
@export var display_name: String = "item"

func get_display_name() -> String:
	return display_name
