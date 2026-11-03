extends ScrollContainer

var is_dragging: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		is_dragging = event.pressed
	elif event is InputEventScreenDrag and is_dragging:
		# Desloca a barra de rolagem verticalmente com o movimento do dedo
		scroll_vertical = int(scroll_vertical - event.relative.y)
		accept_event()

# Também garante que toques diretos nos filhos/netos passem o evento de arrastamento para cima
func _can_drop_data(_at_position: Vector2, _data) -> bool:
	return false
