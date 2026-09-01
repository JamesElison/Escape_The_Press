extends Node2D

@onready var level_music = $LevelMusic
@onready var level_game_over_sound = $LevelGameOverSound
@onready var level_victory_music = $LevelVictoryMusic
@onready var level_start_timer = $LevelStartTimer
@onready var press = $Press
@onready var player = get_node("Player")
@onready var HUD = $HUD

var level_cleared: bool = false

func _ready() -> void:
	level_cleared = false

	# 1. Ajusta o speed da prensa
	if press:
		press.speed = GameManager.press_speed

	# 2. Esconde o retângulo do menu e exibe a mensagem no HUD
	if HUD and HUD.has_method("show_level_start"):
		HUD.show_level_start(GameManager.current_level)

	# 3. Inicia o timer da prensa
	if level_start_timer:
		level_start_timer.timeout.connect(_on_level_start_timer_timeout)
		level_start_timer.start()

	# 4. Toca a música da fase
	if level_music:
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

func _on_level_start_timer_timeout() -> void:
	press.press_active = true

func game_over() -> void:
	level_cleared = true
	if "press_active" in press:
		press.press_active = false
	HUD.show_game_over()
	if level_music:
		level_music.stop()
	if level_game_over_sound:
		level_game_over_sound.play()
