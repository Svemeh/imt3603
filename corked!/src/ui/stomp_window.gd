# stomp_window.gd
extends Control

## Stomping station popup. MASH shows the progress on the current grape, Juice
## shows how full the barrel is, and the feet light up in turn on every stomp

const FOOT_IDLE := Color(0.25, 0.15, 0.35)
const FOOT_ACTIVE := Color(0.7, 0.35, 0.9)

@onready var _left_foot: Panel = %LeftFoot
@onready var _right_foot: Panel = %RightFoot
@onready var _mash_bar: ProgressBar = %MashBar
@onready var _juice_bar: ProgressBar = %JuiceBar

## Own copies of the foot styles so recolouring doesn't affect other windows
var _left_style: StyleBoxFlat
var _right_style: StyleBoxFlat
## Whch foor lights up for the next stomp
var _left_next: bool = true

func _ready() -> void:
	_left_style = _own_style(_left_foot)
	_right_style = _own_style(_right_foot)
	set_mash(0.0)
	set_juice(0.0)
	_light_foot(false, false)

## Progress on the current grape, 0.0 -> 1.0
func set_mash(ratio: float) -> void:
	_mash_bar.value = clampf(ratio, 0.0, 1.0)

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

func _own_style(panel: Panel) -> StyleBoxFlat:
	var style := (panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	panel.add_theme_stylebox_override("panel", style)
	return style
