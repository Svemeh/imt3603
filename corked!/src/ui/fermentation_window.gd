# fermentation_window.gd
extends Control

## Pressure minigame popup for the fermentation station.
## Only draws. All timing lives in FermentationStation, so the needle you see
## is the exact value the hit check uses.
## The panel is small in pixels but shown with a large pixel_size on the
## mount, so the text stays big and sharp on screen. Keep fonts 14px or more.

const RED := Color(0.85, 0.2, 0.2)
const YELLOW := Color(0.95, 0.72, 0.2)
const GREEN := Color(0.25, 0.8, 0.35)
const WINE := Color(0.6, 0.06, 0.14)
const TRACK := Color(0.2, 0.22, 0.27)
const EDGE := Color(0.33, 0.36, 0.43)
const BG := Color(0.095, 0.105, 0.135)
const TEXT := Color(0.95, 0.96, 0.98)
const DIM := Color(0.62, 0.65, 0.72)

## Seconds the ring flashes after a press
const FLASH_TIME := 0.25
## Seconds the red ring shows on a lost wine pip
const LOSS_FLASH_TIME := 0.6
## Padding inside the content area, smaller than the shared template so the
## gauge gets as much room as possible
const BODY_MARGIN := 8.0

var station: FermentationStation = null

var _gauge: Control
var _font: Font
var _flash: float = 0.0
var _flash_color: Color = GREEN
var _loss_flash: float = 0.0


func _ready() -> void:
	$Frame/Layout/Header/Title.text = "FERMENTATION"
	$Frame/Layout/ContentSlot/Placeholder.hide()

	# Own copy of the body style with less padding, only affects this window
	var slot: PanelContainer = $Frame/Layout/ContentSlot
	var body := slot.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if body:
		body.set_content_margin_all(BODY_MARGIN)
		slot.add_theme_stylebox_override("panel", body)

	# One control that draws everything, cheaper than many nodes
	_gauge = Control.new()
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gauge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gauge.draw.connect(_draw_gauge)
	slot.add_child(_gauge)
	_font = _gauge.get_theme_font("font", "Label")


## Called by the station in its _ready
func set_station(s: FermentationStation) -> void:
	station = s
	station.check_result.connect(_on_check_result)
	station.potential_lost.connect(_on_potential_lost)
	station.progress_lost.connect(_on_progress_lost)


func _on_check_result(success: bool) -> void:
	_flash = FLASH_TIME
	_flash_color = GREEN if success else RED


func _on_potential_lost() -> void:
	_loss_flash = LOSS_FLASH_TIME


## Lap without a press: same red ring flash as a missed press
func _on_progress_lost() -> void:
	_flash = FLASH_TIME
	_flash_color = RED


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_loss_flash = maxf(_loss_flash - delta, 0.0)
	if station and station.is_running():
		_gauge.queue_redraw()


## Needle angle 0 = top, Godot's draw angle 0 = right
func _screen_angle(a: float) -> float:
	return a - PI * 0.5


func _ring_radius(s: Vector2) -> float:
	return minf(s.y * 0.5 - 8.0, s.x * 0.24)


