extends Control

## Repair popup for the bottling station. The ball goes from red to
## green as players hit the broken machine with the hammer

const BROKEN_COLOR := Color(0.85, 0.2, 0.2)
const FIXED_COLOR := Color(0.25, 0.8, 0.35)

@onready var _ball: Panel = %Ball
@onready var _status: Label = %StatusLabel

## Own copy of the balls style, so changing its color only affects this window
var _ball_style: StyleBoxFlat

## duplicate gives each window its own copy of the ball style. Otherwise changing
## the color could change it everywhere the same style is used
func _ready() -> void:
	print("repair window loaded from: ", scene_file_path)
	print_tree_pretty()
	_ball_style = (_ball.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	_ball.add_theme_stylebox_override("panel", _ball_style)
	set_progress(1.0)

## 0.0 = just broke (red), 1.0 = fixed (green)
## lerp blends between the two colors
func set_progress(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	_ball_style.bg_color = BROKEN_COLOR.lerp(FIXED_COLOR, ratio)
	_status.text = "Running" if ratio >= 1.0 else "Hit it with the hammer!"
