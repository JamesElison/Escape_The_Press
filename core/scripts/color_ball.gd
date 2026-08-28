extends CharacterBody2D

# Precarrega a cena do bloco para spawnar na Prensa
const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")
# Tamanho fixo da sua grade de blocos
const GRID_SIZE: float = 64.0

var dir = Vector2.UP
var speed = 1500.0
var is_exploding: bool = false # Impede reprocessamento durante a explosão

@onready var color_ball_sprite = $ColorBallSprite
@onready var color_ball_shape = $ColorBallShape
@onready var color_ball_anim = $ColorBallAnim

var color_balls = [
	"res://core/assets/sprites/set_objects/red_ball.png",
	"res://core/assets/sprites/set_objects/green_ball.png",
	"res://core/assets/sprites/set_objects/blue_ball.png",
	"res://core/assets/sprites/set_objects/ciano_ball.png",
	"res://core/assets/sprites/set_objects/magenta_ball.png",
	"res://core/assets/sprites/set_objects/yellow_ball.png",
	#"res://core/assets/sprites/set_objects/black_ball.png",
	#"res://core/assets/sprites/set_objects/white_ball.png"
]

@export var color_ball = 0: set = set_color_ball


func set_color_ball(val) -> void:
	color_ball = val
	if color_ball_sprite and val >= 0 and val < color_balls.size():
		color_ball_sprite.texture = load(color_balls[val])

func _ready() -> void:
	set_color_ball(color_ball)

func _physics_process(delta: float) -> void:
	# Se a bola já colidiu e está explodindo, ignora a física completamente
	if is_exploding:
		return
		
	var movement = dir * speed * delta
	var collision = move_and_collide(movement)
	
	if collision:
		var collider = collision.get_collider()
		
		# -------------------------------------------------------------
		# Regras: Prensa, Floor ou Player
		# -------------------------------------------------------------
		if collider.name == "Floor" or (collider is CharacterBody2D and collider.name != "Press"):
			queue_free()
			return
			
		# -------------------------------------------------------------
		# Regra: Prensa (Spawna um bloco da mesma cor da bola no ponto de impacto)
		# -------------------------------------------------------------
		if collider.name == "Press":
			spawn_block_at_impact(collision.get_position())
			destroy_with_anim()
			return

		# -------------------------------------------------------------
		# Regras 1, 2 e 3: Colisão com o Bloco (RigidBody2D)
		# -------------------------------------------------------------
		if collider is RigidBody2D and "block_color" in collider:
			
			if "affected_block" in collider:
				collider.affected_block = false
				collider.affected_block = true
			
			if collider.has_method("play_impact_animation"):
				collider.play_impact_animation()
			
			# Se o bloco já estiver caindo
			if "droped_block" in collider and collider.droped_block:
				destroy_with_anim()
				return
			
			var b_color = collider.block_color
			
			# Regra 1: Mesma cor -> Animação e destrói
			if b_color == color_ball:
				if collider.has_method("destroy_with_delay"):
					collider.destroy_with_delay()
				else:
					collider.queue_free()
				destroy_with_anim()
				return
				
			# Mapeamento dos grupos
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
					collider.block_color = new_color
				elif new_color == -1:
					if "droped_block" in collider:
						collider.droped_block = true
				destroy_with_anim()
				return
			
			# Regra 2: Padrões opostos -> Queda
			if (ball_is_rgb and block_is_cmy) or (ball_is_cmy and block_is_rgb) or (ball_is_rgb and block_is_kw) or (ball_is_cmy and block_is_kw) or (ball_is_kw and block_is_rgb) or (ball_is_kw and block_is_cmy):
				if "droped_block" in collider:
					collider.droped_block = true
				destroy_with_anim()
				return
		
		# Ricochete padrão para paredes laterais
		dir = dir.bounce(collision.get_normal())

# Função para instanciar o bloco alinhado à grade de 64x64px
func spawn_block_at_impact(impact_position: Vector2) -> void:
	var parent_node = get_parent()
	if parent_node and BLOCK_SCENE:
		var new_block = BLOCK_SCENE.instantiate()
		
		# Calcula a posição exata do centro do slot da grade de 64px
		# Exemplo: Se bateu na posição X = 150, (150 / 64) arredondado dá 2 -> 2 * 64 = 128 (centro da coluna)
		var snapped_x: float = floor(impact_position.x / GRID_SIZE) * GRID_SIZE + (GRID_SIZE / 2.0)
		var snapped_y: float = floor(impact_position.y / GRID_SIZE) * GRID_SIZE + (GRID_SIZE / 2.0)
		
		new_block.global_position = Vector2(snapped_x, snapped_y)
		
		# 1. Adiciona à árvore de nós
		parent_node.add_child(new_block)
		
		# 2. Define a mesma cor da bola
		if "block_color" in new_block:
			new_block.block_color = self.color_ball

# Função para congelar a bola e tocar a animação com segurança
func destroy_with_anim() -> void:
	is_exploding = true
	speed = 0.0
	
	# Desativa colisões com segurança usando set_deferred
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if color_ball_shape:
		color_ball_shape.set_deferred("disabled", true)
		
	color_ball_anim.play("explode")
	await get_tree().create_timer(0.42).timeout
	queue_free()

# Tabela de Mistura de Cores
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
