# fermentation_station.gd
class_name FermentationStation
extends Interactable

## Emitted after every skill check press. success is true on a hit
signal check_result(success: bool)
## Emitted when the pressure sat in red long enough to ruin one unit
signal potential_lost
## Emitted when the needle did a full lap without a press
signal progress_lost

## The three pressure zones on the bar
enum Zone { RED, YELLOW, GREEN }

## Gameplay flow:
## 1. Player stands at the hopper (PourMarker) holding a juice barrel and
##    presses interact once per unit. Every unit in the tank is one unit of
##    wine potential.
## 2. Player docks an empty barrel at the output (BarrelMarker) with
##    interact2. The pressure minigame only starts once the tank has juice
##    AND a barrel is docked, so the popup does not show up while pouring.
## 3. While the minigame runs the pressure slowly drops, also when nobody
##    is at the station. Pressing interact while the needle is inside the
##    target zone raises the pressure, a bad press lowers it.
##    Green = wine flows, yellow = paused, red = paused and one
##    unit of juice is lost every red_loss_time seconds. A bad press while
##    already in red also loses juice right away.
## 4. The minigame ends when the barrel is full or the tank is empty.
##
## All tuning values live in the FermentationSettings autoload so modifiers
## can change them during the game.

## Juice units poured per interact press
@export var pour_per_press: int = 1
## How close (in meters, ignoring height) the player must stand to the hopper
@export var pour_range: float = 1.6
## How close (in meters, ignoring height) the player must stand to the
## output spot to dock a barrel
@export var dock_range: float = 3.0
## How close (in meters, ignoring height) the player must stand to keep
## playing the minigame, no matter which way they are facing
@export var minigame_range: float = 3.0

@onready var barrel_marker: Marker3D = $BarrelMarker
@onready var pour_marker: Marker3D = $PourMarker
@onready var tank_label: Label3D = $TankLabel

## Barrel docked at the output spot, if any
var barrel: Barrel = null
## Juice in the tank waiting to become wine (= wine potential)
var _tank_amount: int = 0

## Current pressure, 0 -> 100
var pressure: float = 0.0
## Needle angle in radians. 0 = top, grows clockwise
var needle_angle: float = 0.0
## Where the target zone starts, same units as needle_angle
var zone_start: float = 0.0
## 0 -> 1 progress towards the next unit of wine in the docked barrel
var fill_progress: float = 0.0

## True while the pressure minigame is running
var _active: bool = false
## Seconds spent in red since we last lost a unit
var _red_time: float = 0.0
## Time left before another press counts
var _cooldown: float = 0.0
## How far the needle has turned since the last press, in radians
var _angle_since_press: float = 0.0


func _ready() -> void:
	add_to_group("fermentation_stations")
	_connect_window()


## Gives the popup window a reference to this station so it can draw it
func _connect_window() -> void:
	var mount := get_node_or_null("MinigameWindowPreview")
	if mount == null or mount.window == null:
		return
	if mount.window.has_method("set_station"):
		mount.window.set_station(self)


## True while the minigame runs (juice in the tank and a barrel to fill).
## The window manager uses this to keep the popup visible.
func is_running() -> bool:
	return _active


## True when the minigame runs and the player is close enough to play it,
## no matter which way they are facing
func can_play_from(player: Player) -> bool:
	return _active and _flat_distance(player.global_position, global_position) <= minigame_range


## Everything runs here, also when no player is near, so the pressure keeps
## dropping while players are away fixing something else
func _process(delta: float) -> void:
	tank_label.text = "Tank %d/%d" % [_tank_amount, FermentationSettings.tank_capacity]
	tank_label.visible = is_player_near()
	# Only run when there is juice AND a docked barrel with room for wine
	var should_run := _tank_amount > 0 and is_filling()
	if should_run and not _active:
		_start_minigame()
	elif not should_run and _active:
		_end_minigame()
	if not _active:
		return
	_update_needle(delta)
	_update_pressure(delta)
	_update_production(delta)


