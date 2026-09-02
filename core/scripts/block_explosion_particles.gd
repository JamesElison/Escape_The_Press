extends GPUParticles2D

func setup(texture_path: String) -> void:
	# Carrega a textura correspondente à cor do bloco destruído
	texture = load(texture_path)
	
	# Inicia a emissão das partículas
	emitting = true
	
	# Aguarda o tempo de vida das partículas terminar e remove o nó da memória
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
