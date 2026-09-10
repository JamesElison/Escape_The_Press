extends Node2D

var pre_charger_ball = preload("res://core/scenes/set_elements/color_ball_charger.tscn")

# Lista com as instâncias ativas das bolas no carregador
# Index 0 = Bola da saída (Topo / Pronto para disparar - Marker3 ou Marker1 dependendo da sua cena)
# Último Index = Bola na base da fila
var balls: Array = []

# Referência dos marcadores organizados do Topo (Saída) para a Base
@onready var markers: Array = [
	$ChargerMarker3, # Topo (Pronto para atirar)
	$ChargerMarker2, # Meio
	$ChargerMarker1  # Base (Onde entram as novas bolas)
]

func _ready() -> void:
	call_deferred("initialize_charger")

func initialize_charger() -> void:
	# Limpa qualquer bola existente por precaução
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()

	# Instancia uma bola para cada marcador
	for marker in markers:
		var new_ball = pre_charger_ball.instantiate()
		new_ball.color_ball = randi() % 6
		get_parent().add_child(new_ball)
		new_ball.global_position = marker.global_position
		balls.append(new_ball)

## Consome a bola do topo, move a fila e retorna a cor de forma atômica (Sem atraso de sinal)
func pop_top_ball_color() -> int:
	if balls.is_empty():
		return 0 # Valor fallback caso a lista esteja vazia por segurança

	# 1. Pega a bola da frente (Topo da fila / Saída)
	var fired_ball = balls.pop_front()
	var shot_color = fired_ball.color_ball
	
	# Destrói a bola que foi consumida
	fired_ball.queue_free()

	# 2. Anima as bolas restantes subindo um nível em direção ao topo
	for i in range(balls.size()):
		if is_instance_valid(balls[i]):
			var target_marker = markers[i]
			var tween = create_tween()
			tween.tween_property(balls[i], "global_position", target_marker.global_position, 0.12)

	# 3. Instancia a nova bola na base (ChargerMarker1)
	var new_ball = pre_charger_ball.instantiate()
	new_ball.color_ball = randi() % 6
	get_parent().add_child(new_ball)
	
	# Coloca na posição do último marcador (Base)
	var base_marker = markers[markers.size() - 1]
	new_ball.global_position = base_marker.global_position
	
	# Adiciona ao final da lista
	balls.append(new_ball)

	return shot_color

# Mantida por compatibilidade caso algum outro script consulte apenas a cor sem disparar
func get_top_ball_color() -> int:
	if not balls.is_empty() and is_instance_valid(balls[0]):
		return balls[0].color_ball
	return 0
