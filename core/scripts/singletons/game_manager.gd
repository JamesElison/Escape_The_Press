extends Node

# --- DADOS PERSISTENTES DO JOGO ---
var current_level: int = 1
var press_speed: float = 2.0
var coins: int = 10000

var unlocked_launchers: Array[String] = ["Standart"]
var equipped_launcher: String = "Standart"

# Armazena o nível individual em que o jogador parou em cada lançador/cenário
var launcher_level_progress: Dictionary = {
	"Standart": 1,
	"120mm": 1,
	"piercing": 1,
	"mini_plasma": 1
}

const SAVE_PATH: String = "user://game_save.dat"

# Catálogo de temas carregados
var themes_catalog: Dictionary = {}

func _ready() -> void:
	_load_themes()
	load_game_data()

func _load_themes() -> void:
	themes_catalog["Standart"] = load("res://core/resources/themes/theme_crystal_palace.tres")
	themes_catalog["120mm"] = load("res://core/resources/themes/theme_ancient_ruins.tres")
	themes_catalog["piercing"] = load("res://core/resources/themes/theme_heavy_metal.tres")
	themes_catalog["mini_plasma"] = load("res://core/resources/themes/theme_sub_zero.tres")

func get_current_theme() -> ThemeData:
	if themes_catalog.has(equipped_launcher):
		return themes_catalog[equipped_launcher]
	return themes_catalog["Standart"]

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

# --- TROCA DE LANÇADOR (MODO TESTE E BODYSHOP) ---
func equip_launcher_scenario(launcher_id: String) -> void:
	# 1. Salva o nível alcançado no lançador atual
	launcher_level_progress[equipped_launcher] = current_level
	
	# 2. Equipa o novo lançador
	equipped_launcher = launcher_id
	
	# 3. Restaura o nível salvo do novo lançador
	current_level = launcher_level_progress.get(launcher_id, 1)
	
	# 4. Recalcula a velocidade da prensa com base no ciclo de 45 levels (2.0 a 6.4 px/s)
	_recalculate_press_speed()
	save_game_data()

func _recalculate_press_speed() -> void:
	var level_in_cycle = ((current_level - 1) % 45) + 1
	press_speed = 2.0 + ((level_in_cycle - 1) * 0.1)

# --- PROGRESSÃO DE NÍVEL ---
func reset_level_progress() -> void:
	current_level = 1
	launcher_level_progress[equipped_launcher] = 1
	_recalculate_press_speed()
	save_game_data()

func advance_to_next_level() -> void:
	current_level += 1
	launcher_level_progress[equipped_launcher] = current_level
	
	_recalculate_press_speed()
	add_coins(500)
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
			"equipped_launcher": equipped_launcher,
			"launcher_level_progress": launcher_level_progress
		}
		file.store_var(save_dict)

func load_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_dict = file.get_var()
			if save_dict is Dictionary:
				coins = save_dict.get("coins", 10000)
				
				var raw_launchers = save_dict.get("unlocked_launchers", ["Standart"])
				unlocked_launchers.clear()
				for l in raw_launchers:
					unlocked_launchers.append(str(l))
					
				equipped_launcher = save_dict.get("equipped_launcher", "Standart")
				launcher_level_progress = save_dict.get("launcher_level_progress", {
					"Standart": 1,
					"120mm": 1,
					"piercing": 1,
					"mini_plasma": 1
				})
				
				current_level = launcher_level_progress.get(equipped_launcher, 1)
				_recalculate_press_speed()

func reset_all_save_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("game_save.dat")

	current_level = 1
	press_speed = 2.0
	coins = 10000
	unlocked_launchers = ["Standart"]
	equipped_launcher = "Standart"
	launcher_level_progress = {
		"Standart": 1,
		"120mm": 1,
		"piercing": 1,
		"mini_plasma": 1
	}

	EventBus.coins_updated.emit(coins)
	EventBus.launcher_changed.emit(equipped_launcher)
