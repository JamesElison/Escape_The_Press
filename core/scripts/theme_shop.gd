extends Control

signal opened
signal closed

const SHOP_ITEM_SCENE = preload("res://core/scenes/set_elements/shop_item.tscn")

@onready var theme_shop_music = $ThemeShopMusic
@onready var vbox_container = $ThemeShopScroll/ThemeShopVBox

var items_catalog: Array[Dictionary] = [
	{
		"id": "marble",
		"title_key": "THEME_SHOP_TITLE_MARBLE",
		"price": "N/A",  # Padrão inicial
		"texture_path": "res://core/assets/HUD/texture_path/0_marble_720x256_v2.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/"
	},
	{
		"id": "120mm",
		"title_key": "THEME_SHOP_TITLE_120MM",
		"price": 100000,   # Preço de exemplo para compra na lojinha
		"texture_path": "res://core/assets/HUD/texture_path/1_120mm_720x256.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/1_120mm_type/"
	},
	{
		"id": "piercing",
		"title_key": "THEME_SHOP_TITLE_PIERCING",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/2_piercing_720x256.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/2_piercing_type/"
	},
	{
		"id": "mini_plasma",
		"title_key": "THEME_SHOP_TITLE_MINI_PLASMA",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/3_mini_plasma_720x256_v2.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/3_mini_plasma_type/"
	},
	{
		"id": "flame",
		"title_key": "THEME_SHOP_TITLE_FLAME_THROWER",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/4_flame_720x256.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/4_flame_type/"
	},
	{
		"id": "high_voltage",
		"title_key": "THEME_SHOP_TITLE_HIGH_VOLTAGE",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/5_high_voltage_720x256.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/5_high_voltage_type/"
	},
	{
		"id": "fire_fighter",
		"title_key": "THEME_SHOP_TITLE_FIRE_FIGHTER",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/6_fire_fighter_720x256.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/6_fire_fighter/"
	},
	{
		"id": "laser_beam",
		"title_key": "THEME_SHOP_TITLE_LASER_BEAM",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/7_laser_beam_720x256.jpg",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/7_laser_beam/"
	},
	{
		"id": "ice_cube",
		"title_key": "THEME_SHOP_TITLE_ICE_CUBE",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/8_ice_cube_720x256.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/8_ice_cube/"
	},
	{
		"id": "dart",
		"title_key": "THEME_SHOP_TITLE_DART",
		"price": 100000,
		"texture_path": "res://core/assets/HUD/texture_path/9_dart_720x256.png",
		"projectile_dir": "res://core/assets/sprites/set_objects/specific_projectiles/9_dart/"
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
		var localized_item := item_data.duplicate()
		var title_key: String = item_data.get("title_key", "")
		if title_key != "":
			localized_item["title"] = tr(title_key)
			
		var item_node = SHOP_ITEM_SCENE.instantiate()
		vbox_container.add_child(item_node)
		item_node.setup(localized_item)
		
		item_node.buy_requested.connect(_on_item_buy_requested)
		item_node.equip_requested.connect(_on_item_equip_requested)

func refresh_all_items() -> void:
	for child in vbox_container.get_children():
		if child.has_method("update_state"):
			child.update_state()

func _on_item_buy_requested(item_data: Dictionary) -> void:
	var price = item_data.get("price", 0)
	var item_id = item_data.get("id", "")
	
	if GameManager.is_choosing_temporary_launcher:
		_apply_bonus_temporary_launcher_and_enter_level(item_id)
		return
	
	# Garanta que preços "N/A" ou string não quebrem a lógica caso passem por aqui
	if typeof(price) == TYPE_STRING:
		price = 0
		
	if GameManager.remove_coins(price):
		if not item_id in GameManager.unlocked_launchers:
			GameManager.unlocked_launchers.append(item_id)
			
		GameManager.equip_launcher_scenario(item_id)
		refresh_all_items()
		EventBus.launcher_changed.emit(item_id)
		await get_tree().create_timer(0.3).timeout
		close()
		_reload_game_play_area()

func _on_item_equip_requested(item_data: Dictionary) -> void:
	var item_id = item_data.get("id", "")
	
	if GameManager.is_choosing_temporary_launcher:
		_apply_bonus_temporary_launcher_and_enter_level(item_id)
		return
	
	GameManager.equip_launcher_scenario(item_id)
	refresh_all_items()
	EventBus.launcher_changed.emit(item_id)
	close()
	_reload_game_play_area()

func _reload_game_play_area() -> void:
	# Recarrega a cena atual para aplicar as alterações de visual do novo lançador
	get_tree().paused = false
	get_tree().reload_current_scene()

func _apply_bonus_temporary_launcher_and_enter_level(item_id: String) -> void:
	if item_id == "":
		return
		
	GameManager.equip_temporary_launcher(item_id, 1)
	GameManager.is_choosing_temporary_launcher = false
	GameManager.set_level_from_stop(GameManager.current_level)
	
	refresh_all_items()
	EventBus.launcher_changed.emit(item_id)
	
	if theme_shop_music and theme_shop_music.playing:
		theme_shop_music.stop()
		
	hide()
	get_tree().paused = false
	closed.emit()
	
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://core/scenes/levels/level.tscn")


func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if theme_shop_music:
		theme_shop_music.play()
	populate_shop()
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	GameManager.is_choosing_temporary_launcher = false
	if theme_shop_music:
		theme_shop_music.stop()
	hide()
	get_tree().paused = false
	closed.emit()
