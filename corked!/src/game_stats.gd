extends Node

## Stats for the current run. Lives in an autoload so it survives the scene
## change from the game to the game over screen.

## Bottles delivered on days where the quota was met
var bottles_sold: int = 0
## Money earned from deliveries this run
var money_earned: int = 0
## Days where the truck left with the quota met
var days_survived: int = 0
## Bottles on the last truck and the quota it needed, for the recap
var last_day_bottles: int = 0
var last_day_quota: int = 0
## Why the run ended, shown under the "Game Over" title
var loss_reason: String = ""

## Call this whenever a brand new run starts
func reset() -> void:
	bottles_sold = 0
	money_earned = 0
	days_survived = 0
	last_day_bottles = 0
	last_day_quota = 0
	loss_reason = ""
