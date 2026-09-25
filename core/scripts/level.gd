extends Node2D

const WINNER_PARTICLES_SCENE = preload("res://core/entities/effects/winner_particles.tscn")

@onready var background_sprite = $LevelBackground/BackGround
@onready var level_music = $LevelMusic
@onready var proximity_warning = $ProximityWarning
@onready var warning_piep = $WarningPiep
@onready var winner_message_marker = $WinnerMessageMarker
@onready var level_game_over_sound = $LevelGameOverSound
@onready var level_victory_fx = $LevelVictoryFXs
@onready var level_victory_music = $LevelVictoryMusic
@onready var level_start_timer = $LevelStartTimer
@onready var warning_piep_timer =$WarningPiepTimer
@onready var press = $Press
@onready var player = $Player
@onready var fx2 = $FxAncientRuins
@onready var message_label = $LevelCanvasLayer/MessageLabel
@onready var level_label = $LevelCanvasLayer/LevelLabel
@onready var body_shop_button = $LevelCanvasLayer/BodyShopButton
@onready var pause_button = $LevelCanvasLayer/PauseButton
@onready var message_timer = $MessageTimer
@onready var fog_overlay = $FogCanvas/FogOverlay
@onready var snow_fx = $SnowFX
@onready var warning_area = $WarningArea
@onready var warning_color = $WarningColor
@onready var warning_line = $WarningLine

# Nós de Áudio para o Spawn de Blocos Especiais
@onready var black_spawn = $BlackSpawn
@onready var white_spawn = $WhiteSpawn

const TARGET_WARNING_ALPHA: float = 80.0 / 255.0
const TARGET_LINE_MAX_ALPHA: float = 1.0
const TARGET_LINE_MIN_ALPHA: float = 0.2

var level_cleared: bool = false
var is_game_over: bool = false
var warning_is_on: bool = false
var warning_body_entities = []
var warning_tween: Tween
var line_tween: Tween

# Controle do Sorteio do Bloco Misterioso
var mystery_timer: Timer
var current_mystery_block: Node2D = null

# Controle do Congelamento da Prensa
var is_press_frozen: bool = false
var freeze_time_remaining: int = 0
var freeze_timer: Timer

func _ready() -> void:
	GameManager.load_game_data()
	await get_tree().process_frame
	
	level_cleared = false

	if is_instance_valid(warning_color):
		warning_color.modulate.a = 0.0
		warning_color.show()

	_start_warning_line_animation()

	if is_instance_valid(level_label):
		level_label.text = str(GameManager.current_level)

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

	_setup_mystery_system()

	# Conecta com os eventos de troca de lançador/cenário para garantir atualização limpa
	if not EventBus.launcher_changed.is_connected(_on_launcher_changed):
		EventBus.launcher_changed.connect(_on_launcher_changed)

func _on_launcher_changed(_launcher_id: String) -> void:
	_apply_current_theme_visuals()

# --- SISTEMA DE SORTEIO DO BLOCO MISTERIOSO ---
func _setup_mystery_system() -> void:
	mystery_timer = Timer.new()
	mystery_timer.wait_time = 10.0
	mystery_timer.autostart = true
	mystery_timer.one_shot = false
	mystery_timer.timeout.connect(_on_mystery_timer_timeout)
	add_child(mystery_timer)
	
	get_tree().create_timer(3.0).timeout.connect(_on_mystery_timer_timeout)

func _on_mystery_timer_timeout() -> void:
	if level_cleared or is_game_over:
		return

	if is_instance_valid(current_mystery_block) and current_mystery_block.has_method("set_mystery"):
		current_mystery_block.set_mystery(false)
		current_mystery_block = null

	var valid_blocks = _get_blocks_in_bottom_3_rows()
	if not valid_blocks.is_empty():
		current_mystery_block = valid_blocks.pick_random()
		if is_instance_valid(current_mystery_block) and current_mystery_block.has_method("set_mystery"):
			current_mystery_block.set_mystery(true)