## Clears the barrel if the player picked it back up
func _check_barrel() -> void:
	if barrel and (not is_instance_valid(barrel) or barrel.get_parent() != barrel_marker):
		barrel = null
		fill_progress = 0.0


## Distance between two points, ignoring height
func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


## Finds the player holding this item (the hand marker sits under the player)
func _holder_of(item: Item) -> Player:
	var node: Node = item.get_parent()
	while node != null and not (node is Player):
		node = node.get_parent()
	return node as Player


## Which zone the pressure is in right now
func get_zone() -> Zone:
	if pressure < FermentationSettings.red_limit:
		return Zone.RED
	if pressure < FermentationSettings.green_limit:
		return Zone.YELLOW
	return Zone.GREEN


## Target zone size in radians
func zone_size() -> float:
	return deg_to_rad(FermentationSettings.zone_size_degrees)


## Units of wine potential left in the tank
func get_tank_amount() -> int:
	return _tank_amount


## Seconds until the next unit is lost while in red
func time_until_loss() -> float:
	return maxf(FermentationSettings.red_loss_time - _red_time, 0.0)


## True when a docked barrel still has room for wine
func is_filling() -> bool:
	_check_barrel()
	return barrel != null and barrel.juice_amount < barrel.MAX_CAPACITY


## Production speed for the current zone (1.0 = normal)
func production_speed() -> float:
	match get_zone():
		Zone.GREEN:
			return 1.0
		Zone.YELLOW:
			return FermentationSettings.yellow_speed
	return 0.0


## Resets the pressure and needle when the tank has juice and a barrel is docked
func _start_minigame() -> void:
	_active = true
	pressure = FermentationSettings.start_pressure
	_red_time = 0.0
	_cooldown = 0.0
	_angle_since_press = 0.0
	fill_progress = 0.0
	needle_angle = 0.0
	_new_zone()
	print("Fermentation started - keep the pressure up!")


## Barrel full or tank empty, frees the barrel so it can be picked up
func _end_minigame() -> void:
	_active = false
	_red_time = 0.0
	fill_progress = 0.0
	_check_barrel()
	if barrel:
		barrel.can_pick_up = true
	print("Fermentation done")


## Places a new target zone somewhere ahead of the needle
func _new_zone() -> void:
	zone_start = needle_angle + randf_range(0.35, 0.85) * TAU


## Spins the needle and moves the zone if the needle passed it
func _update_needle(delta: float) -> void:
	needle_angle += TAU / FermentationSettings.needle_lap_time * delta
	# A full lap without any press costs a little barrel progress
	_angle_since_press += TAU / FermentationSettings.needle_lap_time * delta
	if _angle_since_press >= TAU:
		_angle_since_press -= TAU
		_lose_lap_progress()
	_cooldown = maxf(_cooldown - delta, 0.0)
	# Needle went past the zone without a press: no penalty, just a new zone
	var grace := deg_to_rad(FermentationSettings.hit_grace_degrees)
	if needle_angle > zone_start + zone_size() + grace:
		_new_zone()
	# Keep the numbers small, both move together so nothing visibly changes
	if needle_angle >= TAU:
		needle_angle -= TAU
		zone_start -= TAU


## True when the needle is inside the target zone (with a little grace)
func _is_needle_in_zone() -> bool:
	var grace := deg_to_rad(FermentationSettings.hit_grace_degrees)
	return needle_angle >= zone_start - grace and needle_angle <= zone_start + zone_size() + grace


## One press of the skill check. A bad press while already in red also
## spills juice from the tank right away
func _skill_check() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = FermentationSettings.press_cooldown
	_angle_since_press = 0.0
	var success := _is_needle_in_zone()
	var was_red := get_zone() == Zone.RED
	if success:
		pressure = minf(pressure + FermentationSettings.hit_gain, 100.0)
	else:
		pressure = maxf(pressure - FermentationSettings.miss_penalty, 0.0)
	check_result.emit(success)
	_new_zone()
	if not success and was_red:
		for i in FermentationSettings.red_miss_loss:
			if _tank_amount <= 0:
				break
			_lose_potential()


