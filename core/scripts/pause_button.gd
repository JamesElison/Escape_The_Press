extends TextureButton

@export var pause_texture: Texture2D
@export var play_texture: Texture2D

const ALPHA_MUTED: float = 70.0 / 255.0  # ~0.27 (despausado)
const ALPHA_FULL: float = 1.0            # 1.0 (pausado)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	sync_state()

func _on_pressed() -> void:
	var next_pause_state = not get_tree().paused
	get_tree().paused = next_pause_state
	set_paused_state(next_pause_state)

## Atualiza visualmente o botão (textura e transparência) com base no estado desejado
func set_paused_state(is_pausing: bool) -> void:
	if is_pausing:
		self_modulate.a = ALPHA_FULL
		if play_texture:
			texture_normal = play_texture
	else:
		self_modulate.a = ALPHA_MUTED
		if pause_texture:
			texture_normal = pause_texture

## Força o botão a sincronizar seu visual diretamente com o estado real de pausa da árvore (get_tree().paused)
func sync_state() -> void:
	set_paused_state(get_tree().paused)
