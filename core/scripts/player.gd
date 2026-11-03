extends CharacterBody2D

var screen_size
var pre_ball = preload("res://core/scenes/set_elements/color_ball.tscn")

@onready var player_jet_right = $PlayerJetRight
@onready var player_jet_left = $PlayerJetLeft
@onready var player_shoot_anim = $PlayerShootAnim

# Nós do Lança-Chamas (Option 1)
@onready var flame_cast: RayCast2D = $SpecialProjectiles/FlameCast
@onready var flame_line: Line2D = $SpecialProjectiles/FlameLine

const SPEED = 1000.0

@export var rotation_speed: float = 0.1
@export var max_rotation_degrees: float = 75.0
@export var shoot_cooldown: float = 0.9 # Tempo mínimo entre um tiro e outro (trava anti-rajada)

const BALL_COLORS: Array[Color] = [
	Color(0.95, 0.2, 0.2),   # 0: Red
	Color(0.2, 0.9, 0.3),   # 1: Green
	Color(0.2, 0.4, 0.95),  # 2: Blue
	Color(0.95, 0.95, 0.95), # 3: White
	Color(0.1, 0.85, 0.95), # 4: Cyan
	Color(0.9, 0.25, 0.85), # 5: Magenta
	Color(0.95, 0.85, 0.1), # 6: Yellow
	Color(0.15, 0.15, 0.15) # 7: Black
]

# Cores correspondentes para as partículas de fogo (8 cores)
const FLAME_COLORS = {
	0: Color(0.95, 0.2, 0.2),   # Red
	1: Color(0.2, 0.9, 0.3),   # Green
	2: Color(0.2, 0.4, 0.95),  # Blue
	3: Color(0.95, 0.95, 0.95), # White
	4: Color(0.1, 0.85, 0.95), # Cyan
	5: Color(0.9, 0.25, 0.85), # Magenta
	6: Color(0.95, 0.85, 0.1), # Yellow
	7: Color(0.15, 0.15, 0.15) # Black
}

@onready var player_ball_shoot = $PlayerBallShoot
@onready var player_sprite = $PlayerSprite
@onready var player_marker = $PlayerMarker
@onready var laser_ray_cast: RayCast2D = $LaserRayCast
@onready var laser_line: Line2D = $LaserLine
@export var charger: Node2D

signal ball_shot(color_index: int)
signal game_over

var is_touching: bool = false
var touch_target_x: float = 0.0
var color_tween: Tween

var is_control_enabled: bool = true
var can_shoot: bool = true

# Controle do estado do lança-chamas
var is_flame_active: bool = false
var flame_tween: Tween

func _ready() -> void:
	add_to_group("player")
	screen_size = get_viewport_rect().size
	touch_target_x = global_position.x
	is_control_enabled = true
	
	if is_instance_valid(flame_cast):
		flame_cast.enabled = false

	if not EventBus.launcher_changed.is_connected(_on_launcher_changed):
		EventBus.launcher_changed.connect(_on_launcher_changed)
	
	if is_instance_valid(charger):
		if charger.has_signal("top_color_changed"):
			if not charger.top_color_changed.is_connected(_on_top_color_changed):
				charger.top_color_changed.connect(_on_top_color_changed)
		
		if charger.has_method("get_top_ball_color"):
			_on_top_color_changed(charger.get_top_ball_color())
	
	update_launcher_sprite()

func set_controls_enabled(enabled: bool) -> void:
	is_control_enabled = enabled
	
	if not enabled:
		velocity = Vector2.ZERO
		is_touching = false
		stop_flame()
		if is_instance_valid(laser_line):
			laser_line.clear_points()

func rotate_left(delta: float) -> void:
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation = clamp(rotation - rotation_speed * delta, -max_rad, max_rad)

func rotate_right(delta: float) -> void:
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation = clamp(rotation + rotation_speed * delta, -max_rad, max_rad)

func reset_rotation() -> void:
	rotation = 0.0

func update_laser() -> void:
	if not is_instance_valid(laser_line):
		return

	laser_line.clear_points()
	
	var current_origin = player_marker.global_position if is_instance_valid(player_marker) else global_position
	var current_dir = Vector2.UP.rotated(global_rotation)
	
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

