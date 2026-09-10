extends Node2D

signal top_color_changed(new_color_idx: int)

var pre_charger_ball = preload("res://core/scenes/set_elements/color_ball_charger.tscn")

var balls: Array = []

@onready var markers: Array = [
	$ChargerMarker3, # Topo (Saída)
	$ChargerMarker2, # Meio
	$ChargerMarker1  # Base
]

func _ready() -> void:
	call_deferred("initialize_charger")

func initialize_charger() -> void:
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()

	for marker in markers:
		var new_ball = pre_charger_ball.instantiate()
		get_parent().add_child(new_ball)
		new_ball.global_position = marker.global_position
		new_ball.color_ball = get_targeted_bottom_color()
		balls.append(new_ball)

	# Notifica o player sobre a cor da primeira bola no topo
	top_color_changed.emit(get_top_ball_color())

func pop_top_ball_color() -> int:
	if balls.is_empty():
		return 0

	# 1. Remove a bola do topo
	var fired_ball = balls.pop_front()
	var shot_color = 0
	
	if is_instance_valid(fired_ball):
		shot_color = fired_ball.color_ball
		fired_ball.queue_free()

	# 2. Anima a subida das bolas restantes
	for i in range(balls.size()):
		if is_instance_valid(balls[i]):
			var target_marker = markers[i]
			var tween = create_tween()
			tween.tween_property(balls[i], "global_position", target_marker.global_position, 0.12)

	# 3. Cria uma nova bola na base com a cor direcionada
	var new_ball = pre_charger_ball.instantiate()
	get_parent().add_child(new_ball)
	new_ball.global_position = markers[2].global_position
	new_ball.color_ball = get_targeted_bottom_color()
	balls.append(new_ball)

	# 4. Notifica a nova cor do topo após a reorganização
	top_color_changed.emit(get_top_ball_color())

	return shot_color

func get_top_ball_color() -> int:
	if not balls.is_empty() and is_instance_valid(balls[0]):
		return balls[0].color_ball
	return 0

func get_targeted_bottom_color() -> int:
	var all_blocks = get_tree().get_nodes_in_group("blocks")
	var valid_blocks: Array[Node] = []

	for block in all_blocks:
		if is_instance_valid(block) and not block.get("is_being_destroyed"):
			valid_blocks.append(block)

	if valid_blocks.is_empty():
		return randi() % 6

	var unique_y_positions: Array[float] = []
	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if not block_y in unique_y_positions:
			unique_y_positions.append(block_y)

	unique_y_positions.sort()
	unique_y_positions.reverse()

	var target_y_count = min(2, unique_y_positions.size())
	var lowest_y_levels = unique_y_positions.slice(0, target_y_count)

	var available_colors: Array[int] = []

	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if block_y in lowest_y_levels:
			var idx: int = block.block_color
			if idx >= 0 and idx < 6 and not idx in available_colors:
				available_colors.append(idx)

	if not available_colors.is_empty():
		return available_colors.pick_random()

	return randi() % 6
