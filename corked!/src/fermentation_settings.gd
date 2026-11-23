extends Node

## Global fermentation values. Lives in an autoload so modifiers and upgrades
## can change them from anywhere, e.g. FermentationSettings.drain_per_second *= 0.8
## The station reads these every frame, so a change takes effect right away.

## Default values, used by reset() at the start of a new run
const DEFAULT_TANK_CAPACITY: int = 4
const DEFAULT_FILL_STEP_TIME: float = 2.0
const DEFAULT_START_PRESSURE: float = 45.0
const DEFAULT_RED_LIMIT: float = 25.0
const DEFAULT_GREEN_LIMIT: float = 70.0
const DEFAULT_DRAIN_PER_SECOND: float = 2.5
const DEFAULT_HIT_GAIN: float = 10.0
const DEFAULT_MISS_PENALTY: float = 12.0
const DEFAULT_RED_LOSS_TIME: float = 5.0
const DEFAULT_RED_MISS_LOSS: int = 1
const DEFAULT_YELLOW_SPEED: float = 0.0
const DEFAULT_NEEDLE_LAP_TIME: float = 1.5
const DEFAULT_ZONE_SIZE_DEGREES: float = 45.0
const DEFAULT_HIT_GRACE_DEGREES: float = 4.0
const DEFAULT_PRESS_COOLDOWN: float = 0.3
const DEFAULT_IDLE_LAP_LOSS: float = 0.15

## Max juice units the tank can hold at once (= max wine potential)
var tank_capacity: int = DEFAULT_TANK_CAPACITY
## Seconds for each unit of wine to flow into the barrel in the green zone
var fill_step_time: float = DEFAULT_FILL_STEP_TIME
## Pressure when the tank gets filled. 0 = bottom of red, 100 = top of green
var start_pressure: float = DEFAULT_START_PRESSURE
## Pressure below this is red
var red_limit: float = DEFAULT_RED_LIMIT
## Pressure at or above this is green, between red_limit and this is yellow
var green_limit: float = DEFAULT_GREEN_LIMIT
## Pressure lost every second, also when nobody is at the station
var drain_per_second: float = DEFAULT_DRAIN_PER_SECOND
## Pressure gained on a good press
var hit_gain: float = DEFAULT_HIT_GAIN
## Pressure lost on a bad press
var miss_penalty: float = DEFAULT_MISS_PENALTY
## Seconds in red before one unit of wine potential is lost
var red_loss_time: float = DEFAULT_RED_LOSS_TIME
## Juice units lost on a bad press while the pressure is already in red
var red_miss_loss: int = DEFAULT_RED_MISS_LOSS
## Production speed in yellow. 0.0 = no wine until the pressure is green.
## A modifier can raise this (e.g. 0.5 = half speed in yellow)
var yellow_speed: float = DEFAULT_YELLOW_SPEED
## Seconds for the needle to go one full circle
var needle_lap_time: float = DEFAULT_NEEDLE_LAP_TIME
## Size of the target zone in degrees
var zone_size_degrees: float = DEFAULT_ZONE_SIZE_DEGREES
## Extra forgiveness on each side of the zone in degrees
var hit_grace_degrees: float = DEFAULT_HIT_GRACE_DEGREES
## Seconds after a press before the next press counts (stops button mashing)
var press_cooldown: float = DEFAULT_PRESS_COOLDOWN
## Barrel progress lost (0 -> 1 of one unit) when the needle does a full lap
## without a press. Kept small since players are allowed to step away
var idle_lap_loss: float = DEFAULT_IDLE_LAP_LOSS

## Call this whenever a brand new run starts
func reset() -> void:
	tank_capacity = DEFAULT_TANK_CAPACITY
	fill_step_time = DEFAULT_FILL_STEP_TIME
	start_pressure = DEFAULT_START_PRESSURE
	red_limit = DEFAULT_RED_LIMIT
	green_limit = DEFAULT_GREEN_LIMIT
	drain_per_second = DEFAULT_DRAIN_PER_SECOND
	hit_gain = DEFAULT_HIT_GAIN
	miss_penalty = DEFAULT_MISS_PENALTY
	red_loss_time = DEFAULT_RED_LOSS_TIME
	red_miss_loss = DEFAULT_RED_MISS_LOSS
	yellow_speed = DEFAULT_YELLOW_SPEED
	needle_lap_time = DEFAULT_NEEDLE_LAP_TIME
	zone_size_degrees = DEFAULT_ZONE_SIZE_DEGREES
	hit_grace_degrees = DEFAULT_HIT_GRACE_DEGREES
	press_cooldown = DEFAULT_PRESS_COOLDOWN
	idle_lap_loss = DEFAULT_IDLE_LAP_LOSS
