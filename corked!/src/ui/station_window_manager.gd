extends Node
## Manages popup visibility for each station after a player interacts with it.
## Windows hide when players leave, unless the bottling machine is still running.
## Input and gameplay actions are handled by the player and station scripts.

## Enables or disables all station popups without affecting gameplay.
@export var enabled: bool = true
## Paths from this node to the mounted windows, assigned in game.tscn.
@export var window_paths: Array[NodePath] = []
## Maps each Interactable station to its own mounted window.
var _windows: Dictionary = {}
## Tracks the last supported station used by each player. Separate entries
## let several players keep different windows open at the same time.
var _active_by_player: Dictionary = {}

## Starts with every window hidden, finds its owning station and connects
## both players already in the scene and players spawned afterwards.
func _ready() -> void:
 for path in window_paths:
  var window := get_node_or_null(path) as Node3D
  if not window:
   continue
  window.hide()
  var station := window.get_parent()
  # Bottling has a RepairPopupAnchor between the window and the station.
  # Walk up the parents so both direct mounts and anchored mounts work.
  while station != null and not station is Interactable:
   station = station.get_parent()
  if station:
   _windows[station] = window
 # Game creates players dynamically, so listen for future children too.
 get_parent().child_entered_tree.connect(_register_player)
 for child in get_parent().get_children():
  _register_player(child)

## Connects each player once. Binding the player tells the callback who used
## the station, since the signal itself only carries the station.
func _register_player(node: Node) -> void:
 if node is Player and not node.station_interacted.is_connected(_on_station_interacted.bind(node)):
  node.station_interacted.connect(_on_station_interacted.bind(node))

## Records the station after Player has performed its normal interaction.
## Using another supported station replaces this player's previous window;
## using something without a window clears their previous selection.
func _on_station_interacted(station: Interactable, player: Player) -> void:
 if enabled and _windows.has(station):
  _active_by_player[player] = station
 else:
  _active_by_player.erase(player)
 _refresh_windows()

## Removes player selections when they leave interaction range, disappear,
## or the display is disabled. Machine-driven visibility is checked separately.
func _process(_delta: float) -> void:
 # Iterate over a copy of the keys so entries can be removed safely.
 for player in _active_by_player.keys():
  var station = _active_by_player[player]
  if not enabled or not is_instance_valid(player) or not is_instance_valid(station):
   _active_by_player.erase(player)
   continue
  # Use the same detection area as normal station interaction.
  var area := player.get_node("InteractArea") as Area3D
  if not area.get_overlapping_bodies().has(station):
   _active_by_player.erase(player)
 _refresh_windows()

## Shows a window while at least one nearby player has interacted with it.
## Bottling shows only while broken, so players can leave for the hammer. Fermentation is visible exactly while its tank has juice, so
## the pressure can be watched from afar and the game resumed on return.
func _refresh_windows() -> void:
 for station in _windows:
  if is_instance_valid(_windows[station]):
   var show_window: bool
   if station is FermentationStation:
    show_window = station.is_running()
   elif station is BottlingStation:
    # The bottling window is only the repair popup, so it shows only while
    # the machine is broken, never while it bottles normally.
    show_window = station.is_running()
   else:
    show_window = _active_by_player.values().has(station)
   _windows[station].visible = enabled and show_window
