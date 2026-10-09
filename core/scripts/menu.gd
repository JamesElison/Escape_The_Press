extends Control

signal opened
signal closed

@onready var body_shop_music = $BodyShopMusic
@onready var menu_button_sound = $MenuButtonSound
@onready var vbox_container = $BodyShopScroll/BodyShopVBox

# Botões de controle de som e navegação
@onready var bgm_button = $BodyShopScroll/BodyShopVBox/Panel1/BGM
@onready var sfx_button = $BodyShopScroll/BodyShopVBox/Panel2/SFX
@onready var theme_button = $BodyShopScroll/BodyShopVBox/Panel3/ThemeButton
@onready var sound_track_button = $BodyShopScroll/BodyShopVBox/Panel4/SoundtrackButton
@onready var reset_button = $BodyShopScroll/BodyShopVBox/Panel5/ResetButton
@onready var reset_label = $BodyShopScroll/BodyShopVBox/Panel5/ResetLabel
@onready var back_button = $BodyShopScroll/BodyShopVBox/Panel6/BackButton
@onready var buy_button = $BodyShopScroll/BodyShopVBox/Panel7/BuyButton
@onready var buy_button_label = $BodyShopScroll/BodyShopVBox/Panel7/BuyButton/Label
@onready var exit_button = $BodyShopScroll/BodyShopVBox/Panel8/ExitButton

@export var theme_shop_ui: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameManager.called_from_the_start_menu:
		open()
	else:
		close()
	
	if not "Standart" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("Standart")
	
	# Configura os botões BGM e SFX como botões alternáveis (toggle)
	if is_instance_valid(bgm_button):
		bgm_button.toggle_mode = true
		if not bgm_button.toggled.is_connected(_on_bgm_button_toggled):
			bgm_button.toggled.connect(_on_bgm_button_toggled)

	if is_instance_valid(sfx_button):
		sfx_button.toggle_mode = true
		if not sfx_button.toggled.is_connected(_on_sfx_button_toggled):
			sfx_button.toggled.connect(_on_sfx_button_toggled)

	if is_instance_valid(theme_button):
		if not theme_button.pressed.is_connected(_on_theme_button_pressed):
			theme_button.pressed.connect(_on_theme_button_pressed)

	if is_instance_valid(reset_button):
		if not reset_button.pressed.is_connected(_on_reset_button_pressed):
			reset_button.pressed.connect(_on_reset_button_pressed)

	if is_instance_valid(back_button):
		if not back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.connect(_on_back_button_pressed)

	if is_instance_valid(exit_button):
		if not exit_button.pressed.is_connected(_on_exit_button_pressed):
			exit_button.pressed.connect(_on_exit_button_pressed)

	_update_audio_buttons_visual_state()

func refresh_all_items() -> void:
	_update_audio_buttons_visual_state()
	for child in vbox_container.get_children():
		if child.has_method("update_state"):
			child.update_state()

func _update_audio_buttons_visual_state() -> void:
	# Atualiza o estado pressionado (toggle) sem desativar a interatividade do botão
	if is_instance_valid(bgm_button):
		bgm_button.button_pressed = GameManager.is_bgm_muted

	if is_instance_valid(sfx_button):
		sfx_button.button_pressed = GameManager.is_sfx_muted

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	menu_button_sound.play()
	GameManager.is_bgm_muted = toggled_on
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

	# Se for mutado, interrompe a música do menu; se desmutado, retoma se estiver visível
	if GameManager.is_bgm_muted:
		if body_shop_music and body_shop_music.playing:
			body_shop_music.stop()
	else:
		if visible and body_shop_music and not body_shop_music.playing:
			body_shop_music.play()

func _on_sfx_button_toggled(toggled_on: bool) -> void:
	menu_button_sound.play()
	GameManager.is_sfx_muted = toggled_on
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

func _reload_test_area() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if not GameManager.is_bgm_muted and body_shop_music and not body_shop_music.playing:
		body_shop_music.play()
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	if GameManager.called_from_the_start_menu:
		GameManager.called_from_the_start_menu = false
	
	if body_shop_music and body_shop_music.playing:
		AudioManager.stop_with_fade_out(body_shop_music, 1.0)
	hide()
	get_tree().paused = false
	closed.emit()

func _on_theme_button_pressed() -> void:
	if body_shop_music and body_shop_music.playing:
		AudioManager.stop_with_fade_out(body_shop_music, 1.0)
	hide()
		
	var target_shop: Node = theme_shop_ui
	
	if not is_instance_valid(target_shop):
		if get_parent() and get_parent().has_node("BodyShop"):
			target_shop = get_parent().get_node("BodyShop")
		elif get_node_or_null("../BodyShop") != null:
			target_shop = get_node("../BodyShop")

	if is_instance_valid(target_shop):
		target_shop.show()
		
		if not GameManager.is_bgm_muted:
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
	_update_audio_buttons_visual_state()

func _on_back_button_pressed() -> void:
	menu_button_sound.play()
	GameManager.called_from_the_start_menu = false
	get_tree().paused = false
	if body_shop_music and body_shop_music.playing:
		AudioManager.stop_with_fade_out(body_shop_music, 1.0)
	await menu_button_sound.finished
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")

func _on_exit_button_pressed() -> void:
	menu_button_sound.play()
	GameManager.called_from_the_start_menu = false
	GameManager.save_game_data()
	if body_shop_music and body_shop_music.playing:
		AudioManager.stop_with_fade_out(body_shop_music, 1.0)
	await menu_button_sound.finished
	get_tree().quit()
