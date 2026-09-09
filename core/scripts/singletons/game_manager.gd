extends Node

# --- DADOS PERSISTENTES DO JOGO ---
var current_level: int = 1
var press_speed: float = 3.0
var coins: int = 0

var unlocked_launchers: Array[String] = ["launcher_default"]
var equipped_launcher: String = "launcher_default"

const SAVE_PATH: String = "user://game_save.dat"

func _ready() -> void:
	load_game_data()

# Detecta quando o jogador fecha a janela (PC) ou minimiza/fecha o app (Android)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game_data()

# --- GERENCIAMENTO DE MOEDAS ---
func add_coins(amount: int) -> void:
	coins += amount
	EventBus.coins_updated.emit(coins)
	save_game_data()

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		EventBus.coins_updated.emit(coins)
		save_game_data()
		return true
	return false

# --- PROGRESSÃO DE NÍVEL ---
# Chamado APENAS quando dá Game Over real e você decide voltar a estaca zero
func reset_level_progress() -> void:
	current_level = 1
	press_speed = 3.0
	save_game_data()

func advance_to_next_level() -> void:
	current_level += 1
	press_speed += 0.2
	add_coins(500) # Recompensa por passar de nível
	save_game_data()

# --- SISTEMA DE SAVE E LOAD ---
func save_game_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_dict = {
			"current_level": current_level,
			"press_speed": press_speed,
			"coins": coins,
			"unlocked_launchers": unlocked_launchers,
			"equipped_launcher": equipped_launcher
		}
		file.store_var(save_dict)

func load_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_dict = file.get_var()
			if save_dict is Dictionary:
				current_level = save_dict.get("current_level", 1)
				
				# Recalcula a velocidade da prensa com base no nível salvo
				press_speed = 3.0 + ((current_level - 1) * 0.2)
				
				coins = save_dict.get("coins", 0)
				
				var raw_launchers = save_dict.get("unlocked_launchers", ["launcher_default"])
				unlocked_launchers.clear()
				for l in raw_launchers:
					unlocked_launchers.append(str(l))
					
				equipped_launcher = save_dict.get("equipped_launcher", "launcher_default")
