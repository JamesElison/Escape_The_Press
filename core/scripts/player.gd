extends CharacterBody2D

var screen_size
var pre_ball = preload("res://core/scenes/set_elements/color_ball.tscn")

@onready var player_jet_right = $PlayerJetRight
@onready var player_jet_left = $PlayerJetLeft

const SPEED = 1000.0

# Configurações de Rotação do Lançador
@export var rotation_speed: float = 0.1 # Velocidade suave de rotação (rad/s)
@export var max_rotation_degrees: float = 75.0 # Limite máximo de rotação para esquerda/direita

# Cores equivalentes às bolas do jogo [Red, Green, Blue, Cyan, Magenta, Yellow]
const BALL_COLORS: Array[Color] = [
	Color(0.95, 0.2, 0.2),   # 0: Red
	Color(0.2, 0.9, 0.3),   # 1: Green
	Color(0.2, 0.4, 0.95),  # 2: Blue
	Color(0.1, 0.85, 0.95), # 3: Cyan
	Color(0.9, 0.25, 0.85), # 4: Magenta
	Color(0.95, 0.85, 0.1)  # 5: Yellow
]

@onready var player_ball_shoot = $PlayerBallShoot
@onready var player_sprite = $PlayerSprite
@onready var player_marker = $PlayerMarker
# Nós para o Laser
@onready var laser_ray_cast: RayCast2D = $LaserRayCast
@onready var laser_line: Line2D = $LaserLine
@export var charger: Node2D

signal ball_shot(color_index: int)
signal game_over

# --- Variáveis de Controle por Toque / Drag ---
var is_touching: bool = false
var touch_target_x: float = 0.0
var color_tween: Tween

func _ready() -> void:
	add_to_group("player") # Garante o pertencimento ao grupo do player
	screen_size = get_viewport_rect().size
	touch_target_x = global_position.x
	
	if not EventBus.launcher_changed.is_connected(_on_launcher_changed):
		EventBus.launcher_changed.connect(_on_launcher_changed)
	
	if is_instance_valid(charger):
		if charger.has_signal("top_color_changed"):
			if not charger.top_color_changed.is_connected(_on_top_color_changed):
				charger.top_color_changed.connect(_on_top_color_changed)
		
		if charger.has_method("get_top_ball_color"):
			_on_top_color_changed(charger.get_top_ball_color())
	
	update_launcher_sprite()
	update_jets_visibility()

# --- MÉTODOS DE ROTAÇÃO SUAVE ---
func rotate_left(delta: float) -> void:
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation = clamp(rotation - rotation_speed * delta, -max_rad, max_rad)

func rotate_right(delta: float) -> void:
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation = clamp(rotation + rotation_speed * delta, -max_rad, max_rad)

func reset_rotation() -> void:
	rotation = 0.0

# --- LÓGICA DO LASER COM REFLEXÃO EM ESPELHO (SEM JITTER) ---
func update_laser() -> void:
	if not is_instance_valid(laser_line):
		return

	laser_line.clear_points()
	
	# Ponto inicial do laser em coordenadas globais
	var current_origin = player_marker.global_position if is_instance_valid(player_marker) else global_position
	var current_dir = Vector2.UP.rotated(global_rotation)
	
	# O primeiro ponto é a origem do próprio Line2D/Marker (no espaço local)
	if is_instance_valid(player_marker) and laser_line.get_parent() == player_marker:
		laser_line.add_point(Vector2.ZERO)
	else:
		laser_line.add_point(laser_line.to_local(current_origin))

	var max_reflections = 5
	var space_state = get_world_2d().direct_space_state

	for i in range(max_reflections):
		var ray_target = current_origin + current_dir * 2000.0
		
		var query = PhysicsRayQueryParameters2D.create(current_origin, ray_target)
		query.exclude = [self.get_rid()]
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		if is_instance_valid(laser_ray_cast):
			query.collision_mask = laser_ray_cast.collision_mask
		
		var result = space_state.intersect_ray(query)
		
		if result:
			var hit_point: Vector2 = result.position
			var hit_normal: Vector2 = result.normal
			
			laser_line.add_point(laser_line.to_local(hit_point))
			
			current_dir = current_dir.bounce(hit_normal).normalized()
			current_origin = hit_point + current_dir * 1.5
			
			var collider = result.collider
			if collider.is_in_group("blocks") or collider.name == "Press":
				break
		else:
			laser_line.add_point(laser_line.to_local(ray_target))
			break

