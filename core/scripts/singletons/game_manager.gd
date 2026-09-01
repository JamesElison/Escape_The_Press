extends Node

# Variáveis globais salvas entre cenas
var current_level: int = 1
var press_speed: float = 3.0

# Reseta o progresso quando o jogador perde totalmente e recomeça do Level 1
func reset_game_data() -> void:
	current_level = 1
	press_speed = 3.0

# Incrementa a dificuldade para o próximo nível
func advance_to_next_level() -> void:
	current_level += 1
	press_speed += 2.0
