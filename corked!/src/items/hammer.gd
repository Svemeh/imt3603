# hammer.gd
class_name Hammer
extends Item

## Used to fix the bottling station when it breakss down.
## Must be held when hitting the station to fix it.

func _ready() -> void:
	display_name = "Hammer"
	can_drop = false
