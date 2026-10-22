# fermentation_station.gd
class_name FermentationStation
extends Interactable

## Gameplay flow:
## 1. Player stands at the hopper (PourMarker) holding a juice barrel and
##    presses interact once per unit. Each press pours one level of juice
##    into the tank, so a full barrel takes MAX_CAPACITY presses.
## 2. Player walks to the output spot (BarrelMarker) and hands the empty
##    barrel over with interact2. It snaps into place like at the stomping
##    station.
## 3. The tank fills the docked barrel with wine, one unit every
##    fill_step_time seconds. The barrel is locked while filling and unlocks
##    when it is full or the tank runs out.

## Max juice units the tank can hold at once
@export var tank_capacity: int = 4

## Juice units poured per interact press
@export var pour_per_press: int = 1

## Seconds for each unit of wine to flow into the docked barrel
@export var fill_step_time: float = 2.0

## How close (in meters, ignoring height) the player must stand to the hopper
@export var pour_range: float = 1.6

## How close (in meters, ignoring height) the player must stand to the
## output spot to dock a barrel
@export var dock_range: float = 3.0

@onready var ferment_timer: Timer = $FermentTimer
@onready var barrel_marker: Marker3D = $BarrelMarker
@onready var pour_marker: Marker3D = $PourMarker

## Barrel docked at the output spot, if any
var barrel: Barrel = null

## Juice in the tank waiting to become wine
var _tank_amount: int = 0

func _ready() -> void:
	ferment_timer.one_shot = false
	ferment_timer.wait_time = fill_step_time
	ferment_timer.timeout.connect(_on_ferment_timer_timeout)

## Clears the barrel if the player picked it back up
func _check_barrel() -> void:
	if barrel and (not is_instance_valid(barrel) or barrel.get_parent() != barrel_marker):
		barrel = null
		ferment_timer.stop()

## Distance between two points, ignoring height
func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

## Finds the player holding this item (the hand marker sits under the player)
func _holder_of(item: Item) -> Player:
	var node: Node = item.get_parent()
	while node != null and not (node is Player):
		node = node.get_parent()
	return node as Player

## ------------------- Docking the barrel (interact2) -------------------

## Only takes an empty, non-wine barrel, one at a time, from a player
## standing near the output spot
func can_accept_item(item: Item) -> bool:
	_check_barrel()
	var held := item as Barrel
	if held == null or barrel != null:
		return false
	if held.is_wine or held.juice_amount > 0:
		return false
	var holder := _holder_of(item)
	if holder == null:
		return false
	return _flat_distance(holder.global_position, barrel_marker.global_position) <= dock_range

## Snaps the barrel onto the output spot, same as the stomping station
func accept_item(player: Player) -> void:
	var item := player.transfer_item()
	player.remove_collision_exception_with(item)

	barrel = item as Barrel
	item.reparent(barrel_marker)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.freeze = true
	print("Empty barrel docked at fermentation station")

	_try_start_filling()

## ------------------- Pouring juice (interact) -------------------

## Only works at the hopper, with a held juice barrel (not wine), if the tank has room
func can_interact(player: Player) -> bool:
	if not player.is_holding():
		return false
	if _flat_distance(player.global_position, pour_marker.global_position) > pour_range:
		return false
	var held := player.held_item as Barrel
	if held == null or held.is_wine or held.juice_amount <= 0:
		return false
	return _tank_amount < tank_capacity

## Pours one level of juice per press into the tank. The barrel in the
## player's hands drops one level each time.
func interact(player: Player) -> void:
	if not can_interact(player):
		return

	var held := player.held_item as Barrel
	var amount := mini(pour_per_press, mini(held.juice_amount, tank_capacity - _tank_amount))
	held.juice_amount -= amount
	_tank_amount += amount
	print("Poured %d juice (barrel %d/%d left, tank %d/%d)" % [amount, held.juice_amount, held.MAX_CAPACITY, _tank_amount, tank_capacity])

	_try_start_filling()

## ------------------- Filling the docked barrel -------------------

## Starts filling if there is a docked barrel with room and juice in the tank
func _try_start_filling() -> void:
	_check_barrel()
	if barrel == null or _tank_amount <= 0:
		return
	if barrel.juice_amount >= barrel.MAX_CAPACITY:
		return
	barrel.can_pick_up = false
	if ferment_timer.is_stopped():
		ferment_timer.start()

## Moves one unit of wine from the tank into the docked barrel
func _on_ferment_timer_timeout() -> void:
	_check_barrel()
	if barrel == null:
		return

	barrel.is_wine = true
	barrel.add_juice(1)
	_tank_amount -= 1

	var is_full := barrel.juice_amount >= barrel.MAX_CAPACITY
	if is_full or _tank_amount <= 0:
		ferment_timer.stop()
		barrel.can_pick_up = true
		if is_full:
			print("Wine barrel is FULL (%d/%d) - ready to pick up!" % [barrel.juice_amount, barrel.MAX_CAPACITY])
		else:
			print("Wine barrel is NOT full yet (%d/%d) - pour in more juice" % [barrel.juice_amount, barrel.MAX_CAPACITY])

func get_prompt() -> String:
	_check_barrel()
	if barrel and barrel.juice_amount >= barrel.MAX_CAPACITY:
		return "Wine ready, pick up the barrel"
	if not ferment_timer.is_stopped():
		return "Filling wine... (%d/%d)" % [barrel.juice_amount, barrel.MAX_CAPACITY]
	if barrel == null and _tank_amount > 0:
		return "Place an empty barrel at the output (tank %d/%d)" % [_tank_amount, tank_capacity]
	return "Pour juice at the hopper (tank %d/%d)" % [_tank_amount, tank_capacity]
