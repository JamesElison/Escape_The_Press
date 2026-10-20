extends Control

signal opened
signal closed
signal themeshop_opened

@onready var menu_music = $MenuMusic
@onready var menu_button_sound = $MenuButtonSound
@onready var vbox_container = $MenuScroll/MenuVBox

# Botões de controle de som, sliders e navegação
@onready var bgm_button = $MenuScroll/MenuVBox/Panel1/BGM
@onready var bgm_slider = $MenuScroll/MenuVBox/Panel1/BGMHSlider
@onready var sfx_button = $MenuScroll/MenuVBox/Panel2/SFX
@onready var sfx_slider = $MenuScroll/MenuVBox/Panel2/SFXHSlider
@onready var theme_button = $MenuScroll/MenuVBox/Panel3/ThemeButton
@onready var sound_track_button = $MenuScroll/MenuVBox/Panel4/SoundtrackButton
@onready var reset_button = $MenuScroll/MenuVBox/Panel5/ResetButton
@onready var reset_label = $MenuScroll/MenuVBox/Panel5/ResetLabel
@onready var back_button = $MenuScroll/MenuVBox/Panel6/BackButton
@onready var buy_opition = $MenuScroll/MenuVBox/PanelSuperUser/BuyOpition
@onready var buy_button = $MenuScroll/MenuVBox/Panel7/BuyButton
@onready var buy_button_label = $MenuScroll/MenuVBox/Panel7/BuyButton/Label
@onready var exit_button = $MenuScroll/MenuVBox/Panel8/ExitButton

@export var theme_shop_ui: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if not "marble" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("marble")
		
	# Popula o OptionButton com as casas de 1 a 45 para testes rápidos
	if is_instance_valid(buy_opition):
		buy_opition.clear()
		for i in range(1, 46):
			buy_opition.add_item("Casa " + str(i), i)
		buy_opition.select(0) # Seleciona a primeira opção por padrão
	
	# Configura os botões BGM e SFX como botões alternáveis (toggle)
	if is_instance_valid(bgm_button):
		bgm_button.toggle_mode = true
		if not bgm_button.toggled.is_connected(_on_bgm_button_toggled):
			bgm_button.toggled.connect(_on_bgm_button_toggled)

	# Configura o Slider de BGM
	if is_instance_valid(bgm_slider):
		bgm_slider.min_value = 0.0
		bgm_slider.max_value = 1.0
		bgm_slider.step = 0.05
		bgm_slider.value = GameManager.bgm_volume_linear
		if not bgm_slider.value_changed.is_connected(_on_bgm_slider_value_changed):
			bgm_slider.value_changed.connect(_on_bgm_slider_value_changed)

	if is_instance_valid(sfx_button):
		sfx_button.toggle_mode = true
		if not sfx_button.toggled.is_connected(_on_sfx_button_toggled):
			sfx_button.toggled.connect(_on_sfx_button_toggled)

	# Configura o Slider de SFX
	if is_instance_valid(sfx_slider):
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.step = 0.05
		sfx_slider.value = GameManager.sfx_volume_linear
		if not sfx_slider.value_changed.is_connected(_on_sfx_slider_value_changed):
			sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

	if is_instance_valid(theme_button):
		if not theme_button.pressed.is_connected(_on_theme_button_pressed):
			theme_button.pressed.connect(_on_theme_button_pressed)

	if is_instance_valid(reset_button):
		if not reset_button.pressed.is_connected(_on_reset_button_pressed):
			reset_button.pressed.connect(_on_reset_button_pressed)

	if is_instance_valid(back_button):
		if not back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.connect(_on_back_button_pressed)

	if is_instance_valid(buy_button):
		if not buy_button.pressed.is_connected(_on_buy_button_pressed):
			buy_button.pressed.connect(_on_buy_button_pressed)

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
	if is_instance_valid(bgm_button):
		bgm_button.button_pressed = GameManager.is_bgm_muted

	if is_instance_valid(bgm_slider):
		bgm_slider.value = GameManager.bgm_volume_linear
		bgm_slider.editable = not GameManager.is_bgm_muted

	if is_instance_valid(sfx_button):
		sfx_button.button_pressed = GameManager.is_sfx_muted

	if is_instance_valid(sfx_slider):
		sfx_slider.value = GameManager.sfx_volume_linear
		sfx_slider.editable = not GameManager.is_sfx_muted

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	menu_button_sound.play()
	GameManager.is_bgm_muted = toggled_on
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

	if is_instance_valid(bgm_slider):
		bgm_slider.editable = not toggled_on

	if GameManager.is_bgm_muted:
		if menu_music and menu_music.playing:
			menu_music.stop()
	else:
		if visible and menu_music and not menu_music.playing:
			menu_music.play()

func _on_bgm_slider_value_changed(value: float) -> void:
	GameManager.bgm_volume_linear = value
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

func _on_sfx_button_toggled(toggled_on: bool) -> void:
	menu_button_sound.play()
	GameManager.is_sfx_muted = toggled_on
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

	if is_instance_valid(sfx_slider):
		sfx_slider.editable = not toggled_on

func _on_sfx_slider_value_changed(value: float) -> void:
	GameManager.sfx_volume_linear = value
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

func _reload_previous_area() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if not GameManager.is_bgm_muted and menu_music and not menu_music.playing:
		menu_music.play()
	refresh_all_items()
	show()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	if menu_music and menu_music.playing:
		AudioManager.stop_with_fade_out(menu_music, 1.0)
	hide()
	get_tree().paused = false
	closed.emit()

func _on_theme_button_pressed() -> void:
	if menu_music and menu_music.playing:
		menu_music.stop()
	
	hide()
	themeshop_opened.emit()
	
	var target_shop: Node = theme_shop_ui
	
	if not is_instance_valid(target_shop):
		if get_parent() and get_parent().has_node("ThemeShop"):
			target_shop = get_parent().get_node("ThemeShop")
		elif get_node_or_null("../ThemeShop") != null:
			target_shop = get_node("../ThemeShop")

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

func _on_buy_button_pressed() -> void:
	menu_button_sound.play()
	
	# Pega o número da casa selecionada diretamente no OptionButton (buy_opition)
	var selected_level = 1
	if is_instance_valid(buy_opition):
		# O ID do item que guardamos é o próprio número da casa (1 a 45)
		selected_level = buy_opition.get_item_id(buy_opition.selected)
		
	GameManager.set_level_from_stop(selected_level)
	
	get_tree().paused = false
	if menu_music and menu_music.playing:
		AudioManager.stop_with_fade_out(menu_music, 1.0)
	await menu_button_sound.finished
	get_tree().change_scene_to_file("res://core/scenes/levels/Map.tscn")

func _on_back_button_pressed() -> void:
	menu_button_sound.play()
	get_tree().paused = false
	if menu_music and menu_music.playing:
		AudioManager.stop_with_fade_out(menu_music, 1.0)
	await menu_button_sound.finished
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")

func _on_exit_button_pressed() -> void:
	menu_button_sound.play()
	GameManager.save_game_data()
	if menu_music and menu_music.playing:
		AudioManager.stop_with_fade_out(menu_music, 1.0)
	await menu_button_sound.finished
	get_tree().quit()
