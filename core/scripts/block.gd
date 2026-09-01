extends AnimatableBody2D

# Precarrega a própria cena do bloco via código
const BLOCK_SCENE = preload("res://core/entities/enemies/block.tscn")

var affected_block: bool = false: set = set_affected_block
var droped_block: bool = false: set = set_droped_block
var block_color = 0: set = set_block_color
var has_landed: bool = false
var is_being_destroyed: bool = false

# Velocidade de queda do bloco após ser descolado da Prensa (pixels/segundo)
@export var fall_speed: float = 600.0

# Posição original do bloco no momento em que soltou da Prensa
var spawn_position: Vector2

@onready var block_color_change_sound = $BlockColorChangeSound
@onready var block_explode_sound = $BlockExplodeSound
@onready var block_explode_group_sound = $BlockExplodeGroupSound
@onready var block_move_down_sound = $BlockMoveDownSound
@onready var block_sprite = $BlockSprite
@onready var block_timer = $BlockTimer
@onready var block_anim = $BlockAnim

var block_colors = [
	"res://core/assets/sprites/set_objects/red_block.png",
	"res://core/assets/sprites/set_objects/green_block.png",
	"res://core/assets/sprites/set_objects/blue_block.png",
	"res://core/assets/sprites/set_objects/ciano_block.png",
	"res://core/assets/sprites/set_objects/magenta_block.png",
	"res://core/assets/sprites/set_objects/yellow_block.png"
]

func set_block_color(val) -> void:
	block_color = val
	if is_node_ready() and block_sprite and val >= 0 and val < block_colors.size():
		block_sprite.texture = load(block_colors[val])

func _ready() -> void:
	var random_index = randi() % block_colors.size()
	self.block_color = random_index
	
	add_to_group("blocks")
	
	# Desativa sync com física tradicional para poder mover livremente ao cair
	sync_to_physics = false

func _physics_process(delta: float) -> void:
	# Quando o bloco soltar da Prensa, fazemos ele cair até atingir o chão
	if droped_block and not has_landed:
		var movement = Vector2.DOWN * fall_speed * delta
		var collision = move_and_collide(movement)
		
		# Se tocar no chão ou em outro bloco estacionado no chão
		if collision:
			var collider = collision.get_collider()
			if collider.name == "Floor" or (collider is AnimatableBody2D and collider.has_landed):
				has_landed = true
				affected_block = true

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
		affected_block = false

func set_droped_block(val: bool) -> void:
	if droped_block == val:
		return
		
	droped_block = val
	
	if droped_block:
		# Captura a posição global no momento do impacto
		spawn_position = global_position
		play_impact_animation()
		
		# 1. Aguarda a animação de impacto
		await get_tree().create_timer(0.3).timeout
		
		if block_sprite:
			block_sprite.position = Vector2.ZERO
		
		# 2. Transfere o bloco da Prensa para a cena principal para que ele possa cair sozinho
		var main_scene = get_tree().current_scene
		if get_parent() != main_scene:
			reparent(main_scene, true)
		
		# 3. Aguarda um pequeno intervalo e gera o bloco substituto preso na Prensa
		await get_tree().create_timer(0.5).timeout
		spawn_replacement_block()
		
		if block_timer:
			block_timer.start(5.0)

func spawn_replacement_block() -> void:
	var press_node = get_tree().current_scene.find_child("Press", true, false)
	
	if press_node and BLOCK_SCENE:
		var new_block = BLOCK_SCENE.instantiate()
		var container = press_node.find_child("Block", true, false)
		if not container:
			container = press_node
			
		container.add_child(new_block)
		new_block.global_position = spawn_position
		
		if press_node.has_method("add_collision_exception_with"):
			press_node.add_collision_exception_with(new_block)

# Toca o som de troca de cor com um leve atraso de transição (80 milissegundos)
func play_color_change_sound() -> void:
	if block_color_change_sound:
		await get_tree().create_timer(0.10).timeout
		block_color_change_sound.play()

func destroy_with_delay() -> void:
	if is_being_destroyed:
		return
	is_being_destroyed = true
	
	# Oculta o sprite e desativa colisão para dar a sensação de destruição imediata
	if block_sprite:
		block_sprite.hide()
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	if block_explode_sound:
		await get_tree().create_timer(0.10).timeout
		block_explode_sound.play()
		
	play_impact_animation()
	contaminate_neighbors()
	
	# Aguarda tempo suficiente para o som de explosão terminar antes de dar queue_free()
	if block_explode_sound and block_explode_sound.stream:
		await get_tree().create_timer(block_explode_sound.stream.get_length()).timeout
	else:
		await get_tree().create_timer(0.5).timeout
		
	queue_free()

# Contaminação por raio de aproximação nas 4 direções cardeais
func contaminate_neighbors() -> void:
	var space_state = get_world_2d().direct_space_state
	var check_offsets = [
		Vector2.UP * 64.0,
		Vector2.DOWN * 64.0,
		Vector2.LEFT * 64.0,
		Vector2.RIGHT * 64.0
	]
	
	var group_sound_played: bool = false
	
	for offset in check_offsets:
		var query = PhysicsPointQueryParameters2D.new()
		query.position = global_position + offset
		query.collide_with_bodies = true
		
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			if collider != self and "block_color" in collider:
				if collider.block_color == self.block_color and not collider.get("is_being_destroyed"):
					# Toca o som de destruição em grupo apenas UMA vez para a reação da vizinhança
					if block_explode_group_sound and not group_sound_played:
						block_explode_group_sound.play()
						group_sound_played = true
						
					get_tree().create_timer(0.1).timeout.connect(collider.destroy_with_delay)

# Move o bloco uma casa para baixo na grade local da Prensa
func shift_down() -> void:
	if block_move_down_sound:
		await get_tree().create_timer(0.10).timeout
		block_move_down_sound.play()
	play_impact_animation()
	position.y += 64.0

func _on_block_timer_timeout() -> void:
	queue_free()
