extends Control

const DEFAULT_RESET_WARNING := "Watch out for this button!"

signal opened
signal closed
signal themeshop_opened
signal difficulty_menu_opened

var _reset_countdown_token: int = 0

@onready var menu_music = $MenuMusic
@onready var menu_button_sound = $MenuButtonSound
@onready var coin_label = $CoinPanel/CoinLabel
@onready var vbox_container = $MenuScroll/MenuVBox

# Botões de controle de som, sliders e navegação
@onready var bgm_button = $MenuScroll/MenuVBox/Panel1/BGM
@onready var bgm_button_label = $MenuScroll/MenuVBox/Panel1/BGM/Label
@onready var bgm_slider = $MenuScroll/MenuVBox/PanelA/BGMHSlider
@onready var sfx_button = $MenuScroll/MenuVBox/Panel2/SFX
@onready var sfx_button_label = $MenuScroll/MenuVBox/Panel2/SFX/Label
@onready var sfx_slider = $MenuScroll/MenuVBox/PanelB/SFXHSlider
@onready var theme_button = $MenuScroll/MenuVBox/Panel3/ThemeButton
@onready var theme_button_label = $MenuScroll/MenuVBox/Panel3/ThemeButton/Label
@onready var biome_button = $MenuScroll/MenuVBox/Panel3b/BiomeButton
@onready var biome_button_label = $MenuScroll/MenuVBox/Panel3b/BiomeButton/Label
@onready var difficulty_button = $MenuScroll/MenuVBox/Panel4/DifficultyButton
@onready var difficulty_button_label = $MenuScroll/MenuVBox/Panel4/DifficultyButton/Label
@onready var language_button = $MenuScroll/MenuVBox/Panel4b/LanguageButton
@onready var language_button_label = $MenuScroll/MenuVBox/Panel4b/LanguageButton/Label
@onready var reset_button = $MenuScroll/MenuVBox/Panel5/ResetButton
@onready var reset_button_label = $MenuScroll/MenuVBox/Panel5/ResetButton/Label
@onready var reset_label = $MenuScroll/MenuVBox/Panel5/ResetLabel
@onready var back_button = $MenuScroll/MenuVBox/Panel6/BackButton
@onready var back_button_label = $MenuScroll/MenuVBox/Panel6/BackButton/Label
@onready var biome_opition = $MenuScroll/MenuVBox/PanelSuperUser/BiomeOption
@onready var buy_opition = $MenuScroll/MenuVBox/Panel7/BuyOpition
@onready var buy_button = $MenuScroll/MenuVBox/Panel7/BuyButton
@onready var buy_button_label = $MenuScroll/MenuVBox/Panel7/BuyButton/Label
@onready var exit_button = $MenuScroll/MenuVBox/Panel8/ExitButton
@onready var exit_button_label = $MenuScroll/MenuVBox/Panel8/ExitButton/Label
@onready var reset_confirm = $ConfirmationDialog

@export var theme_shop_ui: Control
@export var difficulty_menu_ui: Control
@export var language_menu_ui: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if not "marble" in GameManager.unlocked_launchers:
		GameManager.unlocked_launchers.append("marble")
		
	# Popula o OptionButton com os biomas disponíveis no GameManager
	if is_instance_valid(biome_opition):
		biome_opition.clear()
		var current_biome_idx := 0
		for i in range(GameManager.LAUNCHER_ORDER.size()):
			var biome_id: String = GameManager.LAUNCHER_ORDER[i]
			# Formata "crystal_palace" para "Crystal Palace" na exibição
			var display_name: String = biome_id.capitalize()
			biome_opition.add_item(display_name, i)
			if biome_id == GameManager.current_biome:
				current_biome_idx = i
		biome_opition.select(current_biome_idx)
		
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

	if is_instance_valid(difficulty_button):
		if not difficulty_button.pressed.is_connected(_on_difficulty_button_pressed):
			difficulty_button.pressed.connect(_on_difficulty_button_pressed)

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
	# Sincroniza o seletor de bioma caso o jogador tenha avançado de ciclo
	if is_instance_valid(biome_opition):
		var idx := GameManager.LAUNCHER_ORDER.find(GameManager.current_biome)
		if idx != -1:
			biome_opition.select(idx)
	for child in vbox_container.get_children():
		if child.has_method("update_state"):
			child.update_state()

func _update_audio_buttons_visual_state() -> void:
	if is_instance_valid(bgm_button):
		bgm_button.button_pressed = GameManager.is_bgm_muted
		if is_instance_valid(bgm_button_label):
			bgm_button_label.text = "Enable Music" if GameManager.is_bgm_muted else "Disable Music"

	if is_instance_valid(bgm_slider):
		bgm_slider.value = GameManager.bgm_volume_linear
		bgm_slider.editable = not GameManager.is_bgm_muted

	if is_instance_valid(sfx_button):
		sfx_button.button_pressed = GameManager.is_sfx_muted
		if is_instance_valid(sfx_button_label):
			sfx_button_label.text = "Enable Sound" if GameManager.is_sfx_muted else "Disable Sound"

	if is_instance_valid(sfx_slider):
		sfx_slider.value = GameManager.sfx_volume_linear
		sfx_slider.editable = not GameManager.is_sfx_muted

