extends Area2D

signal arrived_at_stop(stop_area: Area2D)
signal in_transit(stop_area: Area2D)

@onready var sprite = $Sprite

func _ready() -> void:
	update_launcher_sprite()

func update_launcher_sprite(_launcher_id: String = "") -> void:
	var launcher_theme = GameManager.get_current_launcher_theme()
	if launcher_theme and launcher_theme.launcher_map_texture:
		sprite.texture = launcher_theme.launcher_map_texture

func _on_area_entered(area: Area2D) -> void:
	if area.name.begins_with("StopArea"):
		arrived_at_stop.emit(area)

func _on_area_exited(area: Area2D) -> void:
	if area.name.begins_with("StopArea"):
		in_transit.emit(area)
