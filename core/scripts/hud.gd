extends CanvasLayer

var is_game_over: bool = false

@onready var HUD_color_rect = $HUDColorRect
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton

func _on_start_button_pressed() -> void:
	# Troca de cena diretamente no clique único do botão
	GameManager.reset_game_data()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")
