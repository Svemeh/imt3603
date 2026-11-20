# automatic_door.gd
class_name AutomaticDoor
extends AnimatableBody3D

## Where the door moves when open, relative to its closed position.
## Default sinks it into the floor so it doesn't float in the top-down camera
@export var open_offset: Vector3 = Vector3(0, -2.6, 0)
## Seconds to fully open or close
@export var move_time: float = 0.4

@onready var _shape_node: CollisionShape3D = $CollisionShape3D

var _closed_position: Vector3
## Global transform of the closed door, used for the doorway check
var _closed_global: Transform3D
var _tween: Tween
## Close was requested, but the door waits until no player is in the doorway
var _wants_close := false
## Door is currently moving up to closed
var _closing := false

func _ready() -> void:
	_closed_position = position
	_closed_global = global_transform

## Moves the door out of the way
func open() -> void:
	_wants_close = false
	_closing = false
	_move_to(_closed_position + open_offset)

## Closes the door as soon as the doorway is clear.
## Rising into a player would lift them, and players have no gravity
func close() -> void:
	_wants_close = true

func _physics_process(_delta: float) -> void:
	if not _wants_close:
		return

	if _is_player_in_doorway():
		# Someone stepped in while it was rising, back off and wait
		if _closing:
			_closing = false
			_move_to(_closed_position + open_offset)
		return

	if not _closing:
		_closing = true
		_move_to(_closed_position, _on_closed)

func _on_closed() -> void:
	_wants_close = false
	_closing = false

## True if any player overlaps the space the closed door takes up
func _is_player_in_doorway() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape_node.shape
	query.transform = _closed_global * _shape_node.transform
	query.collision_mask = 3
	query.exclude = [get_rid()]

	for hit in get_world_3d().direct_space_state.intersect_shape(query):
		if hit.collider is Player:
			return true
	return false

func _move_to(target: Vector3, on_done: Callable = Callable()) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	# AnimatableBody3D must move in the physics step, or players clip through it
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "position", target, move_time)
	if on_done.is_valid():
		_tween.tween_callback(on_done)
