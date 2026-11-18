extends Node2D

var is_game_over: bool = false

@onready var main_menu_music = $HUD/MainMenuMusic
@onready var start_button_sound = $HUD/StartButtonSound
@onready var menu_button_sound = $HUD/MenuButtonSound
@onready var attract_timer: Timer = $HUD/AttractTimer
@onready var message_label2 = $HUD/MessageLabel2
@onready var message_label = $HUD/MessageLabel
@onready var start_button = $HUD/StartButton
@onready var hud_fade_fx = $HUD/HUDFadeFX
@onready var hud_fade_anim = $HUD/HUDFadeAnim

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if hud_fade_anim:
		hud_fade_anim.play("fade_in")
	if main_menu_music:
		main_menu_music.play()
	if is_instance_valid(attract_timer):
		attract_timer.timeout.connect(_on_attract_timer_timeout)

func _input(event: InputEvent) -> void:
	# Sempre que o jogador tocar na tela, reinicia a contagem de 15 segundos
	if event.is_pressed() and is_instance_valid(attract_timer):
		attract_timer.start()

func _on_attract_timer_timeout() -> void:
	GameManager.is_attract_mode = true
	# Carrega a cena da partida diretamente!
	get_tree().change_scene_to_file("res://core/scenes/levels/game_play_area.tscn")

func _on_start_button_pressed() -> void:
	# 1. Desativa o botão (como start_button_2.png está no campo Disabled, ele vai manter o visual pressionado)
	start_button.disabled = true
	
	if start_button_sound and start_button_sound.stream:
		#GameManager.play_sfx_persistent(start_button_sound.stream)
		start_button_sound.play()

	# 3. Dá tempo do motor renderizar o frame com a textura trocada antes de trocar a cena
	AudioManager.stop_with_fade_out(main_menu_music, 3.0)
	await start_button_sound.finished

	GameManager.load_game_data()
	if hud_fade_anim:
		hud_fade_anim.play("fade_out")
	await hud_fade_anim.animation_finished
	get_tree().change_scene_to_file("res://core/scenes/levels/card.tscn")
