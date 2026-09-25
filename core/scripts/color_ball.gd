extends CharacterBody2D

const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")
const GRID_SIZE: float = 64.0

var dir = Vector2.UP
var speed: float = 2000.0
var is_exploding: bool = false

@onready var color_ball_sprite = $ColorBallSprite
@onready var color_ball_shape = $ColorBallShape
@onready var color_ball_anim = $ColorBallAnim

const COLOR_FILENAMES = [
	"red.png", "green.png", "blue.png", 
	"cyan.png", "magenta.png", "yellow.png",
	"black.png", "white.png"
]

@export var color_ball = 0: set = set_color_ball

func _ready() -> void:
	apply_launcher_speed()
	set_color_ball(color_ball)
	update_rotation_from_dir()

func apply_launcher_speed() -> void:
	var equipped = GameManager.equipped_launcher
	match equipped:
		"120mm":
			speed = 2500.0
		"piercing":
			speed = 4000.0
		"mini_plasma":
			speed = 3000.0
		_:
			speed = 1500.0

func update_rotation_from_dir() -> void:
	rotation = dir.angle() + (PI / 2.0)

func set_color_ball(val) -> void:
	color_ball = val
	if color_ball_sprite and val >= 0:
		var tex_path = get_projectile_texture_path(val)
		if ResourceLoader.exists(tex_path):
			color_ball_sprite.texture = load(tex_path)

func get_projectile_texture_path(color_idx: int) -> String:
	var theme = GameManager.get_current_theme()
	var clamped_idx = clamp(color_idx, 0, COLOR_FILENAMES.size() - 1)
	var filename = COLOR_FILENAMES[clamped_idx]
	var full_path = theme.projectile_folder + filename
	
	if ResourceLoader.exists(full_path):
		return full_path
	return "res://core/assets/sprites/set_objects/" + filename.replace(".png", "_ball.png")

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
		
	var movement = dir * speed * delta
	var collision = move_and_collide(movement)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.name == "Press":
			spawn_block_on_press(collider, collision.get_position())
			destroy_with_anim()
			if "press_hit" in collider:
				collider.press_hit()
			return

		if collider.is_in_group("blocks") and "block_color" in collider:
			
			if "affected_block" in collider:
				collider.affected_block = false
				collider.affected_block = true
			
			if collider.has_method("play_impact_animation"):
				collider.play_impact_animation()
			
			if "droped_block" in collider and collider.droped_block:
				destroy_with_anim()
				return

			# Verificação do Bloco Misterioso
			if collider.get("is_mystery_active") == true:
				collider.set_mystery(false)
				var level_node = get_tree().current_scene
				if level_node and level_node.has_method("trigger_mystery_reward"):
					level_node.trigger_mystery_reward()
			
			var b_color = collider.block_color
			
			# --- EFEITO DA BOLA BRANCA (ID 7) ---
			# Atinge qualquer bloco do grid e congela a prensa por 10 segundos
			if color_ball == 7:
				var level_node = get_tree().current_scene
				if level_node and level_node.has_method("freeze_press_for_duration"):
					level_node.freeze_press_for_duration(10.0)
				
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return

			# --- EFEITO DA BOLA PRETA (ID 6) ---
			# Ao acertar um bloco colorido (0 a 5), limpa todos os blocos do mapa com essa mesma cor
			if color_ball == 6:
				if b_color >= 0 and b_color <= 5:
					destroy_all_blocks_of_color(b_color)
				elif collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return

			# --- SE O BLOCO ATINGIDO FOR K (6) OU W (7) ---
			if b_color == 6:
				destroy_all_blocks_of_color(self.color_ball)
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return
				
			if b_color == 7:
				var level_node = get_tree().current_scene
				if level_node and level_node.has_method("freeze_press_for_duration"):
					level_node.freeze_press_for_duration(10.0)
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return

			# --- COLISÕES PADRÃO DE MESMA COR ---
			if b_color == color_ball:
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return
				
			var ball_is_rgb = color_ball in [0, 1, 2]
			var block_is_rgb = b_color in [0, 1, 2]
			var ball_is_cmy = color_ball in [3, 4, 5]
			var block_is_cmy = b_color in [3, 4, 5]
			
			if (ball_is_rgb and block_is_rgb) or (ball_is_cmy and block_is_cmy):
				var new_color = mix_colors(color_ball, b_color)
				if new_color != -1:
					if collider.has_method("fade_to_color"):
						collider.fade_to_color(new_color)
					else:
						collider.block_color = new_color
						
					if collider.has_method("play_color_change_sound"):
						collider.play_color_change_sound()
				elif new_color == -1:
					if "droped_block" in collider:
						collider.droped_block = true
				destroy_with_anim()
				return
			
			# Miscigenação incompatível faz o bloco descer
			if (ball_is_rgb and block_is_cmy) or (ball_is_cmy and block_is_rgb):
				if collider.has_method("shift_down"):
					collider.shift_down()
				destroy_with_anim()
				return
		
		dir = dir.bounce(collision.get_normal()).normalized()
		update_rotation_from_dir()

func destroy_all_blocks_of_color(target_color: int) -> void:
	var all_blocks = get_tree().get_nodes_in_group("blocks")
	for block in all_blocks:
		if is_instance_valid(block) and "block_color" in block:
			if block.block_color == target_color and not block.get("is_being_destroyed"):
				if block.has_method("destroy_with_delay"):
					block.destroy_with_delay()

func spawn_block_on_press(press_node: Node2D, impact_position: Vector2) -> void:
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
		new_block.block_color = self.color_ball

	if press_node.has_method("add_collision_exception_with"):
		press_node.add_collision_exception_with(new_block)

	get_tree().process_frame.connect(
		func():
			if is_instance_valid(new_block) and new_block.has_method("check_line_matches"):
				new_block.check_line_matches(),
		CONNECT_ONE_SHOT
	)

func destroy_with_anim() -> void:
	is_exploding = true
	speed = 0.0
	
	var theme = GameManager.get_current_theme()
	if theme and theme.hit_sound:
		GameManager.play_sfx_persistent(theme.hit_sound)
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if color_ball_shape:
		color_ball_shape.set_deferred("disabled", true)
		
	color_ball_anim.play("explode")
	await get_tree().create_timer(0.42).timeout
	queue_free()

func mix_colors(c1: int, c2: int) -> int:
	var pair = [c1, c2]
	pair.sort()
	
	if pair == [0, 2]: return 4
	if pair == [0, 1]: return 5
	if pair == [1, 2]: return 3
	
	if pair == [3, 4]: return 2
	if pair == [3, 5]: return 1
	if pair == [4, 5]: return 0
	
	return -1
