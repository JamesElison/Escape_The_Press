extends CharacterBody2D

const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")
const GRID_SIZE: float = 64.0

var dir = Vector2.UP
var speed: float = 1500.0 # Valor base/fallback
var is_exploding: bool = false

@onready var color_ball_sprite = $ColorBallSprite
@onready var color_ball_shape = $ColorBallShape
@onready var color_ball_anim = $ColorBallAnim

var color_balls = [
	"res://core/assets/sprites/set_objects/red_ball.png",
	"res://core/assets/sprites/set_objects/green_ball.png",
	"res://core/assets/sprites/set_objects/blue_ball.png",
	"res://core/assets/sprites/set_objects/ciano_ball.png",
	"res://core/assets/sprites/set_objects/magenta_ball.png",
	"res://core/assets/sprites/set_objects/yellow_ball.png"
]

@export var color_ball = 0: set = set_color_ball

func _ready() -> void:
	apply_launcher_speed()
	set_color_ball(color_ball)

# Configura a velocidade com base no lançador equipado no GameManager
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
			speed = 1500.0 # Velocidade padrão caso não seja nenhum dos três

func set_color_ball(val) -> void:
	color_ball = val
	if color_ball_sprite and val >= 0:
		var tex_path = get_projectile_texture_path(val)
		if ResourceLoader.exists(tex_path):
			color_ball_sprite.texture = load(tex_path)

func get_projectile_texture_path(color_idx: int) -> String:
	var color_names = ["red.png", "green.png", "blue.png", "cyan.png", "magenta.png", "yellow.png"]
	var color_file = color_names[clamp(color_idx, 0, 5)]
	
	var equipped = GameManager.equipped_launcher
	var base_folder = ""
	
	match equipped:
		"120mm":
			base_folder = "res://core/assets/sprites/set_objects/specific_projectiles/1_120mm_type/"
		"piercing":
			base_folder = "res://core/assets/sprites/set_objects/specific_projectiles/2_piercing_type/"
		"mini_plasma":
			base_folder = "res://core/assets/sprites/set_objects/specific_projectiles/3_mini_plasma_type/"
		_:
			# Caso padrão (se usar as bolas padrão do jogo)
			if color_idx < color_balls.size():
				return color_balls[color_idx]
			return ""

	return base_folder + color_file

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
		
	var movement = dir * speed * delta
	var collision = move_and_collide(movement)
	
	if collision:
		var collider = collision.get_collider()
		
		# Colisão com a Prensa -> Anexa o novo bloco à Prensa
		if collider.name == "Press":
			spawn_block_on_press(collider, collision.get_position())
			destroy_with_anim()
			if "press_hit" in collider:
				collider.press_hit()
			return

		# Checa se o objeto colidido é um bloco (possui a propriedade block_color)
		if collider.is_in_group("blocks") and "block_color" in collider:
			
			if "affected_block" in collider:
				collider.affected_block = false
				collider.affected_block = true
			
			if collider.has_method("play_impact_animation"):
				collider.play_impact_animation()
			
			if "droped_block" in collider and collider.droped_block:
				destroy_with_anim()
				return
			
			var b_color = collider.block_color
			
			# Regra 1: Mesma cor -> Destrói
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
			var ball_is_kw = color_ball in [6, 7]
			var block_is_kw = b_color in [6, 7]
			
			# Regra 3: Mesmo padrão -> MISTURA
			if (ball_is_rgb and block_is_rgb) or (ball_is_cmy and block_is_cmy) or (ball_is_kw and block_is_kw):
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
			
			# Regra 2: Padrões opostos -> Desce uma posição na grade
			if (ball_is_rgb and block_is_cmy) or (ball_is_cmy and block_is_rgb) or (ball_is_rgb and block_is_kw) or (ball_is_cmy and block_is_kw) or (ball_is_kw and block_is_rgb) or (ball_is_kw and block_is_cmy):
				if collider.has_method("shift_down"):
					collider.shift_down()
				destroy_with_anim()
				return
		
		dir = dir.bounce(collision.get_normal())

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

	# Garante que o novo bloco faça parte do grupo "blocks"
	new_block.add_to_group("blocks")

	# 1. Adiciona o nó na árvore primeiro (dispara o _ready do bloco)
	container.add_child(new_block)

	# 2. Atribui a cor da bola DEPOIS
	if "block_color" in new_block:
		new_block.block_color = self.color_ball

	if press_node.has_method("add_collision_exception_with"):
		press_node.add_collision_exception_with(new_block)

func destroy_with_anim() -> void:
	is_exploding = true
	speed = 0.0
	
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
