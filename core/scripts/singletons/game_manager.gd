extends Node

var just_beat_final_level: bool = false  # Flag de controle para a animação do portal no mapa

# --- DADOS PERSISTENTES DO JOGO ---
var current_level: int = 1
var press_speed: float = 2.0
var coins: int = 0

# --- CONTROLE DE ANÚNCIOS E VERSÃO PREMIUM ---
var is_premium: bool = false  # Futura versão Premium (remove anúncios)
var losses_since_last_ad: int = 0

# Lançadores (Itens equipáveis da lojinha)
var unlocked_launchers: Array[String] = ["marble"]
var equipped_launcher: String = "marble"

# --- SISTEMA DE TEMA TEMPORÁRIO (TESTE) ---
var temporary_launcher: String = ""  # Se preenchido, usa este lançador temporariamente
var temporary_launcher_levels_remaining: int = 0  # Rodadas restantes para o teste

# Armazena as configurações de áudio do jogador
var is_bgm_muted: bool = false
var is_sfx_muted: bool = false
var bgm_volume_linear: float = 1.0  
var sfx_volume_linear: float = 1.0  

# Armazena o nível individual em que o jogador parou em cada bioma/cenário (de 1 a 45)
var launcher_level_progress: Dictionary = {
	"crystal_palace": 1,
	"ancient_ruins": 1,
	"heavy_metal": 1,
	"sub_zero": 1
}

# --- ORDEM DOS CENÁRIOS (BIOMAS) PARA PROGRESSÃO DE MAPA ---
const LAUNCHER_ORDER: Array[String] = ["crystal_palace", "ancient_ruins", "heavy_metal", "sub_zero"]
var current_biome: String = "crystal_palace" # O bioma atual do mapa onde o jogador está jogando

const SAVE_PATH: String = "user://game_save.dat"
const END_GAME_SCENE_PATH: String = "res://core/scenes/levels/end_game_card.tscn"

# Catálogos de Recursos
var themes_catalog: Dictionary = {}          # Biomas (Cenários visuais e músicas de fundo)
var launcher_themes_catalog: Dictionary = {} # Lançadores, Projéteis, Blocos e Sons

func _ready() -> void:
	_load_themes()
	_load_launcher_themes()
	load_game_data()

# Carrega os biomas de cenário (ThemeData)
func _load_themes() -> void:
	themes_catalog["crystal_palace"] = load("res://core/resources/themes/theme_crystal_palace.tres")
	themes_catalog["ancient_ruins"] = load("res://core/resources/themes/theme_ancient_ruins.tres")
	themes_catalog["heavy_metal"] = load("res://core/resources/themes/theme_haevy_metal.tres")
	themes_catalog["sub_zero"] = load("res://core/resources/themes/theme_sub_zero.tres")

# Carrega os temas de lançadores da nova pasta dedicada (LauncherThemeData)
func _load_launcher_themes() -> void:
	launcher_themes_catalog["marble"] = load("res://core/resources/launcher_themes/launcher_marble.tres")
	launcher_themes_catalog["120mm"] = load("res://core/resources/launcher_themes/launcher_120mm.tres")
	launcher_themes_catalog["piercing"] = load("res://core/resources/launcher_themes/launcher_piercing.tres")
	launcher_themes_catalog["mini_plasma"] = load("res://core/resources/launcher_themes/launcher_mini_plasma.tres")

# Retorna o bioma/cenário atual baseado na progressão do mapa
func get_current_theme() -> ThemeData:
	if themes_catalog.has(current_biome):
		return themes_catalog[current_biome]
	return themes_catalog["crystal_palace"]

# Retorna os dados visuais/sonoros do lançador/munição equipado (ou em teste temporário)
func get_current_launcher_theme() -> LauncherThemeData:
	var active_key = equipped_launcher
	if temporary_launcher != "" and launcher_themes_catalog.has(temporary_launcher):
		active_key = temporary_launcher
		
	if launcher_themes_catalog.has(active_key):
		return launcher_themes_catalog[active_key]
	return launcher_themes_catalog["marble"]

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

# --- GERENCIAMENTO DE ANÚNCIOS (ADMOB) ---
# Chamado quando o jogador perde a partida
func register_loss() -> bool:
	if is_premium:
		return false
	
	losses_since_last_ad += 1
	if losses_since_last_ad >= 2:
		losses_since_last_ad = 0
		return true  # Hora de exibir Interstitial de Derrota
	return false

# Recompensa o jogador com 2.000 moedas após assistir ao anúncio de recompensa
func grant_ad_reward() -> void:
	add_coins(2000)

# --- TROCA DE LANÇADOR (BODYSHOP - PERMANENTE) ---
func equip_launcher_scenario(launcher_id: String) -> void:
	if launcher_themes_catalog.has(launcher_id):
		equipped_launcher = launcher_id
		temporary_launcher = ""
		temporary_launcher_levels_remaining = 0
		EventBus.launcher_changed.emit(equipped_launcher)
		save_game_data()

# --- TESTAR LANÇADOR TEMPORARIAMENTE POR X RODADAS ---
func equip_temporary_launcher(launcher_id: String, rounds: int) -> void:
	if launcher_themes_catalog.has(launcher_id):
		temporary_launcher = launcher_id
		temporary_launcher_levels_remaining = rounds
		EventBus.launcher_changed.emit(temporary_launcher)
		save_game_data()

# --- CÁLCULO DA VELOCIDADE DA PRENSA ---
func _recalculate_press_speed() -> void:
	var level_in_cycle = clamp(current_level, 1, 45)
	press_speed = 2.0 + ((level_in_cycle - 1) * 0.1)

