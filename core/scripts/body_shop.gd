extends Control

signal opened
signal closed

const SHOP_ITEM_SCENE = preload("res://core/scenes/set_elements/shop_item.tscn")

@onready var vbox_container = $BodyShopScroll/BodyShopVBox

# Definição do catálogo de lançadores disponíveis
var items_catalog: Array[Dictionary] = [
	{
		"id": "Standart",
		"title": "Ball launcher",
		"price": "N/A",
		"texture_path": "res://core/assets/sprites/characters/player.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/"
	},
	{
		"id": "120mm",
		"title": "120mm Type",
		"price": 1000,
		"texture_path": "res://core/assets/sprites/characters/launchers_for_sale/1_120mm_type.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/1_120mm_type/"
	},
	{
		"id": "piercing",
		"title": "Hig Piercing Type",
		"price": 3000,
		"texture_path": "res://core/assets/sprites/characters/launchers_for_sale/2_piercing_type.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/2_piercing_type/"
	},
	{
		"id": "mini_plasma",
		"title": "Mini Plasma Type",
		"price": 5000,
		"texture_path": "res://core/assets/sprites/characters/launchers_for_sale/3_mini_plasma_type.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/3_mini_plasma_type/"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	# Garantia: O lançador padrão sempre deve estar liberado nos salvamentos
	if not "Standart" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("Standart")
		
	populate_shop()

func populate_shop() -> void:
	# Limpa itens antigos para re-gerar a lista limpa
	for child in vbox_container.get_children():
		child.queue_free()
		
	for item_data in items_catalog:
		var item_node = SHOP_ITEM_SCENE.instantiate()
		vbox_container.add_child(item_node)
		item_node.setup(item_data)
		
		item_node.buy_requested.connect(_on_item_buy_requested)
		item_node.equip_requested.connect(_on_item_equip_requested)

func refresh_all_items() -> void:
	for child in vbox_container.get_children():
		if child.has_method("update_state"):
			child.update_state()

func _on_item_buy_requested(item_data: Dictionary) -> void:
	var price = item_data.get("price", 0)
	var item_id = item_data.get("id", "")
	
	if GameManager.remove_coins(price):
		GameManager.unlocked_launchers.append(item_id)
		GameManager.equipped_launcher = item_id
		GameManager.save_game_data()
		refresh_all_items()
		EventBus.launcher_changed.emit(item_id)
		close() # Retorna ao jogo imediatamente após a compra

func _on_item_equip_requested(item_data: Dictionary) -> void:
	var item_id = item_data.get("id", "")
	GameManager.equipped_launcher = item_id
	GameManager.save_game_data()
	refresh_all_items()
	EventBus.launcher_changed.emit(item_id)
	close() # Retorna ao jogo imediatamente após equipar

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()
