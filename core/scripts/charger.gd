extends Node2D

var pre_charger_ball = preload("res://core/scenes/set_elements/color_ball_charger.tscn")

# Lista com as instâncias ativas das bolas
var balls: Array = []

# Lista com a referência dos marcadores na ordem (Index 0 = Marker1, Index 5 = Marker6)
@onready var markers: Array = [
	$ChargerMarker1,
	$ChargerMarker2,
	$ChargerMarker3
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# Usa o call_deferred para garantir que o nó pai já esteja pronto na árvore
	call_deferred("initialize_charger")

func initialize_charger() -> void:
	for marker in markers:
		var new_ball = pre_charger_ball.instantiate()
		
		# Define uma cor aleatória para a bola do carregador
		new_ball.color_ball = randi() % 6
		
		get_parent().add_child(new_ball)
		new_ball.global_position = marker.global_position
		balls.append(new_ball)


# Função ouvinte que será executada ao receber o sinal
func _on_player_ball_shot(_color_index: int = 0) -> void:
	moving_charger_ball()


# Esta função deve ser chamada sempre que o jogador disparar
func moving_charger_ball() -> void:
	if balls.is_empty():
		return
	
	# 1. Remove a bola do topo (Marker 6)
	var fired_ball = balls.pop_back()
	fired_ball.queue_free()
	
	# 2. Anima a subida das bolas restantes
	for i in range(balls.size()):
		var target_marker = markers[i + 1]
		var tween = create_tween()
		tween.tween_property(balls[i], "global_position", target_marker.global_position, 0.15)
	
	# 3. Cria a nova bola na base (Marker 1) com uma NOVA cor aleatória
	var new_ball = pre_charger_ball.instantiate()
	
	# Sorteia a cor para a nova bola que entra na fila
	new_ball.color_ball = randi() % 6
	
	get_parent().add_child(new_ball)
	new_ball.global_position = markers[0].global_position
	
	balls.push_front(new_ball)


# Retorna o valor de 'color_ball' da bola que está no topo do carregador (Marker 6)
func get_top_ball_color() -> int:
	if not balls.is_empty():
		return balls.back().color_ball
	return 0 # Valor padrão caso esteja vazio
