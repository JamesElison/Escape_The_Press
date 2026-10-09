extends Sprite2D

@onready var stop_deactivation_sound: AudioStreamPlayer = $StopDeactivation
@onready var stop_vortex: ColorRect = $StopVortex
@onready var stop_energy_stop: AnimatedSprite2D = $StopEnergyStop
@onready var stop_area: Area2D = $StopArea
@onready var stop_label: Label = $StopLabel

# Armazena o número desta parada (ex: 1, 23, 45)
var stop_number: int = 1

func _ready() -> void:
	_update_label_from_name()

# Extrai o número do nome do nó ("StopSprite_23" -> 23) e escreve no Label
func _update_label_from_name() -> void:
	var name_string = String(name)
	if name_string.begins_with("StopSprite_"):
		var num_str = name_string.replace("StopSprite_", "")
		if num_str.is_valid_int():
			stop_number = num_str.to_int()
			if stop_label:
				stop_label.text = str(stop_number)

# Atualiza a visibilidade dos elementos de acordo com a fase atual do jogador
func setup_state(current_level: int) -> void:
	if stop_number < current_level:
		# FASES JÁ VENCIDAS (1 até current_level - 1): Escondem ambos
		stop_vortex.visible = false
		stop_energy_stop.visible = false
	elif stop_number == current_level:
		# FASE ATUAL A JOGAR: Mostra vortex e energy_stop
		stop_vortex.visible = true
		stop_energy_stop.visible = true
	else:
		# FASES FUTURAS (current_level + 1 em diante): Mostra apenas o vortex
		stop_vortex.visible = true
		stop_energy_stop.visible = false

func _on_stop_area_area_entered(area: Area2D) -> void:
	pass

func _on_stop_area_area_exited(area: Area2D) -> void:
	pass
