extends CanvasLayer

var is_game_over: bool = false

@onready var HUD_color_rect = $HUDColorRect
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton

func _on_start_button_pressed() -> void:
	# Carrega o save existente com o nível em que o jogador parou
	GameManager.load_game_data()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")
