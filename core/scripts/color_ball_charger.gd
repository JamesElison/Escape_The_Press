extends Node2D

@onready var color_ball_sprite = $ColorBallSprite

var color_balls = [
	"res://core/assets/sprites/set_objects/red_ball.png",
	"res://core/assets/sprites/set_objects/green_ball.png",
	"res://core/assets/sprites/set_objects/blue_ball.png",
	"res://core/assets/sprites/set_objects/ciano_ball.png",
	"res://core/assets/sprites/set_objects/magenta_ball.png",
	"res://core/assets/sprites/set_objects/yellow_ball.png",
	#"res://core/assets/sprites/set_objects/black_ball.png",
	#"res://core/assets/sprites/set_objects/white_ball.png"
]

@export var color_ball = 0: set = set_color_ball

func set_color_ball(val) -> void:
	color_ball = val
	if color_ball_sprite and val >= 0 and val < color_balls.size():
		color_ball_sprite.texture = load(color_balls[val])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Sorteia um número entre 0 e o último índice da lista
	var random_index = randi() % color_balls.size()
	
	# Atribui o valor sorteado (isso aciona o setter 'set_block_color')
	self.color_ball = random_index
