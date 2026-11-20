extends Node

const ALL: Array[Dictionary] = [
	{
		"id": &"extra_barrel",
		"title": "Extra Barrel",
		"buff": "One more barrel in the stack",
		"debuff": "The door opens 3 seconds after someone steps on the plate",
		"cost": 40,
	},
	{
		"id": &"green_thumb",
		"title": "Green Thumb",
		"buff": "Grapes grow back 2 seconds faster",
		"debuff": "Each grape takes 3 more stomps",
		"cost": 30,
	},
	{
		"id": &"sturdy_machine",
		"title": "Sturdy Machine",
		"buff": "The bottling machine breaks half as often",
		"debuff": "Fermentation pressure drops 30% faster",
		"cost": 50,
	},
	{
		"id": &"early_driver",
		"title": "Early Driver",
		"buff": "The truck opens 10% earlier in the day",
		"debuff": "Fixing the bottling machine takes 2 more hammer hits",
		"cost": 40,
	},
	{
		"id": &"overtime",
		"title": "Overtime",
		"buff": "Each day is 30 seconds longer",
		"debuff": "Tomorrow's quota is 3 bottles higher",
		"cost": 30,
	},
	{
		"id": &"running_shoes",
		"title": "Running Shoes",
		"buff": "Everyone runs 15% faster",
		"debuff": "Getting knocked over lasts twice as long",
		"cost": 40,
	},
	{
		"id": &"reinforced_bottles",
		"title": "Reinforced Bottles",
		"buff": "Dropped crates no longer break",
		"debuff": "Each bottle sells for $3 less",
		"cost": 40,
	},
	{
		"id": &"good_vintage",
		"title": "Good Vintage",
		"buff": "Each bottle sells for $5 more",
		"debuff": "Grapes grow back 2 seconds slower",
		"cost": 30,
	},
]

const MIN_VINE_REGROW_TIME: float = 1.0

var extra_barrels: int = 0
var door_open_delay: float = 0.0
var vine_regrow_change: float = 0.0
var extra_stomps: int = 0
var break_chance_multiplier: float = 1.0
var extra_repair_hits: int = 0
var delivery_opens_change: float = 0.0
var extra_round_time: float = 0.0
var extra_money_per_bottle: int = 0
var pending_quota: int = 0
var run_speed_multiplier: float = 1.0
var stun_time_multiplier: float = 1.0
var unbreakable_crates: bool = false

func reset() -> void:
	extra_barrels = 0
	door_open_delay = 0.0
	vine_regrow_change = 0.0
	extra_stomps = 0
	break_chance_multiplier = 1.0
	extra_repair_hits = 0
	delivery_opens_change = 0.0
	extra_round_time = 0.0
	extra_money_per_bottle = 0
	pending_quota = 0
	run_speed_multiplier = 1.0
	stun_time_multiplier = 1.0
	unbreakable_crates = false

func roll_choices(count: int = 3) -> Array[Dictionary]:
	var pool := ALL.duplicate()
	pool.shuffle()
	return pool.slice(0, count)

func apply(modifier: Dictionary, remove_debuff: bool) -> void:
	_apply_buff(modifier.id)
	if not remove_debuff:
		_apply_debuff(modifier.id)

func take_pending_quota() -> int:
	var amount := pending_quota
	pending_quota = 0
	return amount

func vine_regrow_time(base: float) -> float:
	return maxf(base + vine_regrow_change, MIN_VINE_REGROW_TIME)

func delivery_opens_at(base: float) -> float:
	return clampf(base + delivery_opens_change, 0.0, 1.0)

func _apply_buff(id: StringName) -> void:
	match id:
		&"extra_barrel":
			extra_barrels += 1
		&"green_thumb":
			vine_regrow_change -= 2.0
		&"sturdy_machine":
			break_chance_multiplier *= 0.5
		&"early_driver":
			delivery_opens_change -= 0.1
		&"overtime":
			extra_round_time += 30.0
		&"good_vintage":
			extra_money_per_bottle += 5
		&"running_shoes":
			run_speed_multiplier *= 1.15
		&"reinforced_bottles":
			unbreakable_crates = true

func _apply_debuff(id: StringName) -> void:
	match id:
		&"extra_barrel":
			door_open_delay += 3.0
		&"green_thumb":
			extra_stomps += 3
		&"sturdy_machine":
			FermentationSettings.drain_per_second *= 1.3
		&"early_driver":
			extra_repair_hits += 2
		&"overtime":
			pending_quota += 3
		&"good_vintage":
			vine_regrow_change += 2.0
		&"running_shoes":
			stun_time_multiplier *= 2.0
		&"reinforced_bottles":
			extra_money_per_bottle -= 3
