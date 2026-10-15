extends Control

@onready var coin_label = $CoinLabel
@onready var animated_sprite = $AnimatedSprite2D

var previous_coins: int = 0
var color_tween: Tween
var original_font_color: Color

func _ready() -> void:
	previous_coins = GameManager.coins
	
	# Salva a cor original do label logo no início da cena
	if coin_label:
		if coin_label.has_theme_color_override("font_color"):
			original_font_color = coin_label.get_theme_color("font_color")
		else:
			original_font_color = Color(1, 1, 1) # Fallback para branco caso não tenha override
			
	EventBus.coins_updated.connect(update_coin_display)
	update_coin_display(GameManager.coins)

func update_coin_display(new_amount: int) -> void:
	if coin_label:
		coin_label.text = format_number(new_amount)
		
		# Compara se houve aumento ou diminuição para aplicar a cor correspondente
		if new_amount > previous_coins:
			flash_label_color(Color(0, 0, 1)) # Azul (R 0, G 0, B 255)
		elif new_amount < previous_coins:
			flash_label_color(Color(1, 0, 0)) # Vermelho (R 255, G 0, B 0)
			
		previous_coins = new_amount

func flash_label_color(target_color: Color) -> void:
	if not coin_label:
		return
		
	# Cancela um tween anterior se houver para evitar conflitos de cores
	if color_tween and color_tween.is_valid():
		color_tween.kill()
		
	coin_label.add_theme_color_override("font_color", target_color)
	
	color_tween = create_tween()
	# Fica na cor de alerta por 0.3 segundos e transiciona de volta para a original salva em 0.7 segundos
	color_tween.tween_interval(0.3)
	color_tween.tween_property(coin_label, "theme_override_colors/font_color", original_font_color, 0.7)

func format_number(value: int) -> String:
	var texts := str(value)
	var regex := RegEx.create_from_string("(\\d)(?=(\\d{3})+$)")
	return regex.sub(texts, "$1.", true)
