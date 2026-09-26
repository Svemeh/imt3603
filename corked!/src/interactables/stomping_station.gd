class_name StompingStation
extends Interactable

## How many times the player must interact to finish stomping
@export var stomps_required: int = 4

## Grape fill visual
@export var max_grape_capacity: int = 4
@export var empty_grape_y: float = 0.005
@export var full_grape_y: float = 0.305
@onready var grape_fill: Node3D = $GrapeFill

## Where a docked barrel sits
@onready var barrel_marker: Marker3D = $barrelMarker

## Grapes handed to this station, stomped one at a time
var _grapes: Array[Grape] = []

## Barrel currently docked at this station, if any
var barrel: Barrel = null

## How many stomps on the current grape so far
var _stomp_progress: int = 0

func _ready() -> void:
	update_grape_visual()

func update_grape_visual() -> void:
	var grape_count: int = _grapes.size()

	if grape_count <= 0:
		grape_fill.visible = false
		return

	grape_fill.visible = true

	var fill_ratio: float = float(grape_count - 1) / float(max_grape_capacity - 1)

	grape_fill.position.y = lerp(
		empty_grape_y,
		full_grape_y,
		fill_ratio
	)

## Clears the barrel if the player picked it back up
func _check_barrel() -> void:
	if barrel and barrel.get_parent() != barrel_marker:
		barrel = null
		_stomp_progress = 0

func can_accept_item(item: Item) -> bool:
	_check_barrel()
	if item is Grape:
		return _grapes.size() < max_grape_capacity
	return item is Barrel and barrel == null

func accept_item(player: Player) -> void:
	var item := player.transfer_item()
	player.remove_collision_exception_with(item)

	if item is Barrel:
		barrel = item
		item.reparent(barrel_marker)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
		item.freeze = true
		return

	item.reparent(self)
	item.visible = false
	item.process_mode = Node.PROCESS_MODE_DISABLED
	_grapes.append(item)
	update_grape_visual()

func can_interact(_player: Player) -> bool:
	_check_barrel()
	if _grapes.is_empty() or barrel == null:
		return false
	return barrel.juice_amount < barrel.MAX_CAPACITY

func interact(player: Player) -> void:
	if not can_interact(player):
		return

	_stomp_progress += 1
	if _stomp_progress < stomps_required:
		return

	var grape: Grape = _grapes.pop_front()
	var remaining_capacity = barrel.MAX_CAPACITY - barrel.juice_amount
	barrel.add_juice(min(grape.amount, remaining_capacity))

	grape.queue_free()
	_stomp_progress = 0
	update_grape_visual()

func get_prompt() -> String:
	_check_barrel()
	if _grapes.is_empty():
		return "Put a grape in the press"
	if barrel == null:
		return "Place a barrel here"
	if barrel.juice_amount >= barrel.MAX_CAPACITY:
		return "Barrel is full"
	return "Stomp (%d/%d) - %d grapes" % [_stomp_progress, stomps_required, _grapes.size()]
