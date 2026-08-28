extends RigidBody2D

# Precarrega a própria cena do bloco via código.
const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")

var affected_block: bool = false: set = set_affected_block
var droped_block: bool = false: set = set_droped_block
var block_color = 0: set = set_block_color
var has_landed: bool = false # Impede que o impacto no chão rode múltiplas vezes
var is_being_destroyed: bool = false

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
	
	# Configura o RigidBody2D para monitorar colisões físicas
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Só processa o impacto no chão se o bloco já tiver sido solto (droped_block) e ainda não tiver pousado
	if droped_block and not has_landed and body.name == "Floor":
		has_landed = true
		
		# Aplica o impacto desejado
		affected_block = true
		
		# Opcional: destrói o bloco logo após o impacto no chão
		# destroy_with_delay()


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
	if is_being_destroyed:
		return
	is_being_destroyed = true
	
	play_impact_animation()
	
	# Dispara a contaminação para os blocos vizinhos ANTES de sumir
	contaminate_neighbors()
	
	await get_tree().create_timer(0.3).timeout
	queue_free()

# Função que procura blocos adjacentes da mesma cor
func contaminate_neighbors() -> void:
	var space_state = get_world_2d().direct_space_state
	
	# Checa nas 4 direções cardeais (Cima, Baixo, Esquerda, Direita)
	# Ajuste o offset (32.0) conforme o tamanho dos seus sprites/collision shapes
	var check_offsets = [
		Vector2.UP * 64.0,
		Vector2.DOWN * 64.0,
		Vector2.LEFT * 64.0,
		Vector2.RIGHT * 64.0
	]
	
	for offset in check_offsets:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position + offset
		query.collide_with_bodies = true
		
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			
			# Se o objeto encontrado for outro bloco válido
			if collider is RigidBody2D and collider != self and "block_color" in collider:
				# Checa se tem a mesma cor e se ainda não está sendo destruído
				if collider.block_color == self.block_color and not collider.get("is_being_destroyed"):
					# Aplica um pequeno delay (ex: 0.1s) para dar o efeito visual em cadeia
					get_tree().create_timer(0.1).timeout.connect(collider.destroy_with_delay)

func set_block_color(val) -> void:
	block_color = val
	if block_sprite and val >= 0 and val < block_colors.size():
		block_sprite.texture = load(block_colors[val])

func _on_block_timer_timeout() -> void:
	queue_free()
