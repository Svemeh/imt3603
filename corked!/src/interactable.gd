# interactable.gd
class_name Interactable
extends StaticBody3D

## Used to check if object is an interactable object
func can_interact(player: PlayerManager) -> bool:
	return true

## interact behaviour
func interact(player: PlayerManager) -> void:
	pass   # subclass overrides

## returns prompt string
func get_prompt() -> String:
	return "Interact"
