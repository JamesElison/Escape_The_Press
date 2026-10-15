extends Control

signal opened
signal closed

const SHOP_ITEM_SCENE = preload("res://core/scenes/set_elements/shop_item.tscn")

@onready var theme_shop_music = $ThemeShopMusic
@onready var vbox_container = $ThemeShopScroll/ThemeShopVBox

var items_catalog: Array[Dictionary] = [
	{
		"id": "marble",
		"title": "Marble",
		"price": "N/A",  # Padrão inicial
		"texture_path": "res://core/assets/HUD/texture_path/0_marble_720x256_v2.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/"
	},
	{
		"id": "120mm",
		"title": "120mm",
		"price": 0,   # Preço de exemplo para compra na lojinha
		"texture_path": "res://core/assets/HUD/texture_path/1_120mm_720x256.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/1_120mm_type/"
	},
	{
		"id": "piercing",
		"title": "Piercing",
		"price": 0,
		"texture_path": "res://core/assets/HUD/texture_path/2_piercing_720x256.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/2_piercing_type/"
	},
	{
		"id": "mini_plasma",
		"title": "Mini Plasma",
		"price": 0,
		"texture_path": "res://core/assets/HUD/texture_path/3_mini_plasma_720x256_v2.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/3_mini_plasma_type/"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if not "marble" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("marble")
		
	populate_shop()

func populate_shop() -> void:
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
	
	# Garanta que preços "N/A" ou string não quebrem a lógica caso passem por aqui
	if typeof(price) == TYPE_STRING:
		price = 0
		
	if GameManager.remove_coins(price):
		if not item_id in GameManager.unlocked_launchers:
			GameManager.unlocked_launchers.append(item_id)
			
		GameManager.equip_launcher_scenario(item_id)
		refresh_all_items()
		EventBus.launcher_changed.emit(item_id)
		close()
		_reload_game_play_area()

func _on_item_equip_requested(item_data: Dictionary) -> void:
	var item_id = item_data.get("id", "")
	GameManager.equip_launcher_scenario(item_id)
	refresh_all_items()
	EventBus.launcher_changed.emit(item_id)
	close()
	_reload_game_play_area()

func _reload_game_play_area() -> void:
	# Recarrega a cena atual para aplicar as alterações de visual do novo lançador
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if theme_shop_music:
		theme_shop_music.play()
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	if theme_shop_music:
		theme_shop_music.stop()
	hide()
	get_tree().paused = false
	closed.emit()
