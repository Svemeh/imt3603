class_name RoundTimer
extends Node

## Emitted every frame the timer is running, so the GUI can display it later.
signal time_updated(time_left: float)

## Emitted once when the round's time reaches zero.
signal round_ended

## Length of a round, in seconds (360 = 6min).
@export var round_duration: float = 360.0

var time_left: float = 0.0
var is_running: bool = false

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if not is_running:
		return

	time_left = max(time_left - delta, 0.0)
	time_updated.emit(time_left)

	if time_left <= 0.0:
		_end_round()

## Starts or restarts the round with round_duration seconds on the clock.
func start_round() -> void:
	time_left = round_duration
	is_running = true
	set_process(true)
	time_updated.emit(time_left)

## Stops the countdown without firing round_ended (e.g. pause).
func stop_round() -> void:
	is_running = false
	set_process(false)

func _end_round() -> void:
	is_running = false
	set_process(false)
	round_ended.emit()
