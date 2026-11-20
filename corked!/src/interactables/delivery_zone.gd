# delivery_zone.gd
class_name DeliveryZone
extends Interactable

## Emitted whenever the crate is loaded, with the total bottles now on board.
## game.gd listens to this to update the quota on the HUD.
signal contents_changed(bottles: int)

## How many crates fit side by side in the truck (Z)
@export var crates_across: int = 2
## How many rows fit from the back wall to the door (X)
@export var crates_deep: int = 3
## Distance between crate centers: x = towards doors, y = per layer, z = across
@export var crate_spacing: Vector3 = Vector3(1.1, 0.55, 1.1)

## Wine boxes dropped off but not yet sent away.
## Holds the actual nodes so different wine types can be told apart. 
## If we later want to differentiate between wine quality or amount or type
var held_items: Array[WineBox] = []

## Where the first crate goes (deepest corner of the cargo flooooooor)
@onready var _anchor: Marker3D = $CratePlace

## True once the truck has been sent, no more loading after that
var _locked: bool = false
## False while the driver is on his smoke break, game.gd opens it
var _open: bool = false

## Puts one wine box in the next free spot in the truck and locks it there
func _handle_delivery(box: WineBox) -> void:
	var index := held_items.size()
	held_items.append(box)
	
	# locked so nobody can pick it back out of the truck
	box.can_pick_up = false
	box.freeze = true
	
	box.reparent(self)
	box.position = _slot_position(index)
	box.rotation = Vector3.ZERO
	
	contents_changed.emit(bottle_count())

## Works out where crate number index sits. Fills across first, then row by row
## towards the door, then stacks a new layer on top
func _slot_position(index: int) -> Vector3:
	var per_layer := crates_across * crates_deep
	var across := index % crates_across
	@warning_ignore("integer_division")
	var row := (index % per_layer) / crates_across
	@warning_ignore("integer_division")
	var layer := index / per_layer
	return _anchor.position + Vector3 (
		row * crate_spacing.x,
		layer * crate_spacing.y,
		across * crate_spacing.z
	)

## Hands everything over to the caller and empties the pad.
func take_all() -> Array[WineBox]:
	var items := held_items.duplicate()
	held_items.clear()
	return items

## Returns true if delivery_zone is empty
func is_empty() -> bool:
	return held_items.is_empty()

## Total bottles across every loaded crate
func bottle_count() -> int:
	var total := 0
	for box in held_items:
		if is_instance_valid(box):
			total += box.bottles
	return total

func lock() -> void:
	_locked = true

## The driver is back: crates can be loaded from now on
func open() -> void:
	_open = true

func is_open() -> bool:
	return _open

## Only accepts full crates, and only while the truck is still parked
func can_accept_item(item: Item) -> bool:
	var box := item as WineBox
	return _open and not _locked and box != null and box.bottles > 0

func accept_item(player: Player) -> void:
	if not can_accept_item(player.held_item):
		return
	var box := player.transfer_item() as WineBox
	player.remove_collision_exception_with(box)
	_handle_delivery(box)

## Loading is done with interact2. Returning false here means "interact"
## always goes to the Deliveryman instead
func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	if not _open:
		return "Truck closed - driver is smoking"
	return "Drop off wine (%d)" % held_items.size()
