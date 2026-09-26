extends Node

const KEYBOARD := -1
const MAX_PLAYERS := 4

## slots the players is stored in
var slots: Array = [null, null, null, null]

## Clears player slots
func clear() -> void:
	slots = [null, null, null, null]

## Returns the open slot
func slot_of(device: int) -> int:
	return slots.find(device)

## Handles player joining
func join(device: int) -> int:
	if slot_of(device) != -1:
		return -1
	var i := slots.find(null)
	if i != -1:
		slots[i] = device
		_setup_actions(i, device)
	return i

## A player leaves the game
func leave(device: int) -> int:
	var i := slot_of(device)
	if i != -1:
		slots[i] = null
	return i

## Returns the current player count
func player_count() -> int:
	return MAX_PLAYERS - slots.count(null)

## array of all actions a player may use
const ACTIONS := ["up", "down", "left", "right", "interact", "interact2", "run"]

## Helper function for action setup
func _setup_actions(slot: int, device: int) -> void:
	for action in ACTIONS:
		var action_name := "%s_%d" % [action, slot]
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
		InputMap.add_action(action_name, InputMap.action_get_deadzone(action))
		for ev in InputMap.action_get_events(action):
			var is_kb := ev is InputEventKey or ev is InputEventMouseButton
			var is_pad := ev is InputEventJoypadButton or ev is InputEventJoypadMotion
			if device == KEYBOARD and is_kb:
				InputMap.action_add_event(action_name, ev)
			elif device != KEYBOARD and is_pad:
				var copy: InputEvent = ev.duplicate()
				copy.device = device
				InputMap.action_add_event(action_name, copy)
