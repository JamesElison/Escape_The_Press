extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "press":
		print("VITÓRIA! A prensa recuou até o topo!")
		# Chame a lógica de vitória do seu jogo aqui
