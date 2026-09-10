extends Node2D

@onready var color_ball_sprite = $ColorBallSprite

var color_balls: Array[String] = [
	"res://core/assets/sprites/set_objects/red_ball.png",
	"res://core/assets/sprites/set_objects/green_ball.png",
	"res://core/assets/sprites/set_objects/blue_ball.png",
	"res://core/assets/sprites/set_objects/ciano_ball.png",
	"res://core/assets/sprites/set_objects/magenta_ball.png",
	"res://core/assets/sprites/set_objects/yellow_ball.png"
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

	# Filtra apenas blocos ativos
	for block in all_blocks:
		if is_instance_valid(block) and not block.get("is_being_destroyed"):
			valid_blocks.append(block)

	if valid_blocks.is_empty():
		return randi() % color_balls.size()

	# Mapeia as posições Y únicas dos blocos
	var unique_y_positions: Array[float] = []
	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if not block_y in unique_y_positions:
			unique_y_positions.append(block_y)

	# Ordena as posições Y em ordem decrescente (maior Y = mais abaixo/próximo do jogador)
	unique_y_positions.sort()
	unique_y_positions.reverse()

	# Seleciona as fileiras mais próximas do lançador (as 2 mais baixas)
	var target_y_count = min(2, unique_y_positions.size())
	var lowest_y_levels = unique_y_positions.slice(0, target_y_count)

	var available_colors: Array[int] = []

	for block in valid_blocks:
		var block_y = snapped(block.global_position.y, 16.0)
		if block_y in lowest_y_levels:
			var idx: int = block.block_color
			if idx >= 0 and idx < color_balls.size() and not idx in available_colors:
				available_colors.append(idx)

	# Retorna uma cor presente nas fileiras inferiores
	if not available_colors.is_empty():
		return available_colors.pick_random()

	return randi() % color_balls.size()
