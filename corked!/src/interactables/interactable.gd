# interactable.gd
class_name Interactable
extends StaticBody3D

## Used to check if object is an interactable object
func can_interact(_player: Player) -> bool:
	return true

## interact behaviour
func interact(_player: Player) -> void:
	pass   # subclass overrides

## returns prompt string
func get_prompt() -> String:
	return "Interact"

func can_accept_item(_item: Item) -> bool:
	return false

func accept_item(_player: Player) -> void:
	pass

## True while a player is inside this station's room (the RoomArea child).
## Used to show the station's fill label. Resize the RoomArea box in the
## station scene to change where the label shows up
func is_player_near() -> bool:
	var room := get_node_or_null("RoomArea") as Area3D
	if room == null:
		return false
	for body in room.get_overlapping_bodies():
		if body is Player:
			return true
	return false
