extends CharacterBody2D

var screen_size
var pre_ball = preload("res://core/scenes/set_elements/color_ball.tscn")

const SPEED = 1000.0

@onready var player_marker = $PlayerMarker
# Referência para o nó do carregador (ajuste o caminho se necessário)
@export var charger: Node2D

# 1. Atualize a declaração para enviar o número/índice da cor
signal ball_shot(color_index: int)
signal game_over

func _ready() -> void:
	screen_size = get_viewport_rect().size


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	position = position.clamp(Vector2.ZERO, screen_size) # clamp significa "limitar".

	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
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
	queue_free() # Ou recarregue a cena com get_tree().reload_current_scene()


func _on_player_health_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.name.begins_with("Block"):
		print(body)
		die()
	elif body.name == "Press":
		print(body)
		die()
