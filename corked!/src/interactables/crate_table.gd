# crate_table.gd
class_name CrateTable
extends Interactable

## Table in the utility room where finished crates wait while the driver is on
## his smoke break. Full crates are put down here with interact2, and picked
## up again with interact2 to carry them to the truck once it opens

## How many crates fit side by side across the table (Z value)
@export var crates_across: int = 1
## How many rows fit from the front to the back of the table (X value)
@export var crates_deep: int = 4
## Distance between crate centres: x = rows, z = across
@export var crate_spacing: Vector3 = Vector3(1.1, 0.0, 1.1)

## Where the first crate goes (front corner of the tabletop)
@onready var _anchor: Marker3D = $CratePlace
## Shows how many crates are on the table
@onready var crate_label: Label3D = $CrateLabel

## One entry per spot on the table, null when the spot is free
var _spots: Array[WineBox] = []

func _ready() -> void:
	_spots.resize(crates_across * crates_deep)

## Keeps the label up to date, also when a player picks a crate back up
func _process(_delta: float) -> void:
	_check_spots()
	var used := _spots.size() - _spots.count(null)
	crate_label.text = "Crates %d" % used
	crate_label.visible = is_player_near()

## Frees spots whose crate has been picked up by a player
func _check_spots() -> void:
	for i in _spots.size():
		var box := _spots[i]
		if box and (not is_instance_valid(box) or box.get_parent() != self):
			_spots[i] = null

## Index of the first free spot, or -1 if the table is full
func _free_spot() -> int:
	_check_spots()
	return _spots.find(null)

## Only full crates, and only while there's room
func can_accept_item(item: Item) -> bool:
	var box := item as WineBox
	return box != null and box.bottles > 0 and _free_spot() != -1

func accept_item(player: Player) -> void:
	if not can_accept_item(player.held_item):
		return
	var index := _free_spot()
	var box := player.transfer_item() as WineBox
	player.remove_collision_exception_with(box)
	box.reparent(self)
	box.global_position = _spot_global_position(index)
	box.rotation = Vector3.ZERO
	box.freeze = true
	_spots[index] = box

## Where spot number index is: across first, then row by row
func _spot_global_position(index: int) -> Vector3:
	var across := index % crates_across
	@warning_ignore("integer_division")
	var row := index / crates_across
	var offset := Vector3(row * crate_spacing.x, 0.0, across * crate_spacing.z)
	return _anchor.global_position + _anchor.global_transform.basis.orthonormalized() * offset

func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	_check_spots()
	var used := _spots.size() - _spots.count(null)
	return "Put a crate here (%d/%d)" % [used, _spots.size()]
