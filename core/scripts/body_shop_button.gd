extends TextureButton

@export var body_shop_ui: Control
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

	if body_shop_ui:
		if not body_shop_ui.opened.is_connected(_on_shop_opened):
			body_shop_ui.opened.connect(_on_shop_opened)
		if not body_shop_ui.closed.is_connected(_on_shop_closed):
			body_shop_ui.closed.connect(_on_shop_closed)

func _on_pressed() -> void:
	if body_shop_ui:
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
		# Sincroniza o texto e opacidade do PauseButton com a árvore de cena
		if pause_button.has_method("sync_state"):
			pause_button.sync_state()
	if turn_left_button:
		turn_left_button.visible = true
	if turn_right_button:
		turn_right_button.visible = true
	if level_label:
		level_label.visible = true
