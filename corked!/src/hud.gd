extends Control

@onready var money_label = $MarginContainer/MoneyLabel

# Ha to funksjoner - update_money(), update_quota(int: money). Disse har et 
# tall: starter på null ( 0 ) og oppdateres etter en quota er oppfylt eller en 
# oppgradering / fiks er kjøpt/betalt for. 

## Updates money icon to X (money)
func update_money(x: int) -> void:
	money_label.text = "Money: " + str(x)

## Updates the  quota based on requirements
func update_quota(money: int):
	pass
