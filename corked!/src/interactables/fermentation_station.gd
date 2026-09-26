# fermentation_station.gd
class_name FermentationStation
extends Interactable

## The player stands at the hopper (PourMarker) and presses "interact" while
## holding a juice barrel. The juice is poured into the station, and the player
## keeps the now-empty barrel. After ferment_time seconds the juice becomes wine,
## 1 to 1, in the output barrel at BarrelMarker. Once that barrel is full it can
## be picked up, and a new empty one spawns there.

const BARREL_SCENE: PackedScene = preload("res://scenes/items/barrel.tscn")

## Model with a lid, used for the sealed wine barrels this station produces
const LID_MODEL: PackedScene = preload("res://assets/models/barrelLid/barrel_lid.glb")

## Seconds it takes for poured juice to turn into wine
@export var ferment_time: float = 8.0

## How close (in meters, ignoring height) the player must stand to the hopper
@export var pour_range: float = 1.6

@onready var ferment_timer: Timer = $FermentTimer
@onready var barrel_marker: Marker3D = $BarrelMarker
@onready var pour_marker: Marker3D = $PourMarker

## The barrel at the output spot that wine goes into
var output_barrel: Barrel = null

## Juice poured in that has not finished fermenting yet
var _fermenting_amount: int = 0

func _ready() -> void:
	ferment_timer.one_shot = true
	ferment_timer.wait_time = ferment_time
	ferment_timer.timeout.connect(_on_ferment_timer_timeout)
	_spawn_output_barrel()

## Spawns a new output barrel once the finished one has been carried away
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(output_barrel) \
			or output_barrel.get_parent() != barrel_marker:
		_spawn_output_barrel()

## Creates a hidden, locked barrel at the output spot, with a lid on it
func _spawn_output_barrel() -> void:
	output_barrel = BARREL_SCENE.instantiate()
	output_barrel.is_wine = true
	output_barrel.can_pick_up = false
	output_barrel.freeze = true
	output_barrel.visible = false
	_put_lid_on(output_barrel)
	barrel_marker.add_child(output_barrel)
	output_barrel.position = Vector3.ZERO
	output_barrel.rotation = Vector3.ZERO

## Swaps the open-top barrel model for the model with a lid
func _put_lid_on(barrel: Barrel) -> void:
	var open_model := barrel.get_node_or_null("barrel_nolid")
	if open_model:
		barrel.remove_child(open_model)
		open_model.queue_free()
	var lid_model := LID_MODEL.instantiate()
	lid_model.name = "barrel_lid"
	barrel.add_child(lid_model)

## True if the player is standing at the hopper (ignores height)
func _is_at_hopper(player: Player) -> bool:
	var p := player.global_position
	var h := pour_marker.global_position
	return Vector2(p.x, p.z).distance_to(Vector2(h.x, h.z)) <= pour_range

## Space left in the output barrel, counting juice that is still fermenting
func _free_space() -> int:
	return output_barrel.MAX_CAPACITY - output_barrel.juice_amount - _fermenting_amount

## Only works at the hopper, with a held juice barrel (not wine), if there is room
func can_interact(player: Player) -> bool:
	if not is_instance_valid(output_barrel) or not player.is_holding():
		return false
	if not _is_at_hopper(player):
		return false
	var held := player.held_item as Barrel
	if held == null or held.is_wine or held.juice_amount <= 0:
		return false
	return _free_space() > 0

## Pours as much juice as fits into the station. The player keeps the barrel.
func interact(player: Player) -> void:
	if not can_interact(player):
		return

	var held := player.held_item as Barrel
	var amount := mini(held.juice_amount, _free_space())
	held.juice_amount -= amount
	_fermenting_amount += amount
	print("Poured ", amount, " juice into fermentation station")

	if ferment_timer.is_stopped():
		ferment_timer.start()

func _on_ferment_timer_timeout() -> void:
	_finish_fermenting()

## Turns all fermenting juice into wine. Shows the barrel, and unlocks it when full.
## Prints to the console whether the wine barrel is full or not.
func _finish_fermenting() -> void:
	if _fermenting_amount <= 0:
		return
	output_barrel.add_juice(_fermenting_amount)
	_fermenting_amount = 0
	output_barrel.visible = true

	if output_barrel.juice_amount >= output_barrel.MAX_CAPACITY:
		output_barrel.can_pick_up = true
		print("Wine barrel is FULL (%d/%d) - ready to pick up!" % [output_barrel.juice_amount, output_barrel.MAX_CAPACITY])
	else:
		print("Wine barrel is NOT full yet (%d/%d) - pour in more juice" % [output_barrel.juice_amount, output_barrel.MAX_CAPACITY])

func get_prompt() -> String:
	if not is_instance_valid(output_barrel):
		return "No barrel"
	if output_barrel.juice_amount >= output_barrel.MAX_CAPACITY:
		return "Wine ready, pick up the barrel"
	if not ferment_timer.is_stopped():
		return "Fermenting... (%d)" % _fermenting_amount
	return "Pour juice at the hopper (%d/%d)" % [output_barrel.juice_amount, output_barrel.MAX_CAPACITY]
