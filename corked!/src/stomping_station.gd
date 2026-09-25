class_name StompingStation
extends Interactable

## How many times the player must interact to finish stomping
@export var stomps_required: int = 4

## Grape currently in press, if any
var _grape_in_press: Grape = null

## Barrel currently docked at this station, if any
var barrel: Barrel = null

## How many stomps on grapes so far
var _stomp_progress: int = 0

## Connect this stations won item-detection Area3D body_exited signal
## to this function. Handles a grape/barrel being picked back up before
## its done, e.g. someone grabs barrel mid stomp
func _on_item_zone_body_exited(body: Node3D) -> void:
	if body == _grape_in_press:
		_grape_in_press = null
		_stomp_progress = 0
	elif body == barrel:
		barrel = null

func can_interact(_player: Player) -> bool:
	if _grape_in_press == null or barrel == null:
		return false
	return barrel.juice_amount < barrel.MAX_CAPACITY

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	_stomp_progress += 1
	if _stomp_progress < stomps_required:
		return
	
	var remaining_capacity = barrel.MAX_CAPACITY - barrel.juice_amount
	
	var juice_to_add = _grape_in_press.amount
	if juice_to_add > remaining_capacity:
		juice_to_add = remaining_capacity
	barrel.add_juice(juice_to_add)
	
	_grape_in_press.queue_free()
	_grape_in_press = null
	_stomp_progress = 0


func get_prompt() -> String:
	if _grape_in_press == null:
		return "Put a grape in the press"
	if barrel == null:
		return "Place a barrel here"
	if barrel.juice_amount >= barrel.MAX_CAPACITY:
		return "Barrel is full"
	return "Stomp (%d/%d)" % [_stomp_progress, stomps_required]