# A CENA MAP CHAMA ESTA FUNÇÃO: Define qual parada foi selecionada e salva
func set_level_from_stop(stop_number: int) -> void:
	current_level = clamp(stop_number, 1, 45)
	launcher_level_progress[current_biome] = current_level
	_recalculate_press_speed()
	save_game_data()

# --- PROGRESSÃO DE NÍVEL ---
func reset_level_progress() -> void:
	current_level = 1
	launcher_level_progress[current_biome] = 1
	_recalculate_press_speed()
	save_game_data()

# Chamado quando o jogador vence a gameplay
func advance_to_next_level() -> void:
	if current_level >= 45:
		just_beat_final_level = true
		current_level = 45
		launcher_level_progress[current_biome] = 45
	else:
		current_level += 1
		launcher_level_progress[current_biome] = current_level

	_recalculate_press_speed()
	
	# Decrementa o teste temporário de lançador, se houver
	if temporary_launcher_levels_remaining > 0:
		temporary_launcher_levels_remaining -= 1
		if temporary_launcher_levels_remaining <= 0:
			temporary_launcher = ""
			EventBus.launcher_changed.emit(equipped_launcher)

	save_game_data()

# Chamado pelo map.gd APÓS o player entrar no portal e a animação terminar
func finalize_cycle_advancement() -> void:
	just_beat_final_level = false
	
	if current_biome == "sub_zero":
		_check_and_advance_biome()
		call_deferred("_change_to_end_game_scene")
	else:
		_check_and_advance_biome()

func _change_to_end_game_scene() -> void:
	get_tree().change_scene_to_file(END_GAME_SCENE_PATH)

# --- TROCA AUTOMÁTICA DE BIOMA NA VIRADA DE CICLO ---
func _check_and_advance_biome() -> void:
	launcher_level_progress[current_biome] = 1

	var current_index = LAUNCHER_ORDER.find(current_biome)
	if current_index != -1:
		var next_index = (current_index + 1) % LAUNCHER_ORDER.size()
		current_biome = LAUNCHER_ORDER[next_index]
		current_level = 1
		launcher_level_progress[current_biome] = 1

		save_game_data()

# --- CONTROLE DE ÁUDIO GLOBAL ---
func apply_audio_settings() -> void:
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus == -1:
		bgm_bus = AudioServer.get_bus_index("Music")
	
	if bgm_bus != -1:
		AudioServer.set_bus_mute(bgm_bus, is_bgm_muted)
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(bgm_volume_linear))

	var fx_bus = AudioServer.get_bus_index("fx")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("FX")
	if fx_bus == -1:
		fx_bus = AudioServer.get_bus_index("SFX")
		
	if fx_bus != -1:
		AudioServer.set_bus_mute(fx_bus, is_sfx_muted)
		AudioServer.set_bus_volume_db(fx_bus, linear_to_db(sfx_volume_linear))

# --- SISTEMA DE SAVE E LOAD ---
func save_game_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_dict = {
			"current_level": current_level,
			"press_speed": press_speed,
			"coins": coins,
			"is_premium": is_premium,
			"losses_since_last_ad": losses_since_last_ad,
			"unlocked_launchers": unlocked_launchers,
			"equipped_launcher": equipped_launcher,
			"current_biome": current_biome,
			"launcher_level_progress": launcher_level_progress,
			"temporary_launcher": temporary_launcher,
			"temporary_launcher_levels_remaining": temporary_launcher_levels_remaining,
			"is_bgm_muted": is_bgm_muted,
			"is_sfx_muted": is_sfx_muted,
			"bgm_volume_linear": bgm_volume_linear,
			"sfx_volume_linear": sfx_volume_linear,
			"just_beat_final_level": just_beat_final_level
		}
		file.store_var(save_dict)

func load_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_dict = file.get_var()
			if save_dict is Dictionary:
				coins = save_dict.get("coins", 0)
				is_premium = save_dict.get("is_premium", false)
				losses_since_last_ad = save_dict.get("losses_since_last_ad", 0)
				
				var raw_launchers = save_dict.get("unlocked_launchers", ["marble"])
				unlocked_launchers.clear()
				for l in raw_launchers:
					unlocked_launchers.append(str(l))
					
				equipped_launcher = save_dict.get("equipped_launcher", "marble")
				current_biome = save_dict.get("current_biome", "crystal_palace")
				launcher_level_progress = save_dict.get("launcher_level_progress", {
					"crystal_palace": 1,
					"ancient_ruins": 1,
					"heavy_metal": 1,
					"sub_zero": 1
				})
				
				temporary_launcher = save_dict.get("temporary_launcher", "")
				temporary_launcher_levels_remaining = save_dict.get("temporary_launcher_levels_remaining", 0)
				
				is_bgm_muted = save_dict.get("is_bgm_muted", false)
				is_sfx_muted = save_dict.get("is_sfx_muted", false)
				bgm_volume_linear = save_dict.get("bgm_volume_linear", 1.0)
				sfx_volume_linear = save_dict.get("sfx_volume_linear", 1.0)
				just_beat_final_level = save_dict.get("just_beat_final_level", false)
				
				current_level = launcher_level_progress.get(current_biome, 1)
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
	is_premium = false
	losses_since_last_ad = 0
	unlocked_launchers = ["marble"]
	equipped_launcher = "marble"
	current_biome = "crystal_palace"
	temporary_launcher = ""
	temporary_launcher_levels_remaining = 0
	is_bgm_muted = false
	is_sfx_muted = false
	bgm_volume_linear = 1.0
	sfx_volume_linear = 1.0
	just_beat_final_level = false
	launcher_level_progress = {
		"crystal_palace": 1,
		"ancient_ruins": 1,
		"heavy_metal": 1,
		"sub_zero": 1
	}

	apply_audio_settings()
	EventBus.coins_updated.emit(coins)
	EventBus.launcher_changed.emit(equipped_launcher)

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
