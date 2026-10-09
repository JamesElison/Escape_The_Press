extends Area2D

# Sinal emitido quando o jogador chega a uma parada
signal arrived_at_stop(stop_area: Area2D)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	# Detecta quando o MapPlayer entra na StopArea de uma parada
	if area.name == "StopArea":
		arrived_at_stop.emit(area)

func _on_area_exited(_area: Area2D) -> void:
	pass
