extends PanelContainer

signal buy_requested(item_data: Dictionary)
signal equip_requested(item_data: Dictionary)

@onready var icon_texture = $HBoxContainer/Icon
@onready var title_label = $HBoxContainer/InfoContainer/TitleLabel
@onready var price_label = $HBoxContainer/InfoContainer/PriceLabel
@onready var action_button = $HBoxContainer/BuyButton

var current_item_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	current_item_data = data
	title_label.text = data.get("title", "Item")
	
	if data.get("texture_path") != "":
		icon_texture.texture = load(data.get("texture_path"))
	
	update_state()

func update_state() -> void:
	var item_id = current_item_data.get("id", "")
	var price = current_item_data.get("price", 0)
	
	var is_unlocked = item_id in GameManager.unlocked_launchers
	var is_equipped = (GameManager.equipped_launcher == item_id)
	
	if is_equipped:
		price_label.text = "EQUIPPED"
		action_button.text = "In Use"
		action_button.disabled = true
	elif is_unlocked:
		price_label.text = "ACQUIRED"
		action_button.text = "Equip"
		action_button.disabled = false
	else:
		price_label.text = "PRICE: " + str(price)
		action_button.text = "Buy"
		action_button.disabled = false

func _on_action_button_pressed() -> void:
	var item_id = current_item_data.get("id", "")
	
	if item_id in GameManager.unlocked_launchers:
		equip_requested.emit(current_item_data)
	else:
		buy_requested.emit(current_item_data)