func _on_top_color_changed(color_idx: int) -> void:
	if not is_instance_valid(laser_line):
		return

	var valid_idx = clamp(color_idx, 0, BALL_COLORS.size() - 1)
	var target_color = BALL_COLORS[valid_idx]

	if color_tween and color_tween.is_running():
		color_tween.kill()

	color_tween = create_tween()

	if laser_line.gradient:
		color_tween.tween_method(
			func(c: Color): laser_line.gradient.set_color(0, c),
			laser_line.gradient.get_color(0),
			target_color,
			0.15
		)
	else:
		color_tween.tween_property(laser_line, "default_color", target_color, 0.15)

func update_launcher_sprite(_launcher_id: String = "") -> void:
	var theme = GameManager.get_current_theme()
	if theme and theme.launcher_texture:
		player_sprite.texture = theme.launcher_texture

func _unhandled_input(event: InputEvent) -> void:
	# Mouse / Touch - Arrastar para mover no X e Soltar para Disparar
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_touching = true
				touch_target_x = event.position.x
			else:
				if is_touching:
					is_touching = false
					processing_shoot()

	elif event is InputEventMouseMotion and is_touching:
		touch_target_x = event.position.x

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_touching = true
			touch_target_x = event.position.x
		else:
			if is_touching:
				is_touching = false
				processing_shoot()

	elif event is InputEventScreenDrag and is_touching:
		touch_target_x = event.position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movimentação Teclado (PC) ou Toque (Android)
	var keyboard_dir := Input.get_axis("left", "right")
	
	if keyboard_dir != 0.0:
		velocity.x = keyboard_dir * SPEED
		touch_target_x = global_position.x
	elif is_touching:
		var diff = touch_target_x - global_position.x
		if abs(diff) > 10.0:
			velocity.x = sign(diff) * SPEED
		else:
			velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Atalhos de rotação por teclado (Q/E ou Botões Turn)
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	if turn_dir != 0.0:
		if turn_dir < 0:
			rotate_left(delta)
		else:
			rotate_right(delta)
	elif Input.is_action_pressed("ui_left_rotate") or Input.is_key_pressed(KEY_Q):
		rotate_left(delta)
	elif Input.is_action_pressed("ui_right_rotate") or Input.is_key_pressed(KEY_E):
		rotate_right(delta)

	move_and_slide()

	# Atualiza a visibilidade dos jatos propulsores baseando-se no movimento real
	update_jets_visibility()

	# Garante que o player fique dentro dos limites da tela
	global_position.x = clamp(global_position.x, 0.0, screen_size.x)

	# Atualiza o feixe de laser de forma síncrona
	update_laser()

	# Disparo por Teclado / Espaço (PC)
	if not is_touching and Input.is_action_just_pressed("shoot"):
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			processing_shoot()

func update_jets_visibility() -> void:
	if is_instance_valid(player_jet_right):
		player_jet_right.visible = (velocity.x > 5.0)

	if is_instance_valid(player_jet_left):
		player_jet_left.visible = (velocity.x < -5.0)

func processing_shoot():
	if player_ball_shoot:
		player_ball_shoot.play()

	EventBus.camera_shake_requested.emit(15.0, 0.15)

	var current_color = 0
	if is_instance_valid(charger) and charger.has_method("pop_top_ball_color"):
		current_color = charger.pop_top_ball_color()
	elif charger and charger.has_method("get_top_ball_color"):
		current_color = charger.get_top_ball_color()
	
	var ball = pre_ball.instantiate()
	ball.color_ball = current_color
	
	get_parent().add_child(ball)
	ball.global_position = player_marker.global_position
	
	# Passa a direção do tiro e a rotação alinhada com o lançador
	ball.dir = Vector2.UP.rotated(global_rotation)
	ball.rotation = global_rotation
	
	ball_shot.emit(current_color)
	
	# Reseta o canhão de volta para a posição apontando para cima (0 rad) ao disparar
	reset_rotation()

func die() -> void:
	game_over.emit()
	player_sprite.hide()
	if is_instance_valid(player_jet_right):
		player_jet_right.hide()
	if is_instance_valid(player_jet_left):
		player_jet_left.hide()
	if is_instance_valid(laser_line):
		laser_line.hide()

func _on_player_health_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("blocks"):
		die()
	elif body.name == "Press":
		die()

func _on_launcher_changed(launcher_id: String) -> void:
	update_launcher_sprite(launcher_id)