func _get_blocks_in_bottom_3_rows() -> Array[Node2D]:
	var all_blocks = get_tree().get_nodes_in_group("blocks")
	var valid_blocks: Array[Node2D] = []

	for block in all_blocks:
		if is_instance_valid(block) and not block.get("is_being_destroyed"):
			valid_blocks.append(block)

	if valid_blocks.is_empty():
		return []

	var unique_y_positions: Array[float] = []
	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if not block_y in unique_y_positions:
			unique_y_positions.append(block_y)

	unique_y_positions.sort()
	unique_y_positions.reverse()

	var target_y_count = min(3, unique_y_positions.size())
	var bottom_3_y_levels = unique_y_positions.slice(0, target_y_count)

	var candidates: Array[Node2D] = []
	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if block_y in bottom_3_y_levels:
			candidates.append(block)

	return candidates

func trigger_mystery_reward() -> void:
	current_mystery_block = null
	var reward_type = randi() % 2
	
	if reward_type == 0:
		var charger_node = find_child("Charger", true, false)
		if charger_node and charger_node.has_method("inject_special_balls"):
			if randf() > 0.5:
				charger_node.inject_special_balls(6, 1) # 1 bola preta
			else:
				charger_node.inject_special_balls(7, 1) # 1 bola branca
	else:
		var all_blocks = get_tree().get_nodes_in_group("blocks")
		var valid_blocks: Array[Node2D] = []
		for b in all_blocks:
			if is_instance_valid(b) and not b.get("is_being_destroyed"):
				valid_blocks.append(b)
				
		if not valid_blocks.is_empty():
			var target_block = valid_blocks.pick_random()
			var is_black = randf() > 0.5
			var special_color = 6 if is_black else 7
			
			if "block_color" in target_block:
				target_block.block_color = special_color
				
			if is_black and is_instance_valid(black_spawn):
				black_spawn.play()
			elif not is_black and is_instance_valid(white_spawn):
				white_spawn.play()

# --- MÉTODOS DE CONGELAMENTO DA PRENSA (BLOCO W) ---
func freeze_press_for_duration(duration: float) -> void:
	if not is_instance_valid(press):
		return

	is_press_frozen = true
	press.press_active = false
	freeze_time_remaining = int(duration)

	if not freeze_timer:
		freeze_timer = Timer.new()
		freeze_timer.wait_time = 1.0
		freeze_timer.one_shot = false
		freeze_timer.timeout.connect(_on_freeze_timer_tick)
		add_child(freeze_timer)

	_update_freeze_ui()
	freeze_timer.start()

func _on_freeze_timer_tick() -> void:
	freeze_time_remaining -= 1
	if freeze_time_remaining <= 0:
		freeze_timer.stop()
		is_press_frozen = false
		if is_instance_valid(press) and not level_cleared and not is_game_over:
			press.press_active = true
		if is_instance_valid(message_label):
			message_label.hide()
	else:
		_update_freeze_ui()

func _update_freeze_ui() -> void:
	if is_instance_valid(message_label):
		message_label.text = str(freeze_time_remaining)
		message_label.show()

func _start_warning_line_animation() -> void:
	if not is_instance_valid(warning_line):
		return

	warning_line.show()
	warning_line.modulate.a = TARGET_LINE_MIN_ALPHA

	line_tween = create_tween().set_loops()
	line_tween.set_trans(Tween.TRANS_SINE)
	line_tween.set_ease(Tween.EASE_IN_OUT)
	line_tween.tween_property(warning_line, "modulate:a", TARGET_LINE_MAX_ALPHA, 0.6)
	line_tween.tween_property(warning_line, "modulate:a", TARGET_LINE_MIN_ALPHA, 0.6)

func _apply_current_theme_visuals() -> void:
	var theme = GameManager.get_current_theme()
	
	if theme:
		if background_sprite and theme.background_texture:
			background_sprite.texture = theme.background_texture
			
		if is_instance_valid(press) and theme.press_texture:
			var press_sprite = press.find_child("PressSprite", true, false)
			if press_sprite:
				press_sprite.texture = theme.press_texture
				
		if is_instance_valid(player) and theme.launcher_texture:
			var player_sprite = player.find_child("PlayerSprite", true, false)
			if player_sprite:
				player_sprite.texture = theme.launcher_texture
				
		if is_instance_valid(level_music) and theme.bgm_music:
			level_music.stream = theme.bgm_music

		var active_theme_id = theme.theme_id
		var is_sub_zero = (active_theme_id == "mini_plasma")

		# Partículas de Neve
		if is_instance_valid(snow_fx):
			snow_fx.visible = is_sub_zero
			if snow_fx is GPUParticles2D or snow_fx is CPUParticles2D:
				snow_fx.emitting = is_sub_zero
			else:
				_toggle_particles(snow_fx, is_sub_zero)

		# Overlay de Neblina Densa
		if is_instance_valid(fog_overlay):
			fog_overlay.visible = is_sub_zero

