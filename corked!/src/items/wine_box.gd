# wine_box.gd
class_name WineBox
extends Item

## How many bottles that fit in a crate
@export var capacity: int = 4

## Bottles currently in the crate
var bottles: int = 0

@onready var _empty_visual: Node3D = $EmptyVisual
@onready var _full_visual: Node3D = $FullVisual
@onready var _slots: Array[Node] = $BottleSlots.get_children()

func _ready() -> void:
	display_name = "Wine Crate"
	can_drop = false # Only the crate table and the open truck take crates
	_update_visuals()

func is_full() -> bool:
	return bottles >= capacity

func next_slot_global_position() -> Vector3:
	if bottles < _slots.size():
		return (_slots[bottles] as Node3D).global_position
	return global_position

## Puts a bottle node into the next free slot
func add_bottle(bottle: Node3D) -> void:
	var slot: Node = self
	if bottles < _slots.size():
		slot = _slots[bottles]
	
	if bottle.get_parent():
		bottle.reparent(slot)
	else:
		slot.add_child(bottle)
	bottle.position = Vector3.ZERO
	bottle.rotation = Vector3.ZERO
	
	bottles += 1
	_update_visuals()

func _update_visuals() -> void:
	var full := is_full()
	_full_visual.visible = full
	_empty_visual.visible = not full
	for slot in _slots:
		slot.visible = not full

func get_display_name() -> String:
	return "%s (%d/%d)" % [display_name, bottles, capacity]
