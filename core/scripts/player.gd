extends CharacterBody2D

var screen_size
var pre_ball = preload("res://core/scenes/set_elements/color_ball.tscn")

const SPEED = 1000.0

@onready var player_ball_shoot = $PlayerBallShoot
@onready var player_sprite = $PlayerSprite
@onready var player_marker = $PlayerMarker

@export var charger: Node2D

signal ball_shot(color_index: int)
signal game_over

# --- Variáveis de Controle por Toque (Android) ---
var is_touching: bool = false
var touch_target_x: float = 0.0

func _ready() -> void:
	screen_size = get_viewport_rect().size
	EventBus.launcher_changed.connect(update_launcher_sprite)
	update_launcher_sprite(GameManager.equipped_launcher)
	# Conecta ao sinal global do EventBus para atualizar em tempo real quando mudar na loja
	if not EventBus.launcher_changed.is_connected(_on_launcher_changed):
		EventBus.launcher_changed.connect(_on_launcher_changed)
	
	# Atualiza o sprite inicial de acordo com o item equipado no GameManager
	update_launcher_sprite(GameManager.equipped_launcher)

func update_launcher_sprite(launcher_id: String) -> void:
	var texture_path = ""
	
	# Mapeia cada ID para o sprite correspondente do lançador (canhão/corpo)
	match launcher_id:
		"Standart":
			texture_path = "res://core/assets/sprites/characters/player.png"
		"120mm":
			texture_path = "res://core/assets/sprites/characters/launchers_for_sale/1_120mm_type.png"
		"piercing":
			texture_path = "res://core/assets/sprites/characters/launchers_for_sale/2_piercing_type.png"
		"mini_plasma":
			texture_path = "res://core/assets/sprites/characters/launchers_for_sale/3_mini_plasma_type.png"
		_:
			texture_path = "res://core/assets/sprites/characters/default_launcher.png" # Sprite padrão

	# Se a textura existir, aplica no nó de Sprite do lançador
	if ResourceLoader.exists(texture_path):
		player_sprite.texture = load(texture_path) # Substitua $Sprite2D pelo nome exato do seu nó de sprite


func _unhandled_input(event: InputEvent) -> void:
	# Ignora eventos emulados para evitar gatilho duplo
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.is_echo():
			return

	# 1. Quando o jogador TOCA ou SOLTA a tela no Android
	if event is InputEventScreenTouch:
		if event.pressed:
			# DEDO ENCOSTOU: Ativa o toque e define o destino X imediato
			is_touching = true
			touch_target_x = event.position.x
		else:
			# DEDO SOLTOU: Dispara o tiro e encerra o movimento do toque
			if is_touching:
				is_touching = false
				processing_shoot()

	# 2. Quando o jogador DESLIZA o dedo pela tela
	elif event is InputEventScreenDrag and is_touching:
		# Atualiza a posição X de destino continuamente conforme o dedo move
		touch_target_x = event.position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movimentação via Toque no Android
	if is_touching:
		# Calcula a velocidade necessária para o move_and_slide alcançar o toque suavemente
		var target_position_x = lerp(global_position.x, touch_target_x, 25.0 * delta)
		velocity.x = (target_position_x - global_position.x) / delta
	else:
		# Movimentação via Teclado/Gamepad (PC)
		var direction := Input.get_axis("left", "right")
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Aplica o movimento da física no Godot 4
	move_and_slide()

	# Trava o Player apenas nos limites X da tela (sem afetar o eixo Y)
	global_position.x = clamp(global_position.x, 0.0, screen_size.x)

	# Disparo no PC/Teclado
	if not is_touching and Input.is_action_just_pressed("shoot"):
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			processing_shoot()

func processing_shoot():
	if player_ball_shoot:
		player_ball_shoot.play()

	EventBus.camera_shake_requested.emit(15.0, 0.15)

	var current_color = 0
	if charger and charger.has_method("get_top_ball_color"):
		current_color = charger.get_top_ball_color()
	
	var ball = pre_ball.instantiate()
	ball.color_ball = current_color
	
	get_parent().add_child(ball)
	ball.global_position = player_marker.global_position
	
	ball_shot.emit(current_color)

func die() -> void:
	game_over.emit()
	player_sprite.hide()

func _on_player_health_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("blocks"):
		print(body)
		die()
	elif body.name == "Press":
		print(body)
		die()

func _on_launcher_changed(launcher_id: String) -> void:
	update_launcher_sprite(launcher_id)
