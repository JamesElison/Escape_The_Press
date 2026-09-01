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
	# Inicia o timer para ativar a prensa
	if level_start_timer:
		level_start_timer.timeout.connect(_on_level_start_timer_timeout)
		level_start_timer.start()

func _process(_delta: float) -> void:
	if level_cleared:
		return

	# Verifica se não restam blocos no grupo "blocks"
	var remaining_blocks = get_tree().get_nodes_in_group("blocks")
	if remaining_blocks.size() == 0 and press.press_active:
		complete_level()

func complete_level() -> void:
	level_cleared = true
	
	# 1. Para a prensa e a música do nível
	press.press_active = false
	level_music.stop()
	
	# 2. Toca a música de vitória (0.04s)
	if level_victory_music:
		level_victory_music.play()
		await level_victory_music.finished
	
	# 3. Atualiza os dados no GameManager (level += 1 e speed += 2.0)
	GameManager.advance_to_next_level()
	
	# 4. Recarrega a cena limpa
	get_tree().reload_current_scene()

func _on_level_start_timer_timeout() -> void:
	press.press_active = true

func game_over() -> void:
	level_cleared = true
	if "press_active" in press:
		press.press_active = false
	HUD.show_game_over()
	level_music.stop()
	level_game_over_sound.play()
	
	# Opcional: Se quiser resetar a velocidade e o level quando der Game Over total:
	 #GameManager.reset_game_data()
