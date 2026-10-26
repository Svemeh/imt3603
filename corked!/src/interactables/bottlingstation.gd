# bottlingstation.gd
class_name BottlingStation
extends Interactable

## Emitted when the machine breaks down
signal broke
## Emitted on every hammer hit, ratio goes 0.0 -> 1.0
signal repair_progress(ratio: float)
## Emitted when the machine is fixed
signal fixed

## Gameplay Flow:
## 1. Player hands over WINE barrel (interact2, same as stomping station
##    It docks at the barrelMaker. Player can take back bottle at any time
##
## 2. Player presses interact: one unit of wine fills the bottle, new bottle
##    spawns in, and the old bottle gets capped and sent to the box
##
## 3. When the crate is full a player then needs to deliver the wine crate 
##    to the delivery zone
##
## 4. When barrel is empty it turn back to a normal barrel and can be reused
##    at stomping station again


## The crate item that bottles go into
const WINE_BOX_SCENE: PackedScene = preload("res://scenes/items/wine_box.tscn")
## The empty bottle visual
const EMPTY_BOTTLE_SCENE: PackedScene = preload("res://scenes/items/empty_wine_bottle.tscn")
## The decorated bottle visual
const WINE_BOTTLE_SCENE: PackedScene = preload("res://scenes/items/full_wine_bottle.tscn")


## Seconds the bottle takes to fill
@export var fill_time: float = 0.5
## Seconds for the bottle to ride from the filler to the end of the conveyor
@export var travel_time: float = 1.2
## Seconds for the bottle to hop from the conveyor into the crate
@export var hop_time: float = 0.4
## How high the bottle arcs on its way into the crate
@export var hop_height: float = 0.5
## Seconds the bottle stops under the capper while it gets decorated
@export var cap_time: float = 0.4
## Chance (0-1) the machine breaks after a bottle, right after a repair
@export var base_break_chance: float = 1.0
## How much the chance grows with every bottle that doesn't break it
@export var break_chance_step: float = 0.05
## Hammer hits needed to fix the machine
@export var hits_to_fix: int = 4


## Where the docked barrel sits
@onready var barrel_marker: Marker3D = $BarrelMarker
## Where the crate sits
@onready var crate_marker: Marker3D = $CrateMarker
## Marker3D the bottle travels through, in order (filler -> order -> conveyor
## end)
@onready var _path_points: Array[Node] = $BottlePath.get_children()


## The barrel currently docked at the station, if any
var barrel: Barrel = null
## Crate currently being filled
var crate: WineBox = null
## True while a bottle is moving down the line
var _busy: bool = false
## True while the machine is broken and need the hammer
var is_broken: bool = false
## Current chance of breaking after the next bottle
var _break_chance: float = 0.0
## Hammer hits so far on the current breakdown
var _hits: int = 0


func _ready() -> void:
	## To start the break chance
	_break_chance = base_break_chance
	_spawn_crate()


## Spawns a new empty crate as soon as the full one has been carried away
func _physics_process(_delta: float) -> void:
	if (crate == null or not is_instance_valid(crate) or crate.get_parent() 
	!= crate_marker):
		_spawn_crate()


## Function for spawn crate
func _spawn_crate() -> void:
	crate = WINE_BOX_SCENE.instantiate()
	crate.freeze = true
	crate.can_pick_up = false		# locked until full
	crate_marker.add_child(crate)


## Clears the barrel reference if the player picked it back up
func _check_barrel() -> void:
	if barrel and (not is_instance_valid(barrel) or barrel.get_parent() !=
	barrel_marker):
		barrel = null

## ------------------- Docking the Barrel -----------------------------

## Only takes barrels that hold finished wine, and only one at a time
func can_accept_item(item: Item) -> bool:
	_check_barrel()
	# a hammer counts as "accepted" only when theres something to fix
	if item is Hammer:
		return is_broken
	var held := item as Barrel
	return (held != null and barrel == null and held.is_wine and
			held.juice_amount > 0)


func accept_item(player: Player) -> void:
	# hitting with the hammer: the player keeps it
	if player.held_item is Hammer:
		_hit()
		return
	
	var item := player.transfer_item()
	player.remove_collision_exception_with(item)
	
	barrel = item
	item.reparent(barrel_marker)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.freeze = true


## ------------------------- Bottling ---------------------------

