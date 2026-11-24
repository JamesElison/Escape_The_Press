extends Node2D

@onready var stop_deactivation_sound: AudioStreamPlayer = $StopDeactivation
@onready var stop_sprite: Sprite2D = $StopSprite
@onready var stop_vortex: ColorRect = $StopVortex
@onready var stop_energy_stop: AnimatedSprite2D = $StopEnergyStop
@onready var stop_area: Area2D = $StopArea
@onready var stop_label: Label = $StopLabel

var stop_number: int = 1

func _ready() -> void:
	# Atualiza a textura da prensa conforme o ThemeData ativo
	update_stopsprite_texture()
	
	_update_label_from_name()

func update_stopsprite_texture() -> void:
	var theme = GameManager.get_current_launcher_theme()
	if stop_sprite and theme and theme.stop_texture:
		stop_sprite.texture = theme.stop_texture

# Extrai o número do nó ("StopSprite_23" -> 23) e atualiza o texto do Label
func _update_label_from_name() -> void:
	var name_string = String(name)
	if name_string.begins_with("StopSprite_"):
		var num_str = name_string.replace("StopSprite_", "")
		if num_str.is_valid_int():
			stop_number = num_str.to_int()
			if stop_label:
				stop_label.text = str(stop_number)

# Aplica as regras de visibilidade e seleção da animação de bônus
func setup_state(current_level: int) -> void:
	# Se já passamos da 45 ou se o ciclo final foi batido, esconde tudo na parada 45
	if stop_number == 45 and (current_level > 45 or (GameManager and GameManager.just_beat_final_level)):
		stop_vortex.visible = false
		stop_energy_stop.visible = false
		return

	# Define qual animação o AnimatedSprite2D deve rodar nas casas de bônus (10, 20, 30, 40)
	if is_instance_valid(stop_energy_stop):
		if stop_number in [10, 15, 25, 30, 35, 40]:
			if stop_energy_stop.sprite_frames and stop_energy_stop.sprite_frames.has_animation("bonus"):
				stop_energy_stop.play("bonus")
		else:
			if stop_energy_stop.sprite_frames and stop_energy_stop.sprite_frames.has_animation("default"):
				stop_energy_stop.play("default")

	if stop_number < current_level:
		# Níveis passados (1 até current_level - 1): Escondem ambos
		stop_vortex.visible = false
		stop_energy_stop.visible = false
	elif stop_number == current_level:
		# Nível atual a ser jogado: Mostra ambos
		stop_vortex.visible = true
		stop_energy_stop.visible = true
	else:
		# Níveis futuros (current_level + 1 até 45): Mostra apenas o vortex
		stop_vortex.visible = true
		stop_energy_stop.visible = false
