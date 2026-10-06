
extends CanvasItem
@export var blink_speed: float = 1.4
@export var min_alpha: float = 0.4
@export var max_alpha: float = 1.0

func _process(delta):
	var t = Time.get_ticks_msec() / 1000.0
	var alpha = min_alpha + (max_alpha - min_alpha) * (sin(t * blink_speed * 2.0 * PI) * 0.5 + 0.5)
	modulate.a = alpha
	# Slight blue glow pulse
	modulate = Color(0.5 + alpha*0.5, 0.7 + alpha*0.3, 1.0, alpha)
