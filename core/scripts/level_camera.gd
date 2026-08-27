extends Camera2D

var tween: Tween

func _ready() -> void:
	add_to_group("camera")
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)

func _on_camera_shake_requested(p_intensity: float, p_duration: float) -> void:
	shake(p_intensity, p_duration)

func shake(p_intensity: float = 40.0, p_duration: float = 0.2) -> void:
	# Cancela qualquer shake anterior que ainda esteja acontecendo
	if tween:
		tween.kill()
		
	tween = create_tween()
	
	# Faz pequenos saltos aleatórios durante a duração
	var steps = int(p_duration * 30) # ~30 vibrações por segundo
	var step_duration = p_duration / steps
	
	for i in range(steps):
		# Calcula a força decrescente (diminui até chegar a 0)
		var damp = 1.0 - (float(i) / float(steps))
		var random_offset = Vector2(
			randf_range(-p_intensity, p_intensity),
			randf_range(-p_intensity, p_intensity)
		) * damp
		
		tween.tween_property(self, "offset", random_offset, step_duration)
		
	# Garante que volta para a posição original no final
	tween.tween_property(self, "offset", Vector2.ZERO, 0.05)
