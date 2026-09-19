extends Node2D

@onready var level_music = $LevelMusic
@onready var level_game_over_sound = $LevelGameOverSound
@onready var level_victory_music = $LevelVictoryMusic
@onready var level_start_timer = $LevelStartTimer
@onready var press = $Press
@onready var player = $Player
@onready var fx1 = $FxCrystalPalace
@onready var fx2 = $FxAncientRuins
@onready var message_label = $LevelCanvasLayer/MessageLabel
@onready var level_label = $LevelCanvasLayer/LevelLabel # Referência ao Label que exibe o número do nível
@onready var body_shop_button = $LevelCanvasLayer/BodyShopButton
@onready var pause_button = $LevelCanvasLayer/PauseButton
@onready var message_timer = $MessageTimer
@onready var background_sprite = $LevelBackground/BackGround # Adicione um nó Sprite2D no fundo do cenário

var level_cleared: bool = false
var is_game_over: bool = false

func _ready() -> void:
	GameManager.load_game_data()
	await get_tree().process_frame
	
	level_cleared = false

	# Exibe apenas o número do nível atual no LevelLabel
	if is_instance_valid(level_label):
		level_label.text = str(GameManager.current_level)

	# Aplica visual do tema do cenário atual
	_apply_current_theme_visuals()

	if is_instance_valid(player):
		if not player.game_over.is_connected(game_over):
			player.game_over.connect(game_over)

	if is_instance_valid(press):
		press.speed = GameManager.press_speed
		press.press_active = true

	show_level_start(GameManager.current_level)

	if is_instance_valid(level_start_timer):
		if not level_start_timer.timeout.is_connected(_on_level_start_timer_timeout):
			level_start_timer.timeout.connect(_on_level_start_timer_timeout)
			level_start_timer.start()

	if is_instance_valid(level_music):
		level_music.play()

func _apply_current_theme_visuals() -> void:
	var theme = GameManager.get_current_theme()
	
	if theme:
		# Background
		if background_sprite and theme.background_texture:
			background_sprite.texture = theme.background_texture
			
		# Prensa
		if is_instance_valid(press) and theme.press_texture:
			var press_sprite = press.find_child("PressSprite", true, false)
			if press_sprite:
				press_sprite.texture = theme.press_texture
				
		# Lançador (Player)
		if is_instance_valid(player) and theme.launcher_texture:
			var player_sprite = player.find_child("PlayerSprite", true, false)
			if player_sprite:
				player_sprite.texture = theme.launcher_texture
				
		# Música de Fundo
		if is_instance_valid(level_music) and theme.bgm_music:
			level_music.stream = theme.bgm_music

		# --- GERENCIAMENTO DE EFEITOS VISUAIS (FX) POR ID DO TEMA ---
		var active_theme_id = theme.theme_id

		# 1. Efeitos do Tema Crystal Palace ("Standart")
		if is_instance_valid(fx1):
			var is_standart = (active_theme_id == "Standart" or active_theme_id == "piercing")
			fx1.visible = is_standart
			_toggle_particles(fx1, is_standart)

		# 2. Efeitos do Tema Ancient Ruins ("120mm")
		if is_instance_valid(fx2):
			var is_ancient = (active_theme_id == "120mm" or active_theme_id == "ancient_ruins")
			fx2.visible = is_ancient
			_toggle_particles(fx2, is_ancient)

		# Nota: Se criar nós $FxHeavyMetal (piercing) ou $FxSubZero (mini_plasma) na cena, 
		# basta adicionar a mesma verificação apontando para o id correto.

func _toggle_particles(parent_node: Node, enable: bool) -> void:
	for child in parent_node.get_children():
		if child is GPUParticles2D or child is CPUParticles2D:
			child.emitting = enable
		elif child.get_child_count() > 0:
			_toggle_particles(child, enable)

func _process(_delta: float) -> void:
	if level_cleared:
		return

	var remaining_blocks = get_tree().get_nodes_in_group("blocks")
	if remaining_blocks.size() == 0 and press and press.press_active:
		complete_level()

func complete_level() -> void:
	level_cleared = true
	
	if is_instance_valid(press):
		press.press_active = false
	if is_instance_valid(level_music):
		level_music.stop()
	
	if is_instance_valid(level_victory_music):
		level_victory_music.play()
		await level_victory_music.finished
	
	GameManager.advance_to_next_level()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func show_level_start(level_number: int) -> void:
	setup_for_level()
	show_message("Level " + str(level_number) + "! Ready Go!")

func setup_for_level() -> void:
	is_game_over = false

func show_message(text: String) -> void:
	if is_instance_valid(message_label):
		message_label.text = text
		message_label.show()
	if is_instance_valid(message_timer):
		message_timer.start()

func show_game_over() -> void:
	is_game_over = true
	show_message("Game Over")

func _on_level_start_timer_timeout() -> void:
	if is_instance_valid(press):
		press.press_active = true

func _on_message_timer_timeout() -> void:
	if not is_game_over and is_instance_valid(message_label):
		message_label.hide()

func game_over() -> void:
	level_cleared = true
	if is_instance_valid(press):
		press.press_active = false
	show_game_over()

	if is_instance_valid(level_music):
		level_music.stop()
	if is_instance_valid(level_game_over_sound):
		level_game_over_sound.play()

	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")
