extends TextureButton

@export var body_shop_ui: Control  # Aponta para a tela de Menu
@export var theme_shop_ui: Control # Aponta para a loja de temas (BodyShop)
@export var pause_button: Control
@export var turn_left_button: Control
@export var turn_right_button: Control
@export var level_label: Control

const ALPHA_MUTED: float = 130.0 / 255.0
const ALPHA_FULL: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	self_modulate.a = ALPHA_MUTED

	if not is_instance_valid(theme_shop_ui):
		if get_parent() and get_parent().has_node("BodyShop"):
			theme_shop_ui = get_parent().get_node("BodyShop")
		elif get_node_or_null("../BodyShop") != null:
			theme_shop_ui = get_node("../BodyShop")

	if body_shop_ui:
		if not body_shop_ui.opened.is_connected(_on_shop_opened):
			body_shop_ui.opened.connect(_on_shop_opened)
		if not body_shop_ui.closed.is_connected(_on_shop_closed):
			body_shop_ui.closed.connect(_on_shop_closed)

func _on_pressed() -> void:
	# 1. Se a Loja de Temas (BodyShop) estiver aberta: fecha ela, para a música da loja e volta pro Menu
	if is_instance_valid(theme_shop_ui) and theme_shop_ui.visible:
		# Para o som interno da loja de temas caso exista um reprodutor nele
		var shop_music = theme_shop_ui.find_child("*Music*", true, false)
		if shop_music and shop_music is AudioStreamPlayer and shop_music.playing:
			shop_music.stop()
			
		theme_shop_ui.hide()
		get_tree().paused = true
		
		# Reabre o Menu Hub (que iniciará a sua própria música dentro do open())
		if is_instance_valid(body_shop_ui):
			body_shop_ui.open()
		elif get_parent() and get_parent().has_node("Menu"):
			var menu_node = get_parent().get_node("Menu")
			if menu_node.has_method("open"):
				menu_node.open()
		return

	# 2. Caso contrário, alterna a visibilidade do Menu Hub
	if is_instance_valid(body_shop_ui):
		body_shop_ui.toggle_shop()

func _on_shop_opened() -> void:
	self_modulate.a = ALPHA_FULL
	if pause_button:
		pause_button.visible = false
	if turn_left_button:
		turn_left_button.visible = false
	if turn_right_button:
		turn_right_button.visible = false
	if level_label:
		level_label.visible = false

func _on_shop_closed() -> void:
	self_modulate.a = ALPHA_MUTED
	if pause_button:
		pause_button.visible = true
		if pause_button.has_method("sync_state"):
			pause_button.sync_state()
	if turn_left_button:
		turn_left_button.visible = true
	if turn_right_button:
		turn_right_button.visible = true
	if level_label:
		level_label.visible = true
