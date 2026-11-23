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
## How many layers can be stacked on the crate table
@export var crates_high: int = 3
## Distance between crate centres: x = rows, y = layers, z = across
@export var crate_spacing: Vector3 = Vector3(0.9, 0.6, 0.7)
## Crate turn, to fit better on table
@export var crate_turn: float = 90.0

## Where the first crate goes (front corner of the tabletop)
@onready var _anchor: Marker3D = $CratePlace
## Shows how many crates are on the table
@onready var crate_label: Label3D = $CrateLabel

## One entry per spot on the table, null when the spot is free
var _spots: Array[WineBox] = []

func _ready() -> void:
	_spots.resize(crates_across * crates_deep * crates_high)
	# When a crate is taken, the one under it becomes the top one
	child_exiting_tree.connect(func(_node): _update_pickable.call_deferred())

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
	box.rotation = Vector3(0.0, deg_to_rad(crate_turn), 0.0)
	box.freeze = true
	_spots[index] = box
	_update_pickable()

## Where spot number index is: across first, then row by row
## then the next layer on top in the same order
func _spot_global_position(index: int) -> Vector3:
	var per_layer := crates_across * crates_deep
	@warning_ignore("integer_division")
	var layer := index / per_layer
	var i := index % per_layer
	var across := i % crates_across
	@warning_ignore("integer_division")
	var row := i / crates_across
	var offset := Vector3(row * crate_spacing.x, layer * crate_spacing.y, across * crate_spacing.z)
	return _anchor.global_position + _anchor.global_transform.basis.orthonormalized() * offset

## Only the top crate in each stack can be picked up, so nothing floats
func _update_pickable() -> void:
	_check_spots()
	var per_layer := crates_across * crates_deep
	for i in _spots.size():
		var box := _spots[i]
		if box == null:
			continue
		var above := i + per_layer
		box.can_pick_up = above >= _spots.size() or _spots[above] == null

func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	_check_spots()
	var used := _spots.size() - _spots.count(null)
	return "Put a crate here (%d/%d)" % [used, _spots.size()]
