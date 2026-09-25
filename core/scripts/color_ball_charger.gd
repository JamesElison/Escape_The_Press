extends Node2D

@onready var color_ball_sprite = $ColorBallSprite

const DISPLAY_FILENAMES = [
	"red_display.png", "green_display.png", "blue_display.png", 
	"cyan_display.png", "magenta_display.png", "yellow_display.png",
	"black_display.png", "white_display.png"
]

@export var color_ball: int = 0: set = set_color_ball

func _ready() -> void:
	if not EventBus.launcher_changed.is_connected(_on_launcher_changed):
		EventBus.launcher_changed.connect(_on_launcher_changed)
		
	self.color_ball = get_random_valid_color_index()

func _on_launcher_changed(_launcher_id: String) -> void:
	set_color_ball(color_ball)

func set_color_ball(val: int) -> void:
	color_ball = val
	if is_node_ready() and color_ball_sprite and val >= 0:
		var tex_path = get_display_texture_path(val)
		if ResourceLoader.exists(tex_path):
			color_ball_sprite.texture = load(tex_path)

func get_display_texture_path(color_idx: int) -> String:
	var theme = GameManager.get_current_theme()
	var clamped_idx = clamp(color_idx, 0, DISPLAY_FILENAMES.size() - 1)
	var filename = DISPLAY_FILENAMES[clamped_idx]
	var full_path = theme.display_folder + filename
	
	if ResourceLoader.exists(full_path):
		return full_path
	return "res://core/assets/sprites/set_objects/" + filename.replace("_display.png", "_ball.png")

func get_random_valid_color_index() -> int:
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