func can_interact(_player: Player) -> bool:
	_check_barrel()
	if is_broken or _busy or barrel == null or crate == null or not is_instance_valid(crate):
		return false
	return barrel.is_wine and barrel.juice_amount > 0 and not crate.is_full()


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	
	_busy = true
	
	_busy = true
	barrel.juice_amount -= 1
	if barrel.juice_amount <= 0:
		# empty barrel turn back to normal barrel for next batch
		barrel.is_wine = false
	
	## The bottle is a holder node with EMPTY bottle model inside
	## At the capper it the model inside is swapped for finsihed wine bottle
	var bottle := Node3D.new()
	bottle.add_child(EMPTY_BOTTLE_SCENE.instantiate())
	add_child(bottle)
	bottle.global_position = (_path_points[0] as Node3D).global_position
	bottle.scale = Vector3.ONE * 0.01
	var target_crate := crate
	
	var tween := create_tween()
	# pops in under tank and fills
	tween.tween_property(bottle, "scale", Vector3.ONE, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(fill_time)
	
	# rides down the conveyor
	var legs := _path_points.size() - 1
	for i in range(1, _path_points.size()):
		var point := _path_points[i] as Node3D
		tween.tween_property(bottle, "global_position", point.global_position, travel_time / maxi(legs, 1))
	
	# Under the capper, stop and turn into the finished wine bottle
		if point.name == "CapPoint":
			tween.tween_interval(cap_time * 0.5)
			tween.tween_callback(_finished_bottle.bind(bottle))
			tween.tween_interval(cap_time * 0.5)
	
	# hops into crate in an arc (once after the loop)
	var hop_from := (_path_points[-1] as Node3D).global_position
	var hop_to := target_crate.next_slot_global_position()
	tween.tween_method(_hop_bottle.bind(bottle, hop_from, hop_to), 0.0, 1.0, hop_time)
	tween.tween_callback(_on_bottle_arrived.bind(bottle, target_crate))


func _on_bottle_arrived(bottle: Node3D, target_crate: WineBox) -> void:
	_busy = false
	if is_instance_valid(target_crate):
		target_crate.add_bottle(bottle)
		if target_crate.is_full():
			target_crate.can_pick_up = true
	else:
		bottle.queue_free()
	_roll_breakdown()

## After each bottle: maybe machine break, otherwise make break after next bottle
## more likely
func _roll_breakdown() -> void:
	if randf() < _break_chance:
		_break()
	else:
		_break_chance = minf(_break_chance + break_chance_step, 1.0)


## Stops the machine until someone fixes it with the hammer
func _break() -> void:
	is_broken = true
	_hits = 0
	_break_chance = base_break_chance
	broke.emit()
	print("Bottling station broke down!")


## One hammer hit. Enough hits and the machine works again
func _hit() -> void:
	_hits += 1
	repair_progress.emit(float(_hits) / hits_to_fix)
	print("Hit %d/%d" % [_hits, hits_to_fix])
	if _hits >= hits_to_fix:
		is_broken = false
		fixed.emit()
		print("Bottling station fixed!")


## Moves the bottle along an arc from the conveyor end to its crate slot.
## t goes from 0 to 1 over hop_time
func _hop_bottle(t: float, bottle: Node3D, from: Vector3, to: Vector3) -> void:
	bottle.global_position = from.lerp(to, t) + Vector3.UP * sin(t * PI) * hop_height


## Instances the full bottle model
func _finished_bottle(bottle: Node3D) -> void:
	for child in bottle.get_children():
		child.queue_free()
	bottle.add_child(WINE_BOTTLE_SCENE.instantiate())


func get_prompt() -> String:
	_check_barrel()
	if is_broken:
		return "Broken! Hit it with the hammer (%d/%d)" % [_hits, hits_to_fix]
	if crate and is_instance_valid(crate) and crate.is_full():
		return "Crate full - pick it up"
	if _busy:
		return "Bottling ..."
	if barrel == null:
		return "Place a wine barrel here"
	if not barrel.is_wine or barrel.juice_amount <= 0:
		return "Barrel empty - take it back"
	return "Bottle wine (%d/%d)" % [crate.bottles, crate.capacity]


## Tells the popup manager whether this machine needs its window to stay open
## even when a player walks away to fetch the hammer. For now, _busy covers
## the existing bottle-filling/travel sequence and clears when the bottle arrives.
## Include paused-for-repair/jammed states here when that minigame is added.
func is_running() -> bool:
	return _busy
