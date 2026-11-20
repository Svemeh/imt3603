# hammer.gd
class_name Hammer
extends Item

## Used to fix the bottling station when it breakss down.
## Must be held when hitting the station to fix it.

## Seconds the hammer lies on the floor before it vanishes to its shelf
@export var return_delay: float = 2.0
## Seconds per blink (on or off) before it vanishes
@export var blink_interval: float = 0.1

func _ready() -> void:
	display_name = "Hammer"
	can_drop = false

## A hammer doesn't spill any wine when its knocked out of someones hands
func get_crash_spill_radius() -> float:
	return 0.0

## Knocked out of someones hands, spawns back on the shelf
func on_crashed() -> void:
	# nobody can pick it up while it vanishes
	can_pick_up = false
	
	var tween := create_tween()
	# first half, just lying on the floor
	tween.tween_interval(return_delay * 0.5)
	# second half, blinking
	var blinks := int ((return_delay * 0.5) / blink_interval)
	for i in blinks:
		tween.tween_callback(func(): visible = not visible)
		tween.tween_interval(blink_interval)
	# poof, and then its back on shelf
	tween.tween_callback(_return_to_shelf)

## Shows the hammer again and puts it back on its shelf
func _return_to_shelf() -> void:
	visible = true
	can_pick_up = true
	var shelf := get_tree().get_first_node_in_group("hammer_shelf") as HammerShelf
	if shelf:
		shelf.return_hammer(self)
