class_name BarrelStack
extends Interactable

const BARREL_SCENE: PackedScene = preload("res://scenes/items/barrel.tscn")

@export var remaining: int = 5

# Bottom row first: taking from the end removes both top barrels first.
@onready var _visuals: Array[Node3D] = [
	$Visuals/BottomLeft,
	$Visuals/BottomMiddle,
	$Visuals/BottomRight,
	$Visuals/TopLeft,
	$Visuals/TopRight,
]

func _ready() -> void:
	_update_visuals()

func has_barrels() -> bool:
	return remaining > 0

func take_barrel(player: Player) -> bool:
	if not has_barrels() or player.is_holding():
		return false

	var barrel := BARREL_SCENE.instantiate() as Barrel
	barrel.freeze = true
	add_child(barrel)

	if not player.recieve_item(barrel):
		barrel.queue_free()
		return false

	remaining -= 1
	_update_visuals()
	return true

func can_accept_item(item: Item) -> bool:
	return item is Barrel and remaining < _visuals.size()

func accept_item(player: Player) -> void:
	var barrel := player.transfer_item()
	barrel.queue_free()

	remaining += 1
	_update_visuals()

func _update_visuals() -> void:
	for index in _visuals.size():
		_visuals[index].visible = index < remaining

# Taking barrels uses interact2, handled in Player.try_pickup().
func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	return "Take an empty barrel (%d left)" % remaining
