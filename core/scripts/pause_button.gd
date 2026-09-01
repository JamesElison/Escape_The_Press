extends Button

# Opção A: Se você alterou o Alpha (Transparência)
# 70/255 equivale a ~0.27 de alpha. 255 equivale a 1.0.
const ALPHA_MUTED: float = 70.0 / 255.0  # ~0.27
const ALPHA_FULL: float = 1.0            # 255/255

func _ready() -> void:
	pressed.connect(_on_pressed)
	# Define a opacidade inicial reduzida
	self_modulate.a = ALPHA_MUTED

func _on_pressed() -> void:
	var is_pausing = not get_tree().paused
	get_tree().paused = is_pausing
	
	if is_pausing:
		# Quando PAUSA: Volta ao brilho/opacidade total (255 / 1.0)
		self_modulate.a = ALPHA_FULL
		text = "Play"
	else:
		# Quando DESPAUSA: Volta para a opacidade reduzida (70 / ~0.27)
		self_modulate.a = ALPHA_MUTED
		text = "Pause"
