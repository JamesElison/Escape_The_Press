extends Button

@onready var pause_button = get_parent().get_node("PauseButton")

# Caminho da cena da loja
const BODY_SHOP_SCENE = preload("res://core/scenes/set_elements/body_shop.tscn")

const ALPHA_MUTED: float = 70.0 / 255.0  # ~0.27
const ALPHA_FULL: float = 1.0            # 1.0

# Guarda a referência da instância da loja para não criar duplicadas
var body_shop_instance: Node = null

func _ready() -> void:
	# OBRIGATÓRIO: Permite que este botão continue funcionando mesmo com o jogo PAUSADO
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pressed.connect(_on_pressed)
	self_modulate.a = ALPHA_MUTED

func _on_pressed() -> void:
	var is_pausing = not get_tree().paused
	get_tree().paused = is_pausing
	
	if is_pausing:
		# Quando PAUSA: Abre a BodyShop e destaca o botão
		self_modulate.a = ALPHA_FULL
		open_body_shop()
	else:
		# Quando DESPAUSA: Fecha a BodyShop e restaura a opacidade do botão
		self_modulate.a = ALPHA_MUTED
		close_body_shop()

func open_body_shop() -> void:
	if body_shop_instance == null:
		body_shop_instance = BODY_SHOP_SCENE.instantiate()
		# Adiciona à cena atual
		get_tree().current_scene.add_child(body_shop_instance)
		pause_button.hide()

func close_body_shop() -> void:
	if body_shop_instance and is_instance_valid(body_shop_instance):
		body_shop_instance.queue_free()
		body_shop_instance = null
		pause_button.show()
