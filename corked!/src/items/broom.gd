# broom.gd
class_name Broom
extends Item

## Cleans wine spills. Hold it and press interact near a spill to sweep it.

## How far past a spill's edge the broom can still reach
@export var reach: float = 1.0

var _sweep_tween: Tween


func _ready() -> void:
	display_name = "Broom"


## Dropping a broom does not spill anything
func get_crash_spill_radius() -> float:
	return 0.0


## Sweeps the closest spill near the player once. Returns true if it hit one
func sweep(player: Player) -> bool:
	var best: Spill = null
	var best_dist := INF

	for node in get_tree().get_nodes_in_group("spills"):
		var spill := node as Spill
		if spill == null or not spill.can_sweep():
			continue

		var offset := spill.global_position - player.global_position
		offset.y = 0.0
		var d := offset.length()

		if d <= spill.radius + reach and d < best_dist:
			best_dist = d
			best = spill

	_play_sweep_animation()

	if best:
		best.sweep()
		return true
	return false


## Little side to side wiggle in the hand
func _play_sweep_animation() -> void:
	if _sweep_tween:
		_sweep_tween.kill()
	_sweep_tween = create_tween()
	_sweep_tween.tween_property(self, "rotation:z", 0.5, 0.08)
	_sweep_tween.tween_property(self, "rotation:z", -0.5, 0.12)
	_sweep_tween.tween_property(self, "rotation:z", 0.0, 0.08)