func set_fog_active(active: bool) -> void:
	var theme = GameManager.get_current_theme()
	var is_sub_zero = (theme and theme.theme_id == "mini_plasma")
	if is_instance_valid(fog_overlay):
		fog_overlay.visible = active and is_sub_zero

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
	if remaining_blocks.size() == 0 and press and (press.press_active or is_press_frozen):
		complete_level()

func complete_level() -> void:
	level_cleared = true
	
	if is_instance_valid(freeze_timer):
		freeze_timer.stop()
	
	if is_instance_valid(player) and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)
	
	if is_instance_valid(press):
		press.press_active = false
	if is_instance_valid(level_music):
		level_music.stop()
	
	if is_instance_valid(level_victory_fx):
		level_victory_fx.play()
		await get_tree().create_timer(1.0).timeout
		spawn_winner_particles()
		show_message("WINNER!!!")
	
	if is_instance_valid(level_victory_music):
		level_victory_music.play()
		await level_victory_music.finished
	
	GameManager.advance_to_next_level()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func spawn_winner_particles() -> void:
	if not WINNER_PARTICLES_SCENE:
		return
		
	var particle_instance = WINNER_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(particle_instance)
	
	if is_instance_valid(winner_message_marker):
		particle_instance.global_position = winner_message_marker.global_position
	
	particle_instance.z_index = 100
	
	if particle_instance.has_method("setup"):
		particle_instance.setup()

func show_level_start(level_number: int) -> void:
	setup_for_level()
	show_message("Press Speed " + str(level_number) + "! Ready Go!")

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
	if is_instance_valid(press) and not is_press_frozen:
		press.press_active = true

func _on_message_timer_timeout() -> void:
	if not is_game_over and not is_press_frozen and is_instance_valid(message_label):
		message_label.hide()

func game_over() -> void:
	level_cleared = true
	
	if is_instance_valid(freeze_timer):
		freeze_timer.stop()
	
	if is_instance_valid(player) and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)

	if is_instance_valid(press):
		press.press_active = false
	show_game_over()

	if is_instance_valid(level_music):
		level_music.stop()
	if is_instance_valid(level_game_over_sound):
		level_game_over_sound.play()

	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")

func _on_warning_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("warning_entities"):
		warning_body_entities.append(body)
		warning_state()

func _on_warning_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("warning_entities"):
		warning_body_entities.erase(body)
		warning_state()

func warning_state():
	if warning_body_entities.size() > 0:
		if not warning_is_on:
			warning_is_on = true
			warning_feedbacks()
	else:
		if warning_is_on:
			warning_is_on = false
			warning_feedbacks()

func warning_feedbacks():
	if not is_instance_valid(warning_color):
		return

	if warning_tween and warning_tween.is_running():
		warning_tween.kill()

	if warning_is_on:
		if warning_body_entities.size() < 2:
			proximity_warning.play()
		warning_piep_timer.start()
		
		warning_tween = create_tween().set_loops()
		warning_tween.set_trans(Tween.TRANS_SINE)
		warning_tween.set_ease(Tween.EASE_IN_OUT)
		
		warning_tween.tween_property(warning_color, "modulate:a", TARGET_WARNING_ALPHA, 0.5)
		warning_tween.tween_property(warning_color, "modulate:a", 0.0, 0.5)

	else:
		warning_piep_timer.stop()
		
		warning_tween = create_tween()
		warning_tween.set_trans(Tween.TRANS_SINE)
		warning_tween.set_ease(Tween.EASE_OUT)
		warning_tween.tween_property(warning_color, "modulate:a", 0.0, 0.3)

func _on_warning_piep_timer_timeout() -> void:
	if warning_piep:
		warning_piep.play()

# --- INTEGRAÇÃO COM O BODY SHOP / PAUSE ---
func _on_body_shop_button_pressed() -> void:
	set_fog_active(false)

func _on_body_shop_closed() -> void:
	set_fog_active(true)