func update_flame_beam(color_idx: int) -> void:
	if not is_instance_valid(flame_line):
		return

	flame_line.clear_points()
	
	var current_origin = player_marker.global_position if is_instance_valid(player_marker) else global_position
	var current_dir = Vector2.UP.rotated(global_rotation)
	
	if is_instance_valid(player_marker) and flame_line.get_parent() == player_marker:
		flame_line.add_point(Vector2.ZERO)
	else:
		flame_line.add_point(flame_line.to_local(current_origin))

	var max_reflections = 3
	var space_state = get_world_2d().direct_space_state

	for i in range(max_reflections):
		var ray_target = current_origin + current_dir * 2000.0
		
		var query = PhysicsRayQueryParameters2D.create(current_origin, ray_target)
		query.exclude = [self.get_rid()]
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		if is_instance_valid(flame_cast):
			query.collision_mask = flame_cast.collision_mask
		
		var result = space_state.intersect_ray(query)
		
		if result:
			var hit_point: Vector2 = result.position
			var hit_normal: Vector2 = result.normal
			
			flame_line.add_point(flame_line.to_local(hit_point))
			
			current_dir = current_dir.bounce(hit_normal).normalized()
			current_origin = hit_point + current_dir * 1.5
			
			var collider = result.collider
			if collider and (collider.is_in_group("blocks") or collider.name == "Press"):
				break
		else:
			flame_line.add_point(flame_line.to_local(ray_target))
			break

func start_flame(color_idx: int) -> void:
	is_flame_active = true
	
	# Oculta o Laser padrão enquanto a chama estiver ativa
	if is_instance_valid(laser_line):
		laser_line.hide()
		laser_line.clear_points()
	
	if is_instance_valid(flame_cast):
		flame_cast.enabled = true
		
	if is_instance_valid(flame_line):
		flame_line.show()
		
		var launcher_theme = GameManager.get_current_launcher_theme()
		if launcher_theme and launcher_theme.is_flamethrower and launcher_theme.flame_texture:
			flame_line.texture = launcher_theme.flame_texture
		
		var valid_idx = clamp(color_idx, 0, BALL_COLORS.size() - 1)
		if FLAME_COLORS.has(valid_idx):
			flame_line.default_color = FLAME_COLORS[valid_idx]
			
		# Animação segura de inversão horizontal (piscar/tremeluzir)
		if flame_tween and flame_tween.is_running():
			flame_tween.kill()
			
		flame_line.scale.x = 1.0 
		flame_tween = create_tween().set_loops(5)
		flame_tween.tween_property(flame_line, "scale:x", -1.0, 0.10)
		flame_tween.tween_property(flame_line, "scale:x", 1.0, 0.10)

func stop_flame() -> void:
	is_flame_active = false
	
	if flame_tween and flame_tween.is_running():
		flame_tween.kill()
	if is_instance_valid(flame_line):
		flame_line.scale.x = 1.0
		
	if is_instance_valid(flame_cast):
		flame_cast.enabled = false
	if is_instance_valid(flame_line):
		flame_line.hide()
		flame_line.clear_points()
		
	# Restaura a visibilidade do Laser quando o fogo acaba
	if is_instance_valid(laser_line):
		laser_line.show()


func _on_top_color_changed(color_idx: int) -> void:
	if is_instance_valid(laser_line):
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
			
	if is_flame_active:
		start_flame(color_idx)

func update_launcher_sprite(_launcher_id: String = "") -> void:
	var launcher_theme = GameManager.get_current_launcher_theme()
	if launcher_theme and launcher_theme.launcher_texture:
		player_sprite.texture = launcher_theme.launcher_texture

func _unhandled_input(event: InputEvent) -> void:
	if not is_control_enabled:
		return

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
	if not is_control_enabled:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

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

	global_position.x = clamp(global_position.x, 0.0, screen_size.x)

	# Atualiza o laser apenas se o lança-chamas estiver desligado
	if not is_flame_active:
		update_laser()
	
	if is_flame_active:
		var current_color = charger.get_top_ball_color() if is_instance_valid(charger) else 0
		update_flame_beam(current_color)

	if not is_touching and Input.is_action_just_pressed("shoot"):
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			processing_shoot()


