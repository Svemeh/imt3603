extends Control

@onready var money_label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var quota_label = $MarginContainer/VBoxContainer/QuotaLabel
@onready var timer_bar: ProgressBar = $TimerBar

# Ha to funksjoner - update_money(), update_quota(int: money). Disse har et 
# tall: starter på null ( 0 ) og oppdateres etter en quota er oppfylt eller en 
# oppgradering / fiks er kjøpt/betalt for. 

## Updates money icon to amount. It takes the "amount" as an int and updates
## money label.
func update_money(amount: int) -> void:
	money_label.text = "Money: " + str(amount)

## Shows bottles loaded in the truck against the days quota, f.eks "Quota: 4/8"
func update_quota(loaded: int, target: int) -> void:
	quota_label.text = "Quota %d/%d" % [loaded, target]

## Updates the round timer progress bar. time_left and round_duration are both
## in seconds; the bar fills from empty to full as time elapses.
func update_timer(time_left: float, round_duration: float) -> void:
	timer_bar.max_value = round_duration
	timer_bar.value = round_duration - time_left
