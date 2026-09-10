extends CanvasLayer

var is_game_over: bool = false

@onready var HUD_color_rect = $HUDColorRect
@onready var message_label = $MessageLabel
@onready var start_button = $StartButton
@onready var reset_button = $ResetButton

func _ready() -> void:
	# Conecta o botão de reset dinamicamente caso não esteja conectado pela IDE
	if is_instance_valid(reset_button):
		if not reset_button.pressed.is_connected(_on_reset_button_pressed):
			reset_button.pressed.connect(_on_reset_button_pressed)

func _on_start_button_pressed() -> void:
	# Carrega o save existente com o nível em que o jogador parou
	GameManager.load_game_data()
	get_tree().change_scene_to_file("res://core/scenes/levels/test_area.tscn")

func _on_reset_button_pressed() -> void:
	# Executa o reset nos Singletons (Dados de Jogo e Compras In-App)
	GameManager.reset_all_save_data()
	
	# Opcional: Se o Autoload do InAppManager se chamar "InAppManager"
	if Engine.has_singleton("InAppManager") or get_node_or_null("/root/InAppManager") != null:
		get_node("/root/InAppManager").reset_local_purchases()
		
	print("Save zerado com sucesso!")