## Drains the pressure and counts time spent in red
func _update_pressure(delta: float) -> void:
	pressure = maxf(pressure - FermentationSettings.drain_per_second * delta, 0.0)
	if get_zone() == Zone.RED:
		_red_time += delta
		if _red_time >= FermentationSettings.red_loss_time:
			_red_time -= FermentationSettings.red_loss_time
			_lose_potential()
	else:
		_red_time = 0.0


## Red for too long: one unit of juice is ruined
func _lose_potential() -> void:
	_tank_amount -= 1
	potential_lost.emit()
	print("Pressure too low! Lost one unit (tank %d/%d)" % [_tank_amount, FermentationSettings.tank_capacity])
	if _tank_amount <= 0:
		_tank_amount = 0


## Needle went a full lap without a press: lose a bit of the unit flowing now
func _lose_lap_progress() -> void:
	fill_progress = maxf(fill_progress - FermentationSettings.idle_lap_loss, 0.0)
	progress_lost.emit()


## Fills the docked barrel at the speed the pressure zone allows
func _update_production(delta: float) -> void:
	if not is_filling():
		return
	barrel.can_pick_up = false
	fill_progress += delta * production_speed() / FermentationSettings.fill_step_time
	if fill_progress >= 1.0:
		fill_progress -= 1.0
		_fill_one_unit()


## Moves one unit of wine from the tank into the docked barrel
func _fill_one_unit() -> void:
	barrel.is_wine = true
	barrel.add_juice(1)
	_tank_amount -= 1

	if barrel.juice_amount >= barrel.MAX_CAPACITY:
		barrel.can_pick_up = true
		fill_progress = 0.0
		print("Wine barrel is FULL (%d/%d) - ready to pick up!" % [barrel.juice_amount, barrel.MAX_CAPACITY])


## Docking (interact2): only takes an empty, non-wine barrel, one at a time,
## from a player standing near the output spot
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
	fill_progress = 0.0
	print("Empty barrel docked at fermentation station")


## True when the player is at the hopper with juice and the tank has room
func _can_pour(player: Player) -> bool:
	if not player.is_holding():
		return false
	if _flat_distance(player.global_position, pour_marker.global_position) > pour_range:
		return false
	var held := player.held_item as Barrel
	if held == null or held.is_wine or held.juice_amount <= 0:
		return false
	return _tank_amount < FermentationSettings.tank_capacity


func can_interact(player: Player) -> bool:
	return _can_pour(player) or _active


## Interact: pours juice if the player can, otherwise the press is a skill check
func interact(player: Player) -> void:
	if _can_pour(player):
		_pour(player)
	elif _active:
		_skill_check()


## Pours one level of juice per press into the tank
func _pour(player: Player) -> void:
	var held := player.held_item as Barrel
	var room := FermentationSettings.tank_capacity - _tank_amount
	var amount := mini(pour_per_press, mini(held.juice_amount, room))
	held.juice_amount -= amount
	_tank_amount += amount
	print("Poured %d juice (barrel %d/%d left, tank %d/%d)" % [amount, held.juice_amount, held.MAX_CAPACITY, _tank_amount, FermentationSettings.tank_capacity])


func get_prompt() -> String:
	_check_barrel()
	var cap := FermentationSettings.tank_capacity
	if barrel and barrel.juice_amount >= barrel.MAX_CAPACITY:
		return "Wine ready, pick up the barrel"
	if _active:
		match get_zone():
			Zone.RED:
				return "Pressure critical! Hit the zone!"
			Zone.YELLOW:
				return "Pressure low - hit the zone (tank %d/%d)" % [_tank_amount, cap]
		return "Pressure stable (tank %d/%d)" % [_tank_amount, cap]
	if _tank_amount > 0 and barrel == null:
		return "Place an empty barrel at the output (tank %d/%d)" % [_tank_amount, cap]
	return "Pour juice at the hopper (tank %d/%d)" % [_tank_amount, cap]
