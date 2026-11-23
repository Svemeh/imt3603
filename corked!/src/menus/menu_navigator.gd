class_name MenuNavigator
extends Node

@export var first_focus: Control

const DIRECTIONS := {
	"left": SIDE_LEFT,
	"right": SIDE_RIGHT,
	"up": SIDE_TOP,
	"down": SIDE_BOTTOM,
}
const SLIDER_STEPS := 20.0
const FOCUS_SCALE := 1.08
const FOCUS_TINT := Color(1.3, 1.3, 1.15)

var _highlighted: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	var no_outline := StyleBoxEmpty.new()
	for button in get_parent().find_children("*", "BaseButton", true, false):
		button.add_theme_stylebox_override("focus", no_outline)
	if first_focus:
		first_focus.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	for action in DIRECTIONS:
		if event.is_action("ui_" + action):
			get_viewport().set_input_as_handled()
			return


func _process(_delta: float) -> void:
	for action in DIRECTIONS:
		if Input.is_action_just_pressed(action) or Input.is_action_just_pressed("ui_" + action):
			_move(action)
			return


func _move(action: String) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		if first_focus:
			first_focus.grab_focus()
		return

	var slider := focused as Range
	if slider and (action == "left" or action == "right"):
		var step := (slider.max_value - slider.min_value) / SLIDER_STEPS
		slider.value += step if action == "right" else -step
		return

	var next := focused.find_valid_focus_neighbor(DIRECTIONS[action])
	if next:
		next.grab_focus()


func _on_focus_changed(control: Control) -> void:
	if is_instance_valid(_highlighted):
		_highlighted.scale = Vector2.ONE
		_highlighted.modulate = Color.WHITE
	_highlighted = null
	if control is BaseButton:
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2.ONE * FOCUS_SCALE
		control.modulate = FOCUS_TINT
		_highlighted = control


func _exit_tree() -> void:
	if is_instance_valid(_highlighted):
		_highlighted.scale = Vector2.ONE
		_highlighted.modulate = Color.WHITE
