## Runs in the editor too, so Inspector size changes update the visual preview.
@tool
extends Node3D
## Visual mounting only. No input, visibility rules, or minigame logic.
## Parent this scene to a station. Move this node to adjust the local offset.
## Select a station-specific UI scene here. Its root must be a Control node.
## Create an inherited scene from station_window.tscn to keep the shared frame.
## Clearing this field restores the generic template. Swapping scenes replaces
## the displayed UI, so do this during setup rather than during a minigame.
@export var window_scene: PackedScene = preload("res://scenes/ui/station_window.tscn"):
 set(value):
  window_scene = value
  if is_node_ready():
   _replace_window()

## The currently displayed UI. Developers can use this to connect their station
## signals to their custom window once the mount is ready.
var window: Control

## Width and height of the 2D panel in pixels. Stomping and fermentation use
## 420 x 280; the compact bottling window can use 260 x 180.
@export var panel_size: Vector2i = Vector2i(420, 280):
 set(value):
  # Keep enough room for the title, padding and placeholder content.
  panel_size = Vector2i(maxi(value.x, 260), maxi(value.y, 180))
  _update_design()
## Size of one texture pixel in the 3D world. Lower values make the whole
## window smaller without changing the panel layout or font sizes.
@export_range(0.001, 0.05, 0.001) var pixel_size: float = 0.016:
 set(value):
  pixel_size = value
  _update_design()

## Applies the saved Inspector values once the viewport and visual exist.
func _ready() -> void:
 window = $Viewport/StationWindow
 _replace_window()

## Keeps the 2D panel, its render texture and the camera-facing sprite in sync.
## Moving this Node3D changes the offset; parenting it to a station makes it
## follow that station. This script only handles appearance, not interaction.
func _update_design() -> void:
 # Export setters can run before child nodes are ready when a scene loads.
 if not is_node_ready() or not is_instance_valid(window):
  return
 # Leave 16 transparent pixels on each side so the border/shadow fit.
 $Viewport.size = panel_size + Vector2i(32, 32)
 window.position = Vector2(16, 16)
 window.size = Vector2(panel_size)
 # The Sprite3D displays this viewport texture and faces the camera.
 $PanelVisual.pixel_size = pixel_size


## Replaces only the viewport content; the station attachment and display size
## stay the same. Validate first so a wrong scene leaves the current UI intact.
func _replace_window() -> void:
 var scene := window_scene
 if scene == null:
  scene = preload("res://scenes/ui/station_window.tscn")
 if not scene.can_instantiate():
  push_warning("Window Scene must be an instantiable scene.")
  return
 var replacement := scene.instantiate()
 if not replacement is Control:
  replacement.free()
  push_warning("Window Scene must have a Control root, such as station_window.tscn.")
  return
 if is_instance_valid(window):
  window.get_parent().remove_child(window)
  window.queue_free()
 replacement.name = "StationWindow"
 $Viewport.add_child(replacement)
 window = replacement as Control
 _update_design()
