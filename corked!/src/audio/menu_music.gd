# menu_music.gd
extends AudioStreamPlayer
## Menu and lobby music. This is an autoload, so it survives scene changes
## and keeps playing from the main menu into the lobby without restarting.

## Starts the music, unless it's already playing (then it just continues)
func play_menu_music() -> void:
	if not playing:
		play()

## Stops the music, e.g. when the game itself starts
func stop_menu_music() -> void:
	stop()