func _text(t: String, pos: Vector2, font_size: int, col: Color) -> void:
	_gauge.draw_string(_font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


## Draws text right aligned so it ends at x + w
func _text_right(t: String, x: float, w: float, y: float, font_size: int, col: Color) -> void:
	_gauge.draw_string(_font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_RIGHT, w, font_size, col)


func _draw_gauge() -> void:
	if station == null:
		return
	var s := _gauge.size
	_draw_skill_ring(s)
	_draw_side_panel(s)


## Skill check ring on the left side
func _draw_skill_ring(s: Vector2) -> void:
	var r := _ring_radius(s)
	var c := Vector2(r + 7.0, s.y * 0.5)
	var t := _flash / FLASH_TIME

	# Track, flashes green on hit and red on miss
	_gauge.draw_arc(c, r, 0.0, TAU, 72, TRACK.lerp(_flash_color, t * 0.8), 11.0, true)

	# Target zone
	var a0 := _screen_angle(station.zone_start)
	var a1 := _screen_angle(station.zone_start + station.zone_size())
	_gauge.draw_arc(c, r, a0, a1, 16, GREEN, 15.0, true)

	# Needle
	var dir := Vector2.from_angle(_screen_angle(station.needle_angle))
	_gauge.draw_line(c - dir * 8.0, c + dir * (r + 7.0), TEXT, 4.0, true)
	_gauge.draw_circle(c, 6.0, TEXT)
	_gauge.draw_circle(c, 3.0, TRACK)


## Pressure bar, status, wine left and barrel progress on the right side
func _draw_side_panel(s: Vector2) -> void:
	var x := _ring_radius(s) * 2.0 + 22.0
	var w := s.x - x

	# Pressure bar, the colours explain themselves so no label
	_draw_pressure_bar(Rect2(x, 4, w, 22))

	# Status line
	var zone := station.get_zone()
	var status := "FILLING"
	var col := GREEN
	if zone == FermentationStation.Zone.YELLOW:
		status = "PAUSED"
		col = YELLOW
	elif zone == FermentationStation.Zone.RED:
		status = "LOSING %ds" % ceili(station.time_until_loss())
		col = RED
		col = RED.lerp(TEXT, 0.35 + 0.35 * sin(Time.get_ticks_msec() * 0.012))
	_text(status, Vector2(x, 50), 20, col)

	# Wine potential: pips plus a counter
	var left := station.get_tank_amount()
	var capacity := FermentationSettings.tank_capacity
	_text("WINE", Vector2(x, 72), 15, DIM)
	_text_right("%d/%d" % [left, capacity], x, w, 72, 17, TEXT if left > 0 else RED)
	var pip_r := 9.0
	var step := 23.0
	if capacity > 1:
		step = minf(step, (w - pip_r * 2.0) / (capacity - 1))
	for i in capacity:
		var p := Vector2(x + pip_r + i * step, 87.0)
		if i < left:
			_gauge.draw_circle(p, pip_r, WINE)
			_gauge.draw_circle(p, pip_r, WINE.lightened(0.45), false, 2.0, true)
		else:
			_gauge.draw_circle(p, pip_r, EDGE, false, 2.0, true)
	# Red ring on the pip that was just lost
	if _loss_flash > 0.0 and left < capacity:
		var lost := Vector2(x + pip_r + left * step, 87.0)
		var red := RED
		red.a = _loss_flash / LOSS_FLASH_TIME
		_gauge.draw_circle(lost, pip_r + 3.0, red, false, 3.0, true)

	# Barrel progress
	if station.is_filling():
		var b := station.barrel
		var speed := station.production_speed()
		_text("BARREL", Vector2(x, 116), 15, DIM)
		_text_right("%d/%d" % [b.juice_amount, b.MAX_CAPACITY], x, w, 116, 17, TEXT)
		var bar := Rect2(x, 121, w, 10)
		_gauge.draw_rect(bar, TRACK)
		# Whole units already in the barrel plus the one that is flowing now
		var ratio := (b.juice_amount + station.fill_progress) / float(b.MAX_CAPACITY)
		var fill_col := GREEN if speed > 0.0 else YELLOW
		_gauge.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), fill_col)
		_gauge.draw_rect(bar, EDGE, false, 1.5)


## Red, yellow and green zones, lit up to the current pressure
func _draw_pressure_bar(bar: Rect2) -> void:
	var red_x := bar.size.x * FermentationSettings.red_limit / 100.0
	var green_x := bar.size.x * FermentationSettings.green_limit / 100.0
	var fill := bar.size.x * station.pressure / 100.0
	var segments := [[0.0, red_x, RED], [red_x, green_x, YELLOW], [green_x, bar.size.x, GREEN]]

	for seg in segments:
		var from: float = seg[0]
		var to: float = seg[1]
		var c: Color = seg[2]
		# Dim background for the whole zone
		_gauge.draw_rect(Rect2(bar.position.x + from, bar.position.y, to - from, bar.size.y), c.darkened(0.7))
		# Bright part up to the current pressure
		var lit := minf(to, fill) - from
		if lit > 0.0:
			_gauge.draw_rect(Rect2(bar.position.x + from, bar.position.y, lit, bar.size.y), c)

	# Zone dividers and outline
	for dx in [red_x, green_x]:
		_gauge.draw_line(Vector2(bar.position.x + dx, bar.position.y), Vector2(bar.position.x + dx, bar.end.y), BG, 2.0)
	_gauge.draw_rect(bar, EDGE, false, 2.0)

	# Marker at the current pressure
	var mx := bar.position.x + fill
	_gauge.draw_line(Vector2(mx, bar.position.y - 4.0), Vector2(mx, bar.end.y + 4.0), TEXT, 3.0)
