# wine_box.gd
class_name WineBox
extends Item

## How many bottles that fit in a crate
@export var capacity: int = 4

## Bottles currently in the crate
var bottles: int = 0

@onready var _empty_visual: Node3D = get_node_or_null("EmptyVisual")
@onready var _full_visual: Node3D = get_node_or_null("FullVisual")
var _slots: Array[Node] = []

func _ready() -> void:
	display_name = "Wine Crate"
	if has_node("BottleSlots"):
		_slots = $BottleSlots.get_children()
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
	if _full_visual == null:
		return
	var full := is_full()
	_full_visual.visible = full
	if _empty_visual:
		_empty_visual.visible = not full
	for slot in _slots:
		slot.visible = not full

func get_display_name() -> String:
	return "%s (%d/%d)" % [display_name, bottles, capacity]
