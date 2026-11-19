# automatic_door.gd
class_name AutomaticDoor
extends AnimatableBody3D

## Where the door moves when open, relative to its closed position.
## Default sinks it into the floor so it doesn't float in the top-down camera
@export var open_offset: Vector3 = Vector3(0, -2.6, 0)
## Seconds to fully open or close
@export var move_time: float = 0.4

var _closed_position: Vector3
var _tween: Tween

func _ready() -> void:
	_closed_position = position

## Moves the door out of the way
func open() -> void:
	_move_to(_closed_position + open_offset)

## Moves the door back to block the path
func close() -> void:
	_move_to(_closed_position)

func _move_to(target: Vector3) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	# AnimatableBody3D must move in the physics step, or players clip through it
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "position", target, move_time)
