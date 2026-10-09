extends Control

@onready var coin_label = $CoinLabel
@onready var animated_sprite = $AnimatedSprite2D # ou AnimatedSprite

func _ready() -> void:
	# Conecta com a atualização de moedas vinda do EventBus
	EventBus.coins_updated.connect(update_coin_display)
	update_coin_display(GameManager.coins)

func update_coin_display(new_amount: int) -> void:
	if coin_label:
		coin_label.text = format_number(new_amount)

func format_number(value: int) -> String:
	var texts := str(value)
	var regex := RegEx.create_from_string("(\\d)(?=(\\d{3})+$)")
	return regex.sub(texts, "$1.", true)
