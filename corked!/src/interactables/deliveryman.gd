# deliveryMan.gd
class_name DeliveryMan
extends Interactable

## Emitted the moment a player sends the truck, with total bottles on board
signal delivery_sent(bottles:int)
## Emitted when the truck has finished driving away
signal drive_off_finished

## The zone this desk ships from. Assign in the inspector.
@export var delivery_zone: DeliveryZone
## The node that moves when the truck drives off (the DeliveryPoint root)
@export var truck: Node3D
## Truck model with the back doors open, shown while loading
@export var open_model: Node3D
## Truck model with the back doors closed, shown while driving off
@export var closed_model: Node3D
## Where the driver walks to before getting in (Marker3D by the cab door)
@export var truck_door: Marker3D
## Seconds the driver takes to walk to the truck door
@export var walk_time: float = 2.5

## How far the truck drives forwards before the day ends (this is a rand numb for now)
@export var drive_distance: float = 30.0
## Seconds the drive-off takes
@export var drive_time: float = 2.5

## True once the truck has been sent, so it cant be sent twice (a variable for now since I dont know
## if we should send the truck multiple times)
var _sent: bool = false

## DELIVERY MAN FUNCTIONS

func _ready() -> void:
	_set_doors_open(false)

## Sends the driver off with everything on the pad.
func finish_delivery() -> void:
	_sent = true
	delivery_zone.lock()
	delivery_sent.emit(delivery_zone.bottle_count())
	
	_set_doors_open(false)
	
	if truck == null:
		_on_drive_off_done()
		return

	var tween := create_tween()
	print("truck_door is: ", truck_door)
	
	# 1 - Truck driver walking to the truck door
	if truck_door:
		print("walking to ", truck_door.global_position, " from ", global_position)
		var door_pos := truck_door.global_position
		look_at(Vector3(door_pos.x, global_position.y, door_pos.z))
		tween.tween_property(self, "global_position", door_pos, walk_time)
	
	# 2 - Truck driver drinks a redbull and gets in the truck
	tween.tween_callback(_hide_driver)
	
	# 3 - Drive away. The truck is at the trucks local -X, so drive that way
	# On our screen that will be north aka up aka out of map
	if truck:
		var forward: Vector3 = -truck.global_basis.x.normalized()
		var target: Vector3 = truck.global_position + forward * drive_distance
		tween.tween_property(truck, "global_position", target, drive_time) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(_on_drive_off_done)
	
## Clears the crates once the truck is gone
func _on_drive_off_done() -> void:
	for box in delivery_zone.take_all():
		box.queue_free()
	drive_off_finished.emit()

## Shows the open or closed truck model
func _set_doors_open(open: bool) -> void:
	if open_model:
		open_model.visible = open
	if closed_model: 
		closed_model.visible = not open

## The driver is back from his smoke break: open the doors and the loading spot
func open_for_loading() -> void:
	if _sent:
		return
	delivery_zone.open()
	_set_doors_open(true)

## The driver dissapears, aka gets in the truck: I just hide him for now
func _hide_driver() -> void:
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)

## INTERACTABLE FUNCTIONS

## Can only send once, and only with something in the truck
func can_interact(_player: Player) -> bool:
	return not _sent and delivery_zone != null and not delivery_zone.is_empty()

func interact(player: Player) -> void:
	if not can_interact(player):
		return
	finish_delivery()

func get_prompt() -> String:
	if _sent:
		return "On the way!"
	if not delivery_zone.is_open():
		return "Driver is on smoke break"
	return "Send truck and bottles (%d bottles)" % delivery_zone.bottle_count()
