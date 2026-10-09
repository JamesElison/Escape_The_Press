extends Node

# --- DADOS PERSISTENTES DO JOGO ---
var current_level: int = 1
var press_speed: float = 2.0
var coins: int = 0

var unlocked_launchers: Array[String] = ["crystal_palace"]
var equipped_launcher: String = "crystal_palace"

# Armazena as configurações de áudio do jogador
var is_bgm_muted: bool = false
var is_sfx_muted: bool = false

 #Armazena o nível individual em que o jogador parou em cada lançador/cenário (de 1 a 45)
var launcher_level_progress: Dictionary = {
	"crystal_palace": 1,
	"ancient_ruins": 1,
	"heavy_metal": 1,
	"sub_zero": 1
}

var called_from_the_start_menu = false

# --- ORDEM DOS LANÇADORES/CENÁRIOS ---
const LAUNCHER_ORDER: Array[String] = ["crystal_palace", "ancient_ruins", "heavy_metal", "sub_zero"]

const SAVE_PATH: String = "user://game_save.dat"

# Catálogo de temas carregados
var themes_catalog: Dictionary = {}

func _ready() -> void:
	_load_themes()
	load_game_data()

func _load_themes() -> void:
	themes_catalog["crystal_palace"] = load("res://core/resources/themes/theme_crystal_palace.tres")
	themes_catalog["ancient_ruins"] = load("res://core/resources/themes/theme_ancient_ruins.tres")
	themes_catalog["heavy_metal"] = load("res://core/resources/themes/theme_haevy_metal.tres")
	themes_catalog["sub_zero"] = load("res://core/resources/themes/theme_sub_zero.tres")

func get_current_theme() -> ThemeData:
	if themes_catalog.has(equipped_launcher):
		return themes_catalog[equipped_launcher]
	return themes_catalog["crystal_palace"]

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
	launcher_level_progress[equipped_launcher] = current_level
	equipped_launcher = launcher_id
	current_level = launcher_level_progress.get(launcher_id, 1)
	_recalculate_press_speed()
	save_game_data()

# --- CÁLCULO DA VELOCIDADE DA PRENSA ---
# StopSprite_1 -> 2.0 | StopSprite_2 -> 2.1 | StopSprite_3 -> 2.2
func _recalculate_press_speed() -> void:
	var level_in_cycle = clamp(current_level, 1, 45)
	press_speed = 2.0 + ((level_in_cycle - 1) * 0.1)

# A CENA MAP CHAMA ESTA FUNÇÃO: Define qual parada foi selecionada e salva
func set_level_from_stop(stop_number: int) -> void:
	current_level = clamp(stop_number, 1, 45)
	launcher_level_progress[equipped_launcher] = current_level
	_recalculate_press_speed()
	save_game_data()

# --- PROGRESSÃO DE NÍVEL ---
func reset_level_progress() -> void:
	current_level = 1
	launcher_level_progress[equipped_launcher] = 1
	_recalculate_press_speed()
	save_game_data()

# Chamado quando o jogador vence a gameplay
func advance_to_next_level() -> void:
	if current_level >= 45:
		_check_and_advance_scenario()
	else:
		current_level += 1
		launcher_level_progress[equipped_launcher] = current_level

	_recalculate_press_speed()
	add_coins(500)
	save_game_data()

# --- TROCA AUTOMÁTICA DE CENÁRIO/LANÇADOR NA VIRADA DE CICLO ---
func _check_and_advance_scenario() -> void:
	launcher_level_progress[equipped_launcher] = 1

	var current_index = LAUNCHER_ORDER.find(equipped_launcher)
	if current_index != -1:
		var next_index = (current_index + 1) % LAUNCHER_ORDER.size()
		var next_launcher = LAUNCHER_ORDER[next_index]
		
		if not unlocked_launchers.has(next_launcher):
			unlocked_launchers.append(next_launcher)
			
		equipped_launcher = next_launcher
		current_level = 1
		launcher_level_progress[equipped_launcher] = 1

		EventBus.launcher_changed.emit(equipped_launcher)

# --- CONTROLE DE ÁUDIO GLOBAL ---
func apply_audio_settings() -> void:
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus == -1:
		bgm_bus = AudioServer.get_bus_index("Music")
	if bgm_bus != -1:
		AudioServer.set_bus_mute(bgm_bus, is_bgm_muted)

	var fx_bus = AudioServer.get_bus_index("fx")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("FX")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("SFX")
	if fx_bus != -1:
		AudioServer.set_bus_mute(fx_bus, is_sfx_muted)

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
			"launcher_level_progress": launcher_level_progress,
			"is_bgm_muted": is_bgm_muted,
			"is_sfx_muted": is_sfx_muted
		}
		file.store_var(save_dict)

func load_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_dict = file.get_var()
			if save_dict is Dictionary:
				coins = save_dict.get("coins", 0)
				
				var raw_launchers = save_dict.get("unlocked_launchers", ["crystal_palace"])
				unlocked_launchers.clear()
				for l in raw_launchers:
					unlocked_launchers.append(str(l))
					
				equipped_launcher = save_dict.get("equipped_launcher", "crystal_palace")
				launcher_level_progress = save_dict.get("launcher_level_progress", {
					"crystal_palace": 1,
					"ancient_ruins": 1,
					"heavy_metal": 1,
					"sub_zero": 1
				})
				
				is_bgm_muted = save_dict.get("is_bgm_muted", false)
				is_sfx_muted = save_dict.get("is_sfx_muted", false)
				
				current_level = launcher_level_progress.get(equipped_launcher, 1)
				_recalculate_press_speed()
				apply_audio_settings()

func reset_all_save_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("game_save.dat")

	current_level = 1
	press_speed = 2.0
	coins = 0
	unlocked_launchers = ["crystal_palace"]
	equipped_launcher = "crystal_palace"
	is_bgm_muted = false
	is_sfx_muted = false
	launcher_level_progress = {
		"crystal_palace": 1,
		"ancient_ruins": 1,
		"heavy_metal": 1,
		"sub_zero": 1
	}

	apply_audio_settings()
	EventBus.coins_updated.emit(coins)
	EventBus.launcher_changed.emit(equipped_launcher)

# --- REPRODUÇÃO PERSISTENTE DE ÁUDIO ---
func play_sfx_persistent(stream: AudioStream) -> void:
	if not stream or is_sfx_muted:
		return
		
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = stream
	
	var fx_bus = AudioServer.get_bus_index("fx")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("FX")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("SFX")
		
	if fx_bus != -1:
		temp_player.bus = AudioServer.get_bus_name(fx_bus)
		
	get_tree().root.add_child(temp_player)
	temp_player.play()
	
	temp_player.finished.connect(temp_player.queue_free)
