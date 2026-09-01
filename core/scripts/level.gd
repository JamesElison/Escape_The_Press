extends Node2D

@onready var level_music = $LevelMusic
@onready var level_game_over_sound = $LevelGameOverSound
@onready var level_victory_music = $LevelVictoryMusic
@onready var level_start_timer = $LevelStartTimer
@onready var press = $Press
@onready var player = $Player
@onready var level_color_rect = $LevelColorRect
@onready var message_label = $LevelCanvasLayer/MessageLabel
@onready var pause_button = $LevelCanvasLayer/PauseButton
@onready var message_timer = $MessageTimer

var level_cleared: bool = false
var is_game_over: bool = false

func _ready() -> void:
	# Aguarda a árvore estabilizar a montagem de todos os nós filhos
	await get_tree().process_frame
	
	level_cleared = false

	# Conecta o sinal game_over do Player dinamicamente
	if is_instance_valid(player):
		if not player.game_over.is_connected(game_over):
			player.game_over.connect(game_over)

	# 1. Ajusta o speed da prensa
	if is_instance_valid(press):
		press.speed = GameManager.press_speed
		press.press_active = true

	# 2. Exibe mensagem de início
	show_level_start(GameManager.current_level)

	# 3. Timer
	if is_instance_valid(level_start_timer):
		if not level_start_timer.timeout.is_connected(_on_level_start_timer_timeout):
			level_start_timer.timeout.connect(_on_level_start_timer_timeout)
			level_start_timer.start()

	# 4. Música
	if is_instance_valid(level_music):
		level_music.play()

func _process(_delta: float) -> void:
	if level_cleared:
		return

	# Checa se todos os blocos foram destruídos
	var remaining_blocks = get_tree().get_nodes_in_group("blocks")
	if remaining_blocks.size() == 0 and press.press_active:
		complete_level()

func complete_level() -> void:
	level_cleared = true
	
	press.press_active = false
	if level_music:
		level_music.stop()
	
	if level_victory_music:
		level_victory_music.play()
		await level_victory_music.finished
	
	# Incrementa dados no GameManager
	GameManager.advance_to_next_level()
	
	# Troca direto para a cena do nível
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func show_level_start(level_number: int) -> void:
	setup_for_level()
	show_message("Level " + str(level_number) + "! Ready Go!")

func setup_for_level() -> void:
	is_game_over = false

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	message_timer.start()

func show_game_over() -> void:
	is_game_over = true
	show_message("Game Over")

func _on_level_start_timer_timeout() -> void:
	press.press_active = true

func _on_message_timer_timeout() -> void:
	if not is_game_over:
		message_label.hide()

func game_over() -> void:
	level_cleared = true
	
	# Para a prensa imediatamente
	if is_instance_valid(press):
		press.press_active = false
	
	# Dispara a animação/fluxo de Game Over no HUD
	show_game_over()
	
	if is_instance_valid(level_music):
		level_music.stop()
		
	if is_instance_valid(level_game_over_sound):
		level_game_over_sound.play()
	
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://core/scenes/set_elements/main_menu.tscn")
	
