# hammer_shelf.gd
class_name HammerShelf
extends Interactable

## Shelf in the utility room. The hammer starts here, and this is where its put
## back with interact2. Taking it is the normal item pickup (interact2), the same
## way barrels work at the stomping station, if thats not the case you, the reviewer
## can gladly change it

const HAMMER_SCENE: PackedScene = preload("res://scenes/items/hammer.tscn")

## Where the hammer lies on the shelf
@onready var hammer_marker: Marker3D = $HammerMarker

## The hammer currently on the shelf, if any
var hammer: Hammer = null

## The round starts with the hammer on the shelf
func _ready() -> void:
	add_to_group("hammer_shelf")
	var new_hammer := HAMMER_SCENE.instantiate() as Hammer
	hammer_marker.add_child(new_hammer)
	_place(new_hammer)

## Clears the reference once a player has taken the hammer
func _check_hammer() -> void:
	if hammer and (not is_instance_valid(hammer) or hammer.get_parent() != hammer_marker):
		hammer = null

## Puts the hammer back on the shelf from wherever it is (used if someone runs into a player
## with the hammer)
func return_hammer(item: Hammer) -> void:
	_check_hammer()
	if hammer != null or not is_instance_valid(item):
		return
	item.reparent(hammer_marker)
	_place(item)

## Only takkes the hammer and only when the spot free
func can_accept_item(item: Item) -> bool:
	_check_hammer()
	return item is Hammer and hammer == null

func accept_item(player: Player) -> void:
	if not can_accept_item(player.held_item):
		return
	var item := player.transfer_item() as Hammer
	player. remove_collision_exception_with(item)
	item.reparent(hammer_marker)
	_place(item)

## Locks the hammer in place on the marker
func _place(item: Hammer) -> void:
	hammer = item
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.freeze = true

## Nothing to do with interact here, its all interact2
func can_interact(_player: Player) -> bool:
	return false

func get_prompt() -> String:
	_check_hammer()
	return "Take the Hammer" if hammer else "Put the Hammer back"
