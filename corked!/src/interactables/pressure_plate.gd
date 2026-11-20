# pressure_plate.gd
class_name PressurePlate
extends Area3D

## Doors held open while any player stands on the plate
@export var doors: Array[AutomaticDoor] = []

@onready var _unpressed_model: Node3D = $Unpressed
@onready var _pressed_model: Node3D = $Pressed

var _players_on_plate: Array[Player] = []
var _open_wait: float = 0.0
var _doors_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update()

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

## Swaps the plate model and opens doors while pressed,
## closes them the moment the last player steps off
func _update() -> void:
	_unpressed_model.visible = not is_pressed()
	_pressed_model.visible = is_pressed()

	if is_pressed():
		if _doors_open or _open_wait > 0.0:
			return
		_open_wait = Modifiers.door_open_delay
		if _open_wait <= 0.0:
			_set_doors_open(true)
	else:
		_open_wait = 0.0
		_set_doors_open(false)

func _physics_process(delta: float) -> void:
	if not is_pressed() or _doors_open or _open_wait <= 0.0:
		return
	_open_wait -= delta
	if _open_wait <= 0.0:
		_set_doors_open(true)

func _set_doors_open(value: bool) -> void:
	_doors_open = value
	for door in doors:
		if value:
			door.open()
		else:
			door.close()