func _on_bgm_button_toggled(toggled_on: bool) -> void:
	menu_button_sound.play()
	GameManager.is_bgm_muted = toggled_on
	GameManager.apply_audio_settings()
	GameManager.save_game_data()

	if is_instance_valid(bgm_button_label):
		bgm_button_label.text = "Enable Music" if toggled_on else "Disable Music"

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

	if is_instance_valid(sfx_button_label):
		sfx_button_label.text = "Enable Sound" if toggled_on else "Disable Sound"

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
	menu_button_sound.play()
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

func _on_biome_button_pressed() -> void:
	pass # Replace with function body.

func _on_difficulty_button_pressed() -> void:
	menu_button_sound.play()
	if menu_music and menu_music.playing:
		menu_music.stop()
	
	hide()
	difficulty_menu_opened.emit()
	
	var target_shop: Node = difficulty_menu_ui
	
	if not is_instance_valid(target_shop):
		if get_parent() and get_parent().has_node("DifficultyMenu"):
			target_shop = get_parent().get_node("DifficultyMenu")
		elif get_node_or_null("../DifficultyMenu") != null:
			target_shop = get_node("../DifficultyMenu")

	if is_instance_valid(target_shop):
		target_shop.show()
		
		if not GameManager.is_bgm_muted:
			var shop_music = target_shop.find_child("*BGM*", true, false)
			if shop_music and shop_music is AudioStreamPlayer and not shop_music.playing:
				shop_music.play()

		if target_shop.has_method("open"):
			target_shop.open()
		elif target_shop.has_method("toggle_shop"):
			target_shop.toggle_shop()

func _on_language_button_pressed() -> void:
	pass # Replace with function body.

func _on_reset_button_pressed() -> void:
	menu_button_sound.play()
	
	if is_instance_valid(reset_confirm):
		_reset_countdown_token += 1
		var current_token := _reset_countdown_token
		
		#reset_confirm.dialog_text = "Are you sure you want to reset all save data?"
		reset_confirm.cancel_button_text = "Cancel"
		
		var ok_btn: Button = reset_confirm.get_ok_button()
		if is_instance_valid(ok_btn):
			ok_btn.disabled = true
			ok_btn.text = "5"
		else:
			reset_confirm.ok_button_text = "5"
		
		if not reset_confirm.confirmed.is_connected(_on_reset_confirmed):
			reset_confirm.confirmed.connect(_on_reset_confirmed)
		if not reset_confirm.canceled.is_connected(_on_reset_canceled):
			reset_confirm.canceled.connect(_on_reset_canceled)
			
		reset_confirm.popup_centered()
		
		# Contagem regressiva de 5 até 1 (1.0s cada) com o botão OK desabilitado
		for count in ["5", "4", "3", "2", "1"]:
			if current_token != _reset_countdown_token or not is_instance_valid(reset_confirm) or not reset_confirm.visible:
				return
			if is_instance_valid(ok_btn):
				ok_btn.disabled = true
				ok_btn.text = count
			await get_tree().create_timer(1.0, true).timeout
		
		# Finaliza a contagem e libera o botão Confirm
		if current_token != _reset_countdown_token or not is_instance_valid(reset_confirm) or not reset_confirm.visible:
			return
		if is_instance_valid(ok_btn):
			ok_btn.text = "Confirm"
			ok_btn.disabled = false
		else:
			reset_confirm.ok_button_text = "Confirm"
	else:
		_on_reset_confirmed()

func _on_reset_confirmed() -> void:
	_reset_countdown_token += 1
	_disconnect_reset_dialog_signals()
	GameManager.reset_all_save_data()
	
	if Engine.has_singleton("InAppManager") or get_node_or_null("/root/InAppManager") != null:
		get_node("/root/InAppManager").reset_local_purchases()
		
	reset_label.text = "Save successfully cleared!"
	_update_audio_buttons_visual_state()
	
	await get_tree().create_timer(2.0, true).timeout
	if is_instance_valid(reset_label):
		reset_label.text = DEFAULT_RESET_WARNING

func _on_reset_canceled() -> void:
	_reset_countdown_token += 1
	#var ok_btn := reset_confirm.get_ok_button() if is_instance_valid(reset_confirm) else null
	var ok_btn: Button = reset_confirm.get_ok_button() if is_instance_valid(reset_confirm) else null
	if is_instance_valid(ok_btn):
		ok_btn.disabled = false
	_disconnect_reset_dialog_signals()

func _disconnect_reset_dialog_signals() -> void:
	if is_instance_valid(reset_confirm):
		if reset_confirm.confirmed.is_connected(_on_reset_confirmed):
			reset_confirm.confirmed.disconnect(_on_reset_confirmed)
		if reset_confirm.canceled.is_connected(_on_reset_canceled):
			reset_confirm.canceled.disconnect(_on_reset_canceled)

func _on_buy_button_pressed() -> void:
	menu_button_sound.play()
	
	# 1. Define o bioma selecionado no BiomeOption antes de aplicar o nível
	if is_instance_valid(biome_opition) and biome_opition.selected >= 0:
		var biome_index: int = biome_opition.get_item_id(biome_opition.selected)
		if biome_index >= 0 and biome_index < GameManager.LAUNCHER_ORDER.size():
			GameManager.current_biome = GameManager.LAUNCHER_ORDER[biome_index]
	
	# 2. Pega o número da casa selecionada diretamente no OptionButton (buy_opition)
	var selected_level = 1
	if is_instance_valid(buy_opition):
		# O ID do item que guardamos é o próprio número da casa (1 a 45)
		selected_level = buy_opition.get_item_id(buy_opition.selected)
		
	# Salva o nível dentro do bioma recém-selecionado e recalcula a velocidade da prensa
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
