# pressure_plate.gd
class_name PressurePlate
extends Area3D

## Doors held open while any player stands on the plate
@export var doors: Array[AutomaticDoor] = []
## How far the plate sinks when pressed
@export var press_depth: float = 0.05

@onready var _plate_mesh: Node3D = $MeshInstance3D

var _players_on_plate: Array[Player] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func is_pressed() -> bool:
	return not _players_on_plate.is_empty()

func _on_body_entered(body: Node3D) -> void:
	if body is Player and body not in _players_on_plate:
		_players_on_plate.append(body)
		_update()

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_players_on_plate.erase(body)
		_update()

## Opens doors while pressed, closes them the moment the last player steps off
func _update() -> void:
	_plate_mesh.position.y = -press_depth if is_pressed() else 0.0

	for door in doors:
		if is_pressed():
			door.open()
		else:
			door.close()
