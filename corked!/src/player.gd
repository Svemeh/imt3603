# player.gd
class_name Player
extends CharacterBody3D

## Array storing all interactables within range
var _in_range: Array[Interactable] = []

## Appends new interactable to in range array
func _on_area_entered(body: Node3D) -> void:
	if body is Interactable:
		_in_range.append(body)

## Removes interactable in array
func _on_area_exited(body: Node3D) -> void:
	_in_range.erase(body)

## Finds a target to interact with
func _get_target() -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for i in _in_range:
		if not i.can_interact(self):
			continue
		var d := global_position.distance_to(i.global_position)
		if d < best_dist:
			best_dist = d
			best = i
	return best

## attempts to interact with closest interactable
func try_interact() -> void:
	var target := _get_target()
	if target:
		target.interact(self)
