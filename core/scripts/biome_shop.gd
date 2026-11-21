extends Control

signal opened
signal closed

const SHOP_ITEM_SCENE = preload("res://core/scenes/set_elements/biome_item.tscn")

@onready var theme_shop_music = $ThemeShopMusic
@onready var vbox_container = $ThemeShopScroll/ThemeShopVBox

var items_catalog: Array[Dictionary] = [
	{
		"id": "crystal_palace",
		"title": "Cristal Palace",
		"price": "N/A",
		"biome_path": "res://core/assets/HUD/biome_path/crystal_palace_720x256_v2.png"
	},
	{
		"id": "ancient_ruins",
		"title": "Ancient Ruins",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/ancient_ruins_720x256_v2.png"
	},
	{
		"id": "heavy_metal",
		"title": "Heavy Metal",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/heavy_metal_720x256.png"
	},
	{
		"id": "sub_zero",
		"title": "Freezing Hell",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/subzero_720x256.png"
	},
	{
		"id": "seabed",
		"title": "Seabed",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/seabed_720x256.png"
	},
	{
		"id": "desert",
		"title": "Scorching Desert",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/desert_720x256.png"
	},
	{
		"id": "house",
		"title": "Shadowy House",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/house_720x256.png"
	},
	{
		"id": "space",
		"title": "Deep Space",
		"price": 0,
		"biome_path": "res://core/assets/HUD/biome_path/deep_space_720x256.png"
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
	_on_item_equip_requested(item_data)

func _on_item_equip_requested(item_data: Dictionary) -> void:
	var item_id: String = str(item_data.get("id", ""))
	if not GameManager.select_biome_from_shop(item_id):
		return

	refresh_all_items()
	close()
	_reload_game_play_area()

func _reload_game_play_area() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if theme_shop_music and not GameManager.is_bgm_muted:
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
