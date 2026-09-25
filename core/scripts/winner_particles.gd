extends GPUParticles2D

func setup(texture_path: String = "") -> void:
	if texture_path != "":
		texture = load(texture_path)
		
	# Reseta e inicia a emissão das partículas
	restart()
	emitting = true
	
	# Aguarda o tempo de vida das partículas terminar e remove o nó da memória
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
