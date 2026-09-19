extends CanvasLayer

var is_game_over: bool = false

@onready var main_menu_music = $MainMenuMusic
@onready var start_button_sound = $StartButtonSound
@onready var message_label2 = $MessageLabel2
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton
@onready var reset_button = $ResetButton

func _ready() -> void:
	if main_menu_music:
		main_menu_music.play()
	
	if is_instance_valid(reset_button):
		if not reset_button.pressed.is_connected(_on_reset_button_pressed):
			reset_button.pressed.connect(_on_reset_button_pressed)

func _on_start_button_pressed() -> void:
	# 1. Desativa o botão (como start_button_2.png está no campo Disabled, ele vai manter o visual pressionado)
	start_button.disabled = true

	# 2. Áudio e transição
	if main_menu_music:
		main_menu_music.stop()
	
	if start_button_sound and start_button_sound.stream:
		GameManager.play_sfx_persistent(start_button_sound.stream)

	# 3. Dá tempo do motor renderizar o frame com a textura trocada antes de trocar a cena
	await get_tree().process_frame
	await get_tree().process_frame

	GameManager.load_game_data()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func _on_reset_button_pressed() -> void:
	GameManager.reset_all_save_data()
	
	if Engine.has_singleton("InAppManager") or get_node_or_null("/root/InAppManager") != null:
		get_node("/root/InAppManager").reset_local_purchases()
		
	print("Save zerado com sucesso!")
