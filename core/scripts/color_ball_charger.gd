extends Node2D

@onready var color_ball_sprite = $ColorBallSprite

var color_balls: Array[String] = [
	"res://core/assets/sprites/set_objects/red_ball.png",
	"res://core/assets/sprites/set_objects/green_ball.png",
	"res://core/assets/sprites/set_objects/blue_ball.png",
	"res://core/assets/sprites/set_objects/ciano_ball.png",
	"res://core/assets/sprites/set_objects/magenta_ball.png",
	"res://core/assets/sprites/set_objects/yellow_ball.png",
	#"res://core/assets/sprites/set_objects/black_ball.png",
	#"res://core/assets/sprites/set_objects/white_ball.png"
]

@export var color_ball: int = 0: set = set_color_ball

func set_color_ball(val: int) -> void:
	color_ball = val
	if is_node_ready() and color_ball_sprite and val >= 0 and val < color_balls.size():
		color_ball_sprite.texture = load(color_balls[val])

func _ready() -> void:
	self.color_ball = get_random_valid_color_index()

func get_random_valid_color_index() -> int:
	var all_blocks = get_tree().get_nodes_in_group("blocks")
	var valid_blocks: Array[Node] = []

	# Filtra apenas blocos ativos (ignora os que estão sendo destruídos)
	for block in all_blocks:
		if is_instance_valid(block) and not block.get("is_being_destroyed"):
			valid_blocks.append(block)

	if valid_blocks.is_empty():
		return randi() % color_balls.size()

	# 1. Mapeia as alturas (posições Y) únicas dos blocos ativos
	var unique_y_positions: Array[float] = []
	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if not block_y in unique_y_positions:
			unique_y_positions.append(block_y)

	# 2. Se houver 3 fileiras ou menos de altura restante
	if unique_y_positions.size() <= 3:
		var available_indices: Array[int] = []

		for block in valid_blocks:
			var idx: int = block.block_color
			if idx >= 0 and idx < color_balls.size() and not idx in available_indices:
				available_indices.append(idx)

		# Sorteia apenas entre as cores presentes na tela
		if not available_indices.is_empty():
			return available_indices.pick_random()

	# 3. Se houver 4 fileiras ou mais, sorteia qualquer cor normalmente
	return randi() % color_balls.size()
