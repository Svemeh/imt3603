extends Node

@onready var hud = $Hud
@onready var round_timer: RoundTimer = $RoundTimer
@onready var delivery_zone = $DeliveryPoint/DeliveryZone
@onready var deliveryman = $DeliveryPoint/Deliveryman

## The overlay survives a round reset while the gameplay children are rebuilt.
@onready var round_transition = $RoundTransition

## Run state stays on Game; fresh stations/items must not reset the wallet.
var round_number: int = 1
var _resetting_round: bool = false
var _owns_pause: bool = false

const PLAYER_SCENE := preload("res://scenes/player.tscn")

const PLAYER_VARIANTS := [
	Player.PlayerVariant.YELLOW,
	Player.PlayerVariant.PURPLE,
	Player.PlayerVariant.GREEN,
	Player.PlayerVariant.BLUE
]

var money: int = 0

## Bottles the truck must carry for the day to succeed. Starts at 8 bottles
## (two full crates) and grows by a random 5-10 bottles after each successful round.
@export var quota: int = 8
## moneey earned per delivered bottle, only paid out on the successful day. We also
## need to figure out how this will work, since what if youre able to send some but
## not all? Should the game just end and full restart?
@export var money_per_bottle: int = 10

## Bottles currently loaded in truck
var loaded_bottles: int = 0
## Set once the day is won or lost, so a late timer tick can't override it
## Without this ckeck the truck could drive off last second and the round could
## count as both a loss and a win
var _day_over: bool = false


func _ready() -> void:
	round_transition.next_round_requested.connect(_request_next_round)
	_prepare_round()


## Reconnects the new round's nodes, restores the HUD and spawns the joined players.
## Used both on first load and after Skip; money and run statistics are retained.
func _prepare_round() -> void:
	hud = $Hud
	round_timer = $RoundTimer
	delivery_zone = $DeliveryPoint/DeliveryZone
	deliveryman = $DeliveryPoint/Deliveryman
	hud.update_money(money)
	hud.update_quota(loaded_bottles, quota)
	round_timer.time_updated.connect(_on_round_timer_time_updated)
	round_timer.round_ended.connect(_on_round_timer_round_ended)
	delivery_zone.contents_changed.connect(_on_delivery_zone_contents_changed)
	deliveryman.delivery_sent.connect(_on_delivery_sent)
	round_timer.start_round()

	# add the players
	for i in PlayerManager.MAX_PLAYERS:
		var device = PlayerManager.slots[i]

		if device == null:
			continue

		var p := PLAYER_SCENE.instantiate()

		p.player_index = i
		p.player_variant = PLAYER_VARIANTS[i]

		# Variant must be assigned BEFORE add_child()
		add_child(p)
		var spawns := $Map/PlayerSpawns.get_children()
		if i < spawns.size():
			p.global_position = (spawns[i] as Node3D).global_position


## Increment money up or down by x and refreshes the HUD.
func increment_money(amount: int) -> void:
	money += amount
	hud.update_money(money)


## Increments quota by x (e.g. from a valid delivery) and refreshes the HUD.
func increment_quota(amount: int) -> void:
	quota += amount
	hud.update_quota(loaded_bottles, quota)


## A crate was loaded into the truck, refreshes the quota on the HUD
func _on_delivery_zone_contents_changed(bottles: int) -> void:
	loaded_bottles = bottles
	hud.update_quota(loaded_bottles, quota)


## A player sent the truck. Quota met = yey you won my boy!
## not met/short = day lost you suck my boy!
func _on_delivery_sent(bottles: int) -> void:
	if _day_over:
		return
	_day_over = true
	round_timer.stop_round()
	
	await deliveryman.drive_off_finished
	var won := bottles >= quota
	if won:
		increment_money(bottles * money_per_bottle)
		GameStats.bottles_sold += bottles
		GameStats.money_earned += bottles * money_per_bottle
		GameStats.days_survived += 1
		print("Day won! %d/%d bottles" % [bottles, quota])
		GameStats.last_day_bottles = bottles
		GameStats.last_day_quota = quota
		# Pause only after the drive-off has finished, so the truck animation completes.
		_owns_pause = true
		get_tree().paused = true
		round_transition.show_round_over(round_number, bottles, bottles * money_per_bottle, money)
	else:
		print("Day lost, truck sent with %d/%d bottles" % [bottles, quota])
		GameStats.last_day_bottles = bottles
		GameStats.last_day_quota = quota
		GameStats.loss_reason = "The truck left short on bottles"
		get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")


## Forwards the timer's remaining time to the HUD's progress bar.
func _on_round_timer_time_updated(time_left: float) -> void:
	hud.update_timer(time_left, round_timer.round_duration)

## Called when a round's timer hits zero before the truck was sent. Ends the game.
func _on_round_timer_round_ended() -> void:
	if _day_over:
		return
	_day_over = true
	print("Day lost, time ran out")
	GameStats.last_day_bottles = loaded_bottles
	GameStats.last_day_quota = quota
	GameStats.loss_reason = "Time ran out"
	get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")


## Defer the rebuild until the Skip button has finished emitting its signal.
## The guard prevents duplicate resets from repeated controller/button events.
func _request_next_round() -> void:
	if _resetting_round or not _day_over:
		return
	_resetting_round = true
	_start_next_round.call_deferred()


## Recreate the saved gameplay scene's children instead of resetting station
## fields individually. This restores original item transforms, held/dropped items,
## station contents, breakdowns, timers, popups, players and the truck/driver.
## Future station state is reset automatically when its scene is reconstructed.
func _start_next_round() -> void:
	var fresh_round := (load(scene_file_path) as PackedScene).instantiate()
	# Preserve runtime round length if it was adjusted for development or balancing.
	fresh_round.get_node("RoundTimer").round_duration = round_timer.round_duration
	for child in get_children():
		if child == round_transition:
			continue
		# Remove immediately so old node paths and signals cannot affect the next round.
		remove_child(child)
		child.queue_free()
	# Scene ownership belongs to the temporary root. Clear those links before
	# moving its children, while keeping nested scene ownership intact.
	for node in fresh_round.find_children("*", "", true, false):
		if node.owner == fresh_round:
			node.owner = null
	for child in fresh_round.get_children():
		if child.name == "RoundTransition":
			continue
		fresh_round.remove_child(child)
		add_child(child)
	fresh_round.free()
	loaded_bottles = 0
	round_number += 1
	# Increase once per new round, before refreshing the quota display.
	quota += randi_range(5, 10)
	_day_over = false
	_prepare_round()
	await round_transition.reveal_next_round()
	get_tree().paused = false
	_owns_pause = false
	_resetting_round = false


## Do not leave the next menu paused if this scene is closed during a recap.
func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = false
