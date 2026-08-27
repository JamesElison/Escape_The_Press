extends RigidBody2D

# Precarrega a própria cena do bloco via código.
const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")

var affected_block: bool = false: set = set_affected_block
var droped_block: bool = false: set = set_droped_block
var block_color = 0: set = set_block_color

# Variável para guardar a posição do bloco logo antes de ele cair
var spawn_position: Vector2

@onready var block_sprite = $BlockSprite
@onready var block_timer = $BlockTimer
@onready var block_anim = $BlockAnim

var block_colors = [
	"res://core/assets/sprites/set_objects/red_block.png",
	"res://core/assets/sprites/set_objects/green_block.png",
	"res://core/assets/sprites/set_objects/blue_block.png",
	"res://core/assets/sprites/set_objects/ciano_block.png",
	"res://core/assets/sprites/set_objects/magenta_block.png",
	"res://core/assets/sprites/set_objects/yellow_block.png",
	#"res://core/assets/sprites/set_objects/black_block.png",
	#"res://core/assets/sprites/set_objects/white_block.png"
]

func _ready() -> void:
	var random_index = randi() % block_colors.size()
	self.block_color = random_index

func play_impact_animation() -> void:
	if block_anim:
		block_anim.play("affected")

func set_affected_block(val: bool) -> void:
	if affected_block == val:
		return
	affected_block = val
	if affected_block:
		play_impact_animation()
		EventBus.camera_shake_requested.emit(40.0, 0.2)
		# Permite que o bloco receba novos tremores em impactos futuros
		affected_block = false

func set_droped_block(val: bool) -> void:
	if droped_block == val:
		return
		
	droped_block = val
	
	if droped_block:
		# Captura a posição global EXATA do bloco agora (já com a prensa tendo empurrado ele)
		spawn_position = global_position
		play_impact_animation()
		
		# 1. Aguarda os 0.3s da animação de impacto
		await get_tree().create_timer(0.3).timeout
		
		# Garante que o sprite volte ao centro exato do nó antes de liberar a física
		if block_sprite:
			block_sprite.position = Vector2.ZERO
		
		# 2. Descongela e faz o bloco antigo começar a cair
		freeze = false
		sleeping = false
		gravity_scale = 1.0
		linear_velocity = Vector2.ZERO
		
		# 3. Aguarda os 0.5s para o bloco descer e abrir espaço
		await get_tree().create_timer(0.5).timeout
		
		# 4. Spawna o substituto na posição que capturamos no momento do impacto
		spawn_replacement_block()
		
		if block_timer:
			block_timer.start(5.0)

func spawn_replacement_block() -> void:
	var parent_node = get_parent()
	
	if parent_node and BLOCK_SCENE:
		var new_block = BLOCK_SCENE.instantiate()
		# Usa a posição exata onde o bloco estava antes de iniciar a queda
		new_block.global_position = spawn_position
		parent_node.call_deferred("add_child", new_block)

func destroy_with_delay() -> void:
	play_impact_animation()
	await get_tree().create_timer(0.3).timeout
	queue_free()

func set_block_color(val) -> void:
	block_color = val
	if block_sprite and val >= 0 and val < block_colors.size():
		block_sprite.texture = load(block_colors[val])

func _on_block_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.name == "Floor":
		play_impact_animation()
		EventBus.camera_shake_requested.emit(40.0, 0.2)
