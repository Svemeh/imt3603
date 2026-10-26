extends Node

@onready var hud = $Hud
@onready var round_timer: RoundTimer = $RoundTimer

const PLAYER_SCENE := preload("res://scenes/player.tscn")

const PLAYER_VARIANTS := [
	Player.PlayerVariant.YELLOW,
	Player.PlayerVariant.PURPLE,
	Player.PlayerVariant.GREEN,
	Player.PlayerVariant.BLUE
]

var money: int = 0
var quota: int = 0


func _ready() -> void:
	hud.update_money(money)
	hud.update_quota(quota)

	round_timer.time_updated.connect(_on_round_timer_time_updated)
	round_timer.round_ended.connect(_on_round_timer_round_ended)

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

		p.global_position = $SpawnPoints.get_child(i).global_position


## Increment money up or down by x and refreshes the HUD.
func increment_money(amount: int) -> void:
	money += amount
	hud.update_money(money)


## Increments quota by x (e.g. from a valid delivery) and refreshes the HUD.
func increment_quota(amount: int) -> void:
	quota += amount
	hud.update_quota(quota)


## Forwards the timer's remaining time to the HUD's progress bar.
func _on_round_timer_time_updated(time_left: float) -> void:
	hud.update_timer(time_left, round_timer.round_duration)


## Called when a round's timer hits zero. Ends the game.
func _on_round_timer_round_ended() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")
