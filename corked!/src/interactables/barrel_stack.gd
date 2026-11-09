class_name BarrelStack
extends Interactable

const BARREL_SCENE: PackedScene = preload("res://scenes/items/barrel.tscn")

var remaining: int = 5

# Bottom row first: taking from the end removes both top barrels first.
@onready var _visuals: Array[Node3D] = [
	$Visuals/BottomLeft,
	$Visuals/BottomMiddle,
	$Visuals/BottomRight,
	$Visuals/TopLeft,
	$Visuals/TopRight,
]
@onready var _collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_update_visuals()

func has_barrels() -> bool:
	return remaining > 0

func take_barrel(player: Player) -> bool:
	if not has_barrels() or player.is_holding():
		return false

	# Use the existing open gameplay barrel, including its liquid and collision.
	var barrel := BARREL_SCENE.instantiate() as Barrel
	barrel.freeze = true
	add_child(barrel)
	# This spelling matches the existing method in Corked's player.gd.
	if not player.recieve_item(barrel):
		barrel.queue_free()
		return false

	remaining -= 1
	_update_visuals()
	return true

func _update_visuals() -> void:
	for index in _visuals.size():
		_visuals[index].visible = index < remaining
	_collision.set_deferred("disabled", remaining == 0)

# Taking barrels uses interact2, handled in Player.try_pickup().
func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	return "Take an empty barrel (%d left)" % remaining
