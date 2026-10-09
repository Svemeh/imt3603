extends Camera3D

@export var framed_width: float = 46.0
@export var framed_height: float = 32.0

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_frame)
	_fit_frame()

func _fit_frame() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	# Preserve the whole vineyard and delivery apron when the window narrows.
	var aspect := viewport_size.x / viewport_size.y
	size = maxf(framed_height, framed_width / aspect)
