extends PanelContainer

signal buy_requested(item_data: Dictionary)
signal equip_requested(item_data: Dictionary)

@onready var item_accepted_sound = $ItemAccepted
@onready var item_not_accepted_sound = $ItemNotAccepted
@onready var icon_texture = $Icon
@onready var price_label = $PriceLabel
@onready var action_button = $BuyButton
@onready var action_button_label = $BuyButton/BuyButtonLabel

var current_item_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	current_item_data = data
	
	if data.get("texture_path") != "":
		icon_texture.texture = load(data.get("texture_path"))
	
	update_state()

func update_state() -> void:
	var item_id = current_item_data.get("id", "")
	var price = current_item_data.get("price", 0)
	
	var is_unlocked = item_id in GameManager.unlocked_launchers
	var is_equipped = (GameManager.equipped_launcher == item_id)
	
	if is_equipped:
		price_label.text = ""
		action_button_label.text = "Using"
		action_button.disabled = true
	elif is_unlocked:
		price_label.text = "Acquired"
		action_button_label.text = "To Use"
		action_button.disabled = false
	else:
		# Exibe o preço formatado com ponto separador de milhar
		if typeof(price) == TYPE_INT or typeof(price) == TYPE_FLOAT:
			price_label.text = _format_number(int(price)) + " Coins"
		else:
			price_label.text = str(price)
			
		action_button_label.text = "Buy"
		action_button.disabled = false

func _on_action_button_pressed() -> void:
	var item_id = current_item_data.get("id", "")
	
	if item_id in GameManager.unlocked_launchers:
		if item_accepted_sound:
			item_accepted_sound.play()
		equip_requested.emit(current_item_data)
	else:
		var price = current_item_data.get("price", 0)
		if typeof(price) == TYPE_STRING:
			price = 0
			
		# Verifica se o jogador tem moedas suficientes
		if GameManager.coins >= price:
			if item_accepted_sound:
				item_accepted_sound.play()
			buy_requested.emit(current_item_data)
		else:
			if item_not_accepted_sound:
				item_not_accepted_sound.play()

# Função auxiliar para formatar milhares (ex: 35000 -> "35.000")
func _format_number(number: int) -> String:
	var num_str = str(number)
	var result = ""
	var length = num_str.length()
	
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			result += "."
		result += num_str[i]
		
	return result
