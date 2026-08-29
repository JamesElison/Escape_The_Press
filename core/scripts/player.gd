extends CharacterBody2D

var screen_size
var pre_ball = preload("res://core/scenes/set_elements/color_ball.tscn")

const SPEED = 1000.0

@onready var player_marker = $PlayerMarker
# Referência para o nó do carregador (ajuste o caminho se necessário)
@export var charger: Node2D

# Atualização da declaração para enviar o número/índice da cor
signal ball_shot(color_index: int)
signal game_over

# --- Variáveis de Controle por Toque (Android) ---
var is_touching: bool = false
var touch_start_x: float = 0.0
var player_start_x: float = 0.0
var touch_drag_x: float = 0.0

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _unhandled_input(event: InputEvent) -> void:
	# Ignore eventos emulados de mouse gerados pelo toque para não dar duplo gatilho
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.is_echo():
			return

	# 1. Quando o jogador TOCA ou SOLTA a tela no Android
	if event is InputEventScreenTouch:
		if event.pressed:
			# DEDO ENCOSTOU: Apenas marca o início do arrasto (NÃO ATIRA AQUI)
			is_touching = true
			touch_start_x = event.position.x
			player_start_x = global_position.x
			touch_drag_x = event.position.x
		else:
			# DEDO SOLTOU: Dispara o tiro e reseta o controle do toque
			if is_touching:
				is_touching = false
				processing_shoot()

	# 2. Quando o jogador DESLIZA o dedo na tela
	elif event is InputEventScreenDrag and is_touching:
		touch_drag_x = event.position.x

func _physics_process(delta: float) -> void:
	# Aplica a gravidade se necessário
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movimentação via Toque no Android
	if is_touching:
		var swipe_offset = touch_drag_x - touch_start_x
		var target_x = player_start_x + swipe_offset
		global_position.x = lerp(global_position.x, target_x, 25.0 * delta)
	else:
		# Movimentação via Teclado/Gamepad (Para testes no PC)
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	position = position.clamp(Vector2.ZERO, screen_size)

	move_and_slide()
	
	# Disparo no PC/Teclado apenas se não estiver jogando por toque no Android
	if not is_touching and Input.is_action_just_pressed("shoot"):
		# Garante que não foi um clique vindo de toque
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			processing_shoot()

func processing_shoot():
	# 1. Pega o número da cor que está no topo do carregador (Marker 6)
	var current_color = 0
	if charger and charger.has_method("get_top_ball_color"):
		current_color = charger.get_top_ball_color()
	
	# 2. Instancia a nova bola
	var ball = pre_ball.instantiate()
	
	# 3. Aplica a cor do topo na bola ANTES de colocar no mundo
	ball.color_ball = current_color
	
	# 4. Adiciona à cena e posiciona no canhão
	get_parent().add_child(ball)
	ball.global_position = player_marker.global_position
	
	# 5. Notifica o carregador passando a cor disparada
	ball_shot.emit(current_color)

func die() -> void:
	print("GAME OVER - O jogador foi esmagado!")
	game_over.emit()
	queue_free()

func _on_player_health_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.name.begins_with("Block"):
		print(body)
		die()
	elif body.name == "Press":
		print(body)
		die()
