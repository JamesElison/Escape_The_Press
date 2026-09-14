extends Button

var is_holding: bool = false

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	is_holding = true

func _on_button_up() -> void:
	is_holding = false

func _process(delta: float) -> void:
	if is_holding:
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("rotate_right"):
			player.rotate_right(delta)
