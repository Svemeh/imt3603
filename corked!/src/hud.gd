extends Control

@onready var money_label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var quota_label = $MarginContainer/VBoxContainer/QuotaLabel

# Ha to funksjoner - update_money(), update_quota(int: money). Disse har et 
# tall: starter på null ( 0 ) og oppdateres etter en quota er oppfylt eller en 
# oppgradering / fiks er kjøpt/betalt for. 

## Updates money icon to amount. It takes the "amount" as an int and updates
## money label.
func update_money(amount: int) -> void:
	money_label.text = "Money: " + str(amount)

## Updates the  quota based on requirements. It takes "amount" as an int, while
## updating the quota label.
func update_quota(amount: int):
	quota_label.text = "Quota " + str(amount)
