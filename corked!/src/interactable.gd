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
