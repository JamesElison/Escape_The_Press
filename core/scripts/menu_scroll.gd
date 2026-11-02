extends ScrollContainer

var is_dragging: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		is_dragging = event.pressed
	elif event is InputEventScreenDrag and is_dragging:
		# Desloca o scroll verticalmente de forma suave com o movimento do dedo
		scroll_vertical = int(scroll_vertical - event.relative.y)
		accept_event() # Impede que o toque vaze para outros elementos abaixo
