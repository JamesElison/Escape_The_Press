extends TextureButton

var is_holding: bool = false
@onready var spin_sound: AudioStreamPlayer = $SpinSound # ou AudioStreamPlayer2D

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	is_holding = true
	# Toca o som apenas se ele já não estiver tocando
	if spin_sound and not spin_sound.playing:
		spin_sound.play()

func _on_button_up() -> void:
	is_holding = false
	# Para o som imediatamente ao soltar o botão
	if spin_sound and spin_sound.playing:
		spin_sound.stop()

func _process(delta: float) -> void:
	if is_holding:
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("rotate_left"):
			player.rotate_left(delta)