func processing_shoot() -> void:
	if not can_shoot:
		return

	var launcher_theme = GameManager.get_current_launcher_theme()
	
	# --- COMPORTAMENTO ESPECÍFICO PARA LANÇA-CHAMAS ---
	if launcher_theme and launcher_theme.is_flamethrower:
		can_shoot = false
		
		if is_instance_valid(player_ball_shoot) and launcher_theme.hit_sound:
			player_ball_shoot.stream = launcher_theme.hit_sound
			player_ball_shoot.play()

		EventBus.camera_shake_requested.emit(30.0, 0.15)

		var current_color = 0
		if is_instance_valid(charger) and charger.has_method("pop_top_ball_color"):
			current_color = charger.pop_top_ball_color()
		elif charger and charger.has_method("get_top_ball_color"):
			current_color = charger.get_top_ball_color()

		ball_shot.emit(current_color)

		start_flame(current_color)
		
		var space_state = get_world_2d().direct_space_state
		var current_origin = player_marker.global_position if is_instance_valid(player_marker) else global_position
		var current_dir = Vector2.UP.rotated(global_rotation)
		var final_collider = null
		var last_hit_position = Vector2.ZERO
		
		var max_reflections = 3
		for i in range(max_reflections):
			var ray_target = current_origin + current_dir * 2000.0
			var query = PhysicsRayQueryParameters2D.create(current_origin, ray_target)
			query.exclude = [self.get_rid()]
			query.collide_with_bodies = true
			query.collide_with_areas = true
			if is_instance_valid(flame_cast):
				query.collision_mask = flame_cast.collision_mask
			
			var result = space_state.intersect_ray(query)
			if result:
				var hit_point: Vector2 = result.position
				var hit_normal: Vector2 = result.normal
				var collider = result.collider
				last_hit_position = hit_point
				
				if collider and collider.is_in_group("blocks"):
					final_collider = collider
					break
				elif collider and collider.name == "Press":
					final_collider = collider
					break
				else:
					current_dir = current_dir.bounce(hit_normal).normalized()
					current_origin = hit_point + current_dir * 1.5
			else:
				break

		if is_instance_valid(final_collider):
			if final_collider.name == "Press":
				spawn_block_on_press_flame(final_collider, last_hit_position, current_color)
				if "press_hit" in final_collider:
					final_collider.press_hit()
			
			elif final_collider.is_in_group("blocks") and "block_color" in final_collider:
				if final_collider.get("is_mystery_active") == true:
					final_collider.set_mystery(false)
					var level_node = get_tree().current_scene
					if level_node and level_node.has_method("trigger_mystery_reward"):
						level_node.trigger_mystery_reward()
				
				var b_color = final_collider.block_color
				
				if current_color == 3 or b_color == 3:
					var level_node = get_tree().current_scene
					if level_node and level_node.has_method("freeze_press_for_duration"):
						level_node.freeze_press_for_duration(10.0)
					if final_collider.has_method("destroy_with_delay"):
						final_collider.destroy_with_delay()
					else:
						final_collider.queue_free()
				
				elif current_color == 7:
					if b_color >= 0 and b_color <= 6 and b_color != 3:
						var all_blocks = get_tree().get_nodes_in_group("blocks")
						for blk in all_blocks:
							if is_instance_valid(blk) and "block_color" in blk and blk.block_color == b_color:
								if blk.has_method("destroy_with_delay"):
									blk.destroy_with_delay()
					if final_collider.has_method("destroy_with_delay"):
						final_collider.destroy_with_delay()
					else:
						final_collider.queue_free()
				elif b_color == 7:
					var all_blocks = get_tree().get_nodes_in_group("blocks")
					for blk in all_blocks:
						if is_instance_valid(blk) and "block_color" in blk and blk.block_color == current_color:
							if blk.has_method("destroy_with_delay"):
								blk.destroy_with_delay()
					if final_collider.has_method("destroy_with_delay"):
						final_collider.destroy_with_delay()
					else:
						final_collider.queue_free()

				elif b_color == current_color:
					if final_collider.has_method("destroy_with_delay"):
						final_collider.destroy_with_delay()
					else:
						final_collider.queue_free()
				else:
					var ball_is_rgb = current_color in [0, 1, 2]
					var block_is_rgb = b_color in [0, 1, 2]
					var ball_is_cmy = current_color in [4, 5, 6]
					var block_is_cmy = b_color in [4, 5, 6]
					
					if (ball_is_rgb and block_is_rgb) or (ball_is_cmy and block_is_cmy):
						var new_color = mix_flame_colors(current_color, b_color)
						if new_color != -1 and final_collider.has_method("fade_to_color"):
							final_collider.fade_to_color(new_color)
						elif final_collider.has_method("shift_down"):
							final_collider.shift_down()
					else:
						if final_collider.has_method("shift_down"):
							final_collider.shift_down()

		# Duração total ajustada para 0,5 segundos
		await get_tree().create_timer(0.8).timeout
		stop_flame()
		
		reset_rotation()

		var timer = get_tree().create_timer(shoot_cooldown)
		await timer.timeout
		can_shoot = true
		return
	
	# --- COMPORTAMENTO PADRÃO PARA PROJÉTEIS FÍSICOS ---
	can_shoot = false

	if is_instance_valid(player_ball_shoot) and launcher_theme and launcher_theme.hit_sound:
		player_ball_shoot.stream = launcher_theme.hit_sound
		player_ball_shoot.play()

	var active_launcher_id = GameManager.temporary_launcher if GameManager.temporary_launcher != "" else GameManager.equipped_launcher

	if is_instance_valid(player_shoot_anim) and (active_launcher_id == "120mm" or active_launcher_id == "piercing"):
		player_shoot_anim.play("shoot")

	EventBus.camera_shake_requested.emit(40.0, 0.2)

	var current_color = 0
	if is_instance_valid(charger) and charger.has_method("pop_top_ball_color"):
		current_color = charger.pop_top_ball_color()
	elif charger and charger.has_method("get_top_ball_color"):
		current_color = charger.get_top_ball_color()
	
	var ball = pre_ball.instantiate()
	ball.color_ball = current_color
	
	get_parent().add_child(ball)
	ball.global_position = player_marker.global_position
	
	ball.dir = Vector2.UP.rotated(global_rotation)
	ball.rotation = global_rotation
	
	ball_shot.emit(current_color)
	
	reset_rotation()

	var timer = get_tree().create_timer(shoot_cooldown)
	await timer.timeout
	can_shoot = true

