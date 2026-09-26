extends Control

signal opened
signal closed

@onready var body_shop_music = $BodyShopMusic
@onready var vbox_container = $BodyShopScroll/BodyShopVBox
@onready var reset_button = $BodyShopScroll/BodyShopVBox/Panel5/ResetButton
@onready var reset_label = $BodyShopScroll/BodyShopVBox/Panel5/ResetLabel

# Referência ao botão de Temas dentro do Panel3
@onready var theme_button = $BodyShopScroll/BodyShopVBox/Panel3/ThemeButton

# Referência opcional exportada para a interface do BodyShop antigo
@export var theme_shop_ui: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if not "Standart" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("Standart")
	
	if is_instance_valid(reset_button):
		if not reset_button.pressed.is_connected(_on_reset_button_pressed):
			reset_button.pressed.connect(_on_reset_button_pressed)

	if is_instance_valid(theme_button):
		if not theme_button.pressed.is_connected(_on_theme_button_pressed):
			theme_button.pressed.connect(_on_theme_button_pressed)

func refresh_all_items() -> void:
	for child in vbox_container.get_children():
		if child.has_method("update_state"):
			child.update_state()

func _reload_test_area() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if body_shop_music and not body_shop_music.playing:
		body_shop_music.play()
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	if body_shop_music and body_shop_music.playing:
		body_shop_music.stop()
	hide()
	get_tree().paused = false
	closed.emit()

func _on_theme_button_pressed() -> void:
	# 1. Para a música do Menu e oculta a tela
	if body_shop_music and body_shop_music.playing:
		body_shop_music.stop()
	hide()
		
	# 2. Localiza e abre a Loja de Temas (BodyShop)
	var target_shop: Node = theme_shop_ui
	
	if not is_instance_valid(target_shop):
		if get_parent() and get_parent().has_node("BodyShop"):
			target_shop = get_parent().get_node("BodyShop")
		elif get_node_or_null("../BodyShop") != null:
			target_shop = get_node("../BodyShop")

	if is_instance_valid(target_shop):
		target_shop.show()
		
		# Toca a música própria da loja de temas caso ela tenha um nó dedicado
		var shop_music = target_shop.find_child("*Music*", true, false)
		if shop_music and shop_music is AudioStreamPlayer and not shop_music.playing:
			shop_music.play()

		if target_shop.has_method("open"):
			target_shop.open()
		elif target_shop.has_method("toggle_shop"):
			target_shop.toggle_shop()

func _on_reset_button_pressed() -> void:
	GameManager.reset_all_save_data()
	
	if Engine.has_singleton("InAppManager") or get_node_or_null("/root/InAppManager") != null:
		get_node("/root/InAppManager").reset_local_purchases()
		
	reset_label.text = str("Save successfully cleared!")
	await get_tree().create_timer(2).timeout
	reset_label.text = ""
	print("Save successfully cleared!")
