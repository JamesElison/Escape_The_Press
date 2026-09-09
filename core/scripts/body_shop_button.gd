extends Button

@export var body_shop_ui: Control
@export var pause_button: Control

const ALPHA_MUTED: float = 70.0 / 255.0
const ALPHA_FULL: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	self_modulate.a = ALPHA_MUTED

func _on_pressed() -> void:
	if body_shop_ui:
		body_shop_ui.toggle_shop()
		
		var is_open = body_shop_ui.visible
		self_modulate.a = ALPHA_FULL if is_open else ALPHA_MUTED
		
		# Oculta/Exibe o PauseButton com base no estado da loja
		if pause_button:
			pause_button.visible = not is_open