func spawn_block_on_press_flame(press_node: Node2D, impact_position: Vector2, color_idx: int) -> void:
	const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")
	const GRID_SIZE: float = 64.0
	
	if not BLOCK_SCENE:
		return

	var container = press_node.find_child("Block", true, false)
	if not container:
		container = press_node

	var ref_offset := Vector2.ZERO
	if container.get_child_count() > 0:
		ref_offset = container.get_child(0).position

	var local_impact = container.to_local(impact_position + Vector2(0, 16.0)) - ref_offset

	var snapped_x = round(local_impact.x / GRID_SIZE) * GRID_SIZE
	var snapped_y = round(local_impact.y / GRID_SIZE) * GRID_SIZE

	var final_local_pos = Vector2(snapped_x, snapped_y) + ref_offset

	var new_block = BLOCK_SCENE.instantiate()
	new_block.name = "Block_Spawned"
	new_block.position = final_local_pos

	new_block.add_to_group("blocks")
	container.add_child(new_block)

	if "block_color" in new_block:
		new_block.block_color = color_idx

	if press_node.has_method("add_collision_exception_with"):
		press_node.add_collision_exception_with(new_block)

	get_tree().process_frame.connect(
		func():
			if is_instance_valid(new_block) and new_block.has_method("check_line_matches"):
				new_block.check_line_matches(),
		CONNECT_ONE_SHOT
	)


func mix_flame_colors(c1: int, c2: int) -> int:
	var pair = [c1, c2]
	pair.sort()
	if pair == [0, 2]: return 5
	if pair == [0, 1]: return 6
	if pair == [1, 2]: return 4
	if pair == [4, 5]: return 2
	if pair == [4, 6]: return 1
	if pair == [5, 6]: return 0
	return -1


func die() -> void:
	game_over.emit()
	player_sprite.hide()
	stop_flame()
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
