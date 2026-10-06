
extends Sprite2D
@export var rotation_speed: float = 30.0 # degrees per second
@export var clockwise: bool = true

func _process(delta):
    var dir = 1.0 if clockwise else -1.0
    rotation_degrees += rotation_speed * delta * dir
