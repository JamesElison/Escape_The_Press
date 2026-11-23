extends PanelContainer

signal buy_requested(item_data: Dictionary)
signal equip_requested(item_data: Dictionary)

@onready var item_accepted_sound = $ItemAccepted
@onready var item_not_accepted_sound = $ItemNotAccepted
@onready var icon_texture = $Icon
@onready var theme_label = $ThemeLabel
@onready var price_label = $PriceLabel
@onready var action_button = $BuyButton
@onready var action_button_label = $BuyButton/BuyButtonLabel

var current_item_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	current_item_data = data
	
	if theme_label:
		theme_label.text = data.get("title", "")
	
	if data.get("biome_path") != "":
		icon_texture.texture = load(data.get("biome_path"))
	
	update_state()

func update_state() -> void:
	var item_id: String = str(current_item_data.get("id", ""))
	var is_current_biome: bool = (GameManager.current_biome == item_id)
	var is_conquered: bool = GameManager.is_biome_completed(item_id)
	
	if is_current_biome:
		price_label.text = ""
		action_button_label.text = tr("BIOME_BUTTON_EXPLORING")
		action_button.disabled = true
	elif is_conquered:
		price_label.text = tr("BIOME_PRICE_AVALIABLE")
		action_button_label.text = tr("BIOME_BUTTON_JOIN")
		action_button.disabled = false
	else:
		price_label.text = tr("BIOME_PRICE_UNAVALIABLE")
		action_button_label.text = tr("BIOME_BUTTON_BLOCKED")
		action_button.disabled = true

func _on_action_button_pressed() -> void:
	var item_id: String = str(current_item_data.get("id", ""))
	
	if GameManager.can_join_biome(item_id) and GameManager.current_biome != item_id:
		if item_accepted_sound:
			item_accepted_sound.play()
		equip_requested.emit(current_item_data)
	else:
		if item_not_accepted_sound:
			item_not_accepted_sound.play()
