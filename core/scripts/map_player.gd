extends Area2D

signal arrived_at_stop(stop_area: Area2D)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if area.name == "StopArea":
		arrived_at_stop.emit(area)

func _on_area_exited(_area: Area2D) -> void:
	pass
