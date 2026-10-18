extends Node

@onready var hud = $Hud
@onready var round_timer: RoundTimer = $RoundTimer
@onready var delivery_zone = $DeliveryPoint/DeliveryZone
@onready var deliveryman = $DeliveryPoint/Deliveryman

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var money: int = 0

## Bottles the truck must carry when iit's sent for the day to succeed. GDD
## section 1.3 says 6-10 per round, creates hold 4 bottles, so 8 = 2 crates. This
## is temp, because we need to figure out how the new round system will work
@export var quota_target: int = 8
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
	hud.update_money(money)
	hud.update_quota(loaded_bottles, quota_target)
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
		add_child(p)
		var spawns := $Map/PlayerSpawns.get_children()
		if i < spawns.size():
			p.global_position = (spawns[i] as Node3D).global_position

## Increments money up or down by x and refreshes the HUD.
func increment_money(amount: int) -> void:
	money += amount
	hud.update_money(money)

## A crate was loaded into the truck, refreshes the quota on the HUD
func _on_delivery_zone_contents_changed(bottles: int) -> void:
	loaded_bottles = bottles
	hud.update_quota(loaded_bottles, quota_target)

## A player sent the truck. Quota met = yey you won my boy!
## not met/short = day lost you suck my boy!
func _on_delivery_sent(bottles: int) -> void:
	if _day_over:
		return
	_day_over = true
	round_timer.stop_round()
	
	await deliveryman.drive_off_finished
	var won := bottles >= quota_target
	if won:
		increment_money(bottles * money_per_bottle)
		print("Day won! %d/%d bottles" % [bottles, quota_target])
		# TODO: on a win, go to the upgrade phase
	else:
		print("Day lost, truck sent with %d/%d bottles" % [bottles, quota_target])
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
	get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")
