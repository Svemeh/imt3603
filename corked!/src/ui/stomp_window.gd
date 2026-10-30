# stomp_window.gd
extends Control

## Stomping station popup. MASH shows the progress on the current grape, Juice
## shows how full the barrel is, and the feet light up in turn on every stomp

const FOOT_IDLE := Color(0.25, 0.15, 0.35)
const FOOT_ACTIVE := Color(0.7, 0.35, 0.9)
## MASH bar colours, same idea as the fermentation gauge
const MASH_LOW := Color(0.85, 0.2, 0.2)
const MASH_MID := Color(0.95, 0.8, 0.2)
const MASH_HIGH := Color(0.3, 0.8, 0.35)

@onready var _left_foot: Panel = %LeftFoot
@onready var _right_foot: Panel = %RightFoot
@onready var _mash_bar: ProgressBar = %MashBar
@onready var _juice_bar: ProgressBar = %JuiceBar

## Own copies of the foot styles so recolouring doesn't affect other windows
var _left_style: StyleBoxFlat
var _right_style: StyleBoxFlat
## Whch foor lights up for the next stomp
var _left_next: bool = true
## Bars own style
var _mash_style: StyleBoxFlat

func _ready() -> void:
	_mash_style = _own_fill_style(_mash_bar)
	_left_style = _own_style(_left_foot)
	_right_style = _own_style(_right_foot)
	finish_grape()
	set_juice(0.0)
	_light_foot(false, false)

## Progress on the current grape, 0.0 -> 1.0
func set_mash(ratio: float) -> void:
	_mash_bar.value = clampf(ratio, 0.0, 1.0)
	_update_mash_color()

## A grape is done, empty both bars at once, it wasnt lost
func finish_grape() -> void:
	_mash_bar.value = 0.0
	_update_mash_color()

## How full the barrel is, 0.0 -> 1.0
func set_juice(ratio: float) -> void:
	_juice_bar.value = clampf(ratio, 0.0, 1.0)

## Called on every stomp, alternates left and right
func stomp() -> void:
	_light_foot(_left_next, not _left_next)
	_left_next = not _left_next

func _light_foot(left_on: bool, right_on: bool) -> void:
	_left_style.bg_color = FOOT_ACTIVE if left_on else FOOT_IDLE
	_right_style.bg_color = FOOT_ACTIVE if right_on else FOOT_IDLE

## Red when empty, yellow halfway, green when nearly done
func _update_mash_color() -> void:
	var r := _mash_bar.value
	if r < 0.5:
		_mash_style.bg_color = MASH_LOW.lerp(MASH_MID, r * 2.0)
	else:
		_mash_style.bg_color = MASH_MID.lerp(MASH_HIGH, (r - 0.5) * 2.0)

## Private copy of the bar's fill style, so recolouring only affects this bar
func _own_fill_style(bar: ProgressBar) -> StyleBoxFlat:
	var style := (bar.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	bar.add_theme_stylebox_override("fill", style)
	return style

func _own_style(panel: Panel) -> StyleBoxFlat:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	panel.add_theme_stylebox_override("panel", style)
	return style
