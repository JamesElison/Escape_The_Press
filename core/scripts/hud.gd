extends CanvasLayer

var press_node
var level_music
var is_game_over: bool = false

@onready var HUD_color_rect = $HUDColorRect
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton
@onready var message_timer = $MessageTimer

func _ready() -> void:
	if get_parent().has_node("Press"):
		press_node = get_parent().get_node("Press")
	if get_parent().has_node("LevelMusic"):
		level_music = get_parent().get_node("LevelMusic")

# Prepara a tela quando está dentro da fase (esconde o menu inicial)
func setup_for_level() -> void:
	is_game_over = false
	HUD_color_rect.hide()
	start_button.hide()
	message_label.hide()

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	message_timer.start()

func show_level_start(level_number: int) -> void:
	setup_for_level()
	show_message("Level " + str(level_number) + "! Ready Go!")

func show_game_over() -> void:
	is_game_over = true
	show_message("Game Over")
	await message_timer.timeout
	
	HUD_color_rect.show()
	message_label.text = "Escape The Press!"
	message_label.show()
	await get_tree().create_timer(1.0).timeout
	start_button.show()

func _on_start_button_pressed() -> void:
	# Troca de cena diretamente no clique único do botão
	GameManager.reset_game_data()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func _on_mensage_timer_timeout() -> void:
	message_label.hide()
