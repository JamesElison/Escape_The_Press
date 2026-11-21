extends Node

var just_beat_final_level: bool = false  # Flag de controle para a animação do portal no mapa

# --- CONTROLE DO MODO DEMONSTRAÇÃO (ATTRACT MODE) ---
var is_attract_mode: bool = false      # True quando o jogo está rodando a demo sozinho[cite: 16]
var is_recording_demo: bool = false    # True quando VOCÊ está gravando uma demo para salvar[cite: 16]

# Lista com os arquivos de demonstração disponíveis no projeto
const DEMO_FILES: Array[String] = [
	"res://core/resources/demo_replay_1.json",
	"res://core/resources/demo_replay_2.json",
	"res://core/resources/demo_replay_3.json"
]
var current_demo_index: int = 0 # Controla qual demo vai tocar na vez[cite: 16]

# --- NÍVEIS DE DIFICULDADE GERENCIADOS POR MENU ---
var easy_difficulty_mode = true
var medium_difficulty_mode = false
var hard_difficulty_mode = false

# --- LINGUAGEM SELECIONADA ---
var english = true
var portuguese = false
var mandarin = false
var spanish = false

# --- DADOS PERSISTENTES DO JOGO ---
var current_level: int = 1
var press_speed: float = 0.0
var coins: int = 0  # Conta definitiva do jogador (persiste no save)[cite: 16]

# --- CONTA PROVISÓRIA DA PARTIDA ---
var match_coins: int = 0  # Conta temporária da partida atual (inicia zerada)[cite: 16]

# --- CONTROLE DE ANÚNCIOS E VERSÃO PREMIUM ---
var is_premium: bool = false  # Futura versão Premium (remove anúncios)[cite: 16]
var losses_since_last_ad: int = 0

# Lançadores (Itens equipáveis da lojinha)
var unlocked_launchers: Array[String] = ["marble"]
var equipped_launcher: String = "marble"

# --- SISTEMA DE TEMA TEMPORÁRIO (TESTE) ---
var temporary_launcher: String = ""  # Se preenchido, usa este lançador temporariamente[cite: 16]
var temporary_launcher_levels_remaining: int = 0  # Rodadas restantes para o teste[cite: 16]
var used_temporary_launchers: Array[String] = []  # Histórico de temporários já sorteados no ciclo[cite: 16]

# Armazena as configurações de áudio do jogador
var is_bgm_muted: bool = false
var is_sfx_muted: bool = false
var bgm_volume_linear: float = 1.0  
var sfx_volume_linear: float = 1.0  

# Armazena o nível individual em que o jogador parou em cada bioma/cenário (de 1 a 45)[cite: 16]
var launcher_level_progress: Dictionary = {
	"crystal_palace": 1,
	"ancient_ruins": 1,
	"heavy_metal": 1,
	"sub_zero": 1,
	"seabed": 1,
	"desert": 1,
	"house": 1,
	"space": 1
}

# Biomas que já tiveram a 45ª casa concluída pelo jogador[cite: 16]
var completed_biomes: Array[String] = []

# Controla se o jogador já fez uma revisita posterior à conclusão da 45ª casa em cada bioma[cite: 16]
var revisited_after_completion: Dictionary = {}

# --- ORDEM DOS CENÁRIOS (BIOMAS) PARA PROGRESSÃO DE MAPA ---
const LAUNCHER_ORDER: Array[String] = ["crystal_palace", "ancient_ruins", "heavy_metal", "sub_zero", "seabed", "desert", "house", "space"]
var current_biome: String = "crystal_palace" # O bioma atual do mapa onde o jogador está jogando[cite: 16]

const SAVE_PATH: String = "user://game_save.dat"
const END_GAME_SCENE_PATH: String = "res://core/scenes/levels/end_game_card.tscn"

# Catálogos de Recursos
var themes_catalog: Dictionary = {}          # Biomas (Cenários visuais e músicas de fundo)[cite: 16]
var launcher_themes_catalog: Dictionary = {} # Lançadores, Projéteis, Blocos e Sons[cite: 16]

func _ready() -> void:
	_load_themes()
	_load_launcher_themes()
	load_game_data()
	_recalculate_press_speed()
	reset_match_coins()
	apply_language_settings()


# Carrega os biomas de cenário (ThemeData)
func _load_themes() -> void:
	themes_catalog["crystal_palace"] = load("res://core/resources/themes/theme_crystal_palace.tres")
	themes_catalog["ancient_ruins"] = load("res://core/resources/themes/theme_ancient_ruins.tres")
	themes_catalog["heavy_metal"] = load("res://core/resources/themes/theme_haevy_metal.tres")
	themes_catalog["sub_zero"] = load("res://core/resources/themes/theme_sub_zero.tres")
	themes_catalog["seabed"] = load("res://core/resources/themes/theme_seabed.tres")
	themes_catalog["desert"] = load("res://core/resources/themes/theme_desert.tres")
	themes_catalog["house"] = load("res://core/resources/themes/theme_house.tres")
	themes_catalog["space"] = load("res://core/resources/themes/theme_space.tres")

# Carrega os temas de lançadores da nova pasta dedicada (LauncherThemeData)[cite: 16]
func _load_launcher_themes() -> void:
	launcher_themes_catalog["marble"] = load("res://core/resources/launcher_themes/launcher_marble.tres")
	launcher_themes_catalog["120mm"] = load("res://core/resources/launcher_themes/launcher_120mm.tres")
	launcher_themes_catalog["piercing"] = load("res://core/resources/launcher_themes/launcher_piercing.tres")
	launcher_themes_catalog["mini_plasma"] = load("res://core/resources/launcher_themes/launcher_mini_plasma.tres")
	launcher_themes_catalog["flame"] = load("res://core/resources/launcher_themes/launcher_flame.tres")
	launcher_themes_catalog["high_voltage"] = load("res://core/resources/launcher_themes/launcher_hig_voltage.tres")
	launcher_themes_catalog["high_voltage"] = load("res://core/resources/launcher_themes/launcher_high_voltage.tres")
	launcher_themes_catalog["fire_fighter"] = load("res://core/resources/launcher_themes/launcher_fire_fighter.tres")
	launcher_themes_catalog["laser_beam"] = load("res://core/resources/launcher_themes/launcher_laser_beam.tres")
	launcher_themes_catalog["ice_cube"] = load("res://core/resources/launcher_themes/launcher_ice_cube.tres")
	launcher_themes_catalog["dart"] = load("res://core/resources/launcher_themes/launcher_dart.tres")

# Retorna o bioma/cenário atual baseado na progressão do mapa
func get_current_theme() -> ThemeData:
	if themes_catalog.has(current_biome):
		return themes_catalog[current_biome]
	return themes_catalog["crystal_palace"]

# Retorna os dados visuais/sonoros do lançador/munição equipado (ou em teste temporário)[cite: 16]
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

# --- GERENCIAMENTO DE MOEDAS DA PARTIDA E DEFINITIVAS ---

# Reseta e inicia a conta provisória da partida zerada (chamada ao entrar em uma fase)[cite: 16]
func reset_match_coins() -> void:
	match_coins = 0
	# Não atualizamos a HUD da partida com valores provisórios, mantendo a permanente visível[cite: 16]

# Adiciona moedas à conta provisória da partida (sem atualizar a HUD da cena coin)[cite: 16]
func add_match_coins(amount: int) -> void:
	match_coins += amount

# Remove moedas da conta provisória da partida (penalidade de erro, sem atualizar a HUD da cena coin)[cite: 16]
func remove_match_coins(amount: int) -> bool:
	if match_coins >= amount:
		match_coins -= amount
	else:
		match_coins = 0  # Evita saldo negativo na partida[cite: 16]
	return true

# Consolida os ganhos da partida na conta definitiva ao vencer e atualiza a HUD[cite: 16]
func claim_match_coins() -> void:
	if match_coins > 0:
		coins += match_coins
		match_coins = 0
		save_game_data()
		EventBus.coins_updated.emit(coins) # Atualiza a cena coin ao vencer[cite: 16]

# Descarta os ganhos da partida ao perder ou fechar sem vencer[cite: 16]
func discard_match_coins() -> void:
	match_coins = 0

# --- GERENCIAMENTO DE MOEDAS (DEFINITIVAS / COMPRAS / RECOMPENSAS) ---
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
func register_loss() -> bool:
	if is_premium:
		return false
	
	losses_since_last_ad += 1
	if losses_since_last_ad >= 2:
		losses_since_last_ad = 0
		return true  # Hora de exibir Interstitial de Derrota[cite: 16]
	return false

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

# --- CONTROLE DE BIOMAS CONQUISTADOS E SELEÇÃO PELA BIOME_SHOP ---
func is_biome_completed(biome_id: String) -> bool:
	return biome_id in completed_biomes

func can_join_biome(biome_id: String) -> bool:
	if not biome_id in LAUNCHER_ORDER:
		return false
	return biome_id == current_biome or is_biome_completed(biome_id)

func mark_biome_completed(biome_id: String) -> void:
	if biome_id in LAUNCHER_ORDER and not biome_id in completed_biomes:
		completed_biomes.append(biome_id)
	revisited_after_completion[biome_id] = false

func select_biome_from_shop(biome_id: String) -> bool:
	if not can_join_biome(biome_id):
		return false

	# Salva o nível em que estava no bioma anterior antes de trocar[cite: 16]
	if current_biome in LAUNCHER_ORDER:
		launcher_level_progress[current_biome] = clamp(int(current_level), 1, 45)

	# Se já estiver no bioma selecionado, mantém o progresso exato onde parou[cite: 16]
	if biome_id == current_biome:
		current_level = clamp(int(launcher_level_progress.get(biome_id, current_level)), 1, 45)
		launcher_level_progress[biome_id] = current_level
		_recalculate_press_speed()
		save_game_data()
		return true

	current_biome = biome_id

	# Primeira revisita após concluir a 45ª casa: inicia na casa 1[cite: 16]
	if not revisited_after_completion.get(biome_id, false):
		revisited_after_completion[biome_id] = true
		current_level = 1
		launcher_level_progress[biome_id] = 1
	else:
		# Revisitas seguintes: retorna para a última casa salva nesse bioma[cite: 16]
		current_level = clamp(int(launcher_level_progress.get(biome_id, 1)), 1, 45)
		launcher_level_progress[biome_id] = current_level

	_recalculate_press_speed()
	save_game_data()
	return true

# --- TESTAR LANÇADOR TEMPORARIAMENTE POR X RODADAS ---
func equip_temporary_launcher(launcher_id: String, rounds: int) -> void:
	if launcher_themes_catalog.has(launcher_id):
		temporary_launcher = launcher_id
		temporary_launcher_levels_remaining = rounds
		EventBus.launcher_changed.emit(temporary_launcher)
		save_game_data()

# --- SORTEIO INTELIGENTE DE LANÇADOR TEMPORÁRIO ---
func get_next_temporary_launcher() -> String:
	var available_keys: Array = []
	
	for key in launcher_themes_catalog.keys():
		if key != "marble" and not key in unlocked_launchers and not key in used_temporary_launchers:
			available_keys.append(key)
			
	if available_keys.is_empty():
		used_temporary_launchers.clear()
		for key in launcher_themes_catalog.keys():
			if key != "marble" and not key in unlocked_launchers:
				available_keys.append(key)
				
	if available_keys.is_empty():
		return ""
		
	available_keys.shuffle()
	var chosen_theme = available_keys[0]
	
	used_temporary_launchers.append(chosen_theme)
	save_game_data()
	
	return chosen_theme

# --- CÁLCULO DA VELOCIDADE DA PRENSA ---
func _recalculate_press_speed() -> void:
	var level_in_cycle = clamp(current_level, 1, 45)
	
	if easy_difficulty_mode:
		press_speed = 2.0 + ((level_in_cycle - 1) * 0.1)
	elif medium_difficulty_mode:
		press_speed = 3.0 + ((level_in_cycle - 1) * 0.2)
	elif hard_difficulty_mode:
		press_speed = 4.0 + ((level_in_cycle - 1) * 0.25)

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

func advance_to_next_level() -> void:
	if current_level >= 45:
		just_beat_final_level = true
		current_level = 45
		launcher_level_progress[current_biome] = 45
		mark_biome_completed(current_biome)
	else:
		current_level += 1
		launcher_level_progress[current_biome] = current_level

	_recalculate_press_speed()
	
	if temporary_launcher_levels_remaining > 0:
		temporary_launcher_levels_remaining -= 1
		if temporary_launcher_levels_remaining <= 0:
			temporary_launcher = ""
			EventBus.launcher_changed.emit(equipped_launcher)

	save_game_data()

func finalize_cycle_advancement() -> void:
	just_beat_final_level = false
	
	if current_biome == "space":
		_check_and_advance_biome()
		call_deferred("_change_to_end_game_scene")
	else:
		_check_and_advance_biome()

func _change_to_end_game_scene() -> void:
	get_tree().change_scene_to_file(END_GAME_SCENE_PATH)

func _check_and_advance_biome() -> void:
	mark_biome_completed(current_biome)
	launcher_level_progress[current_biome] = 1

	var current_index = LAUNCHER_ORDER.find(current_biome)
	if current_index != -1:
		var next_index = (current_index + 1) % LAUNCHER_ORDER.size()
		current_biome = LAUNCHER_ORDER[next_index]
		current_level = 1
		launcher_level_progress[current_biome] = 1

		save_game_data()

# --- CONTROLE DE IDIOMA GLOBAL ---
func apply_language_settings() -> void:
	var locale := "en"
	if portuguese:
		locale = "pt_BR"
	elif mandarin:
		locale = "zh"
	elif spanish:
		locale = "es"
	elif english:
		locale = "en"

	TranslationServer.set_locale(locale)

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
			"easy_difficulty_mode": easy_difficulty_mode,
			"medium_difficulty_mode": medium_difficulty_mode,
			"hard_difficulty_mode": hard_difficulty_mode,
			"english": english,
			"portuguese": portuguese,
			"mandarin": mandarin,
			"spanish": spanish,
			"current_level": current_level,
			"press_speed": press_speed,
			"coins": coins,
			"is_premium": is_premium,
			"losses_since_last_ad": losses_since_last_ad,
			"unlocked_launchers": unlocked_launchers,
			"equipped_launcher": equipped_launcher,
			"current_biome": current_biome,
			"launcher_level_progress": launcher_level_progress,
			"completed_biomes": completed_biomes,
			"revisited_after_completion": revisited_after_completion,
			"temporary_launcher": temporary_launcher,
			"temporary_launcher_levels_remaining": temporary_launcher_levels_remaining,
			"used_temporary_launchers": used_temporary_launchers,
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
				easy_difficulty_mode = save_dict.get("easy_difficulty_mode", true)
				medium_difficulty_mode = save_dict.get("medium_difficulty_mode", false)
				hard_difficulty_mode = save_dict.get("hard_difficulty_mode", false)

				english = save_dict.get("english", true)
				portuguese = save_dict.get("portuguese", false)
				mandarin = save_dict.get("mandarin", false)
				spanish = save_dict.get("spanish", false)
				
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
					"sub_zero": 1,
					"seabed": 1,
					"desert": 1,
					"house": 1,
					"space": 1
				})

				completed_biomes.clear()
				var raw_completed = save_dict.get("completed_biomes", [])
				for b in raw_completed:
					completed_biomes.append(str(b))

				revisited_after_completion = save_dict.get("revisited_after_completion", {})
				
				temporary_launcher = save_dict.get("temporary_launcher", "")
				temporary_launcher_levels_remaining = save_dict.get("temporary_launcher_levels_remaining", 0)
				
				var raw_used = save_dict.get("used_temporary_launchers", [])
				used_temporary_launchers.clear()
				for u in raw_used:
					used_temporary_launchers.append(str(u))
				
				is_bgm_muted = save_dict.get("is_bgm_muted", false)
				is_sfx_muted = save_dict.get("is_sfx_muted", false)
				bgm_volume_linear = save_dict.get("bgm_volume_linear", 1.0)
				sfx_volume_linear = save_dict.get("sfx_volume_linear", 1.0)
				just_beat_final_level = save_dict.get("just_beat_final_level", false)
				
				current_level = launcher_level_progress.get(current_biome, 1)
				_recalculate_press_speed()
				apply_audio_settings()
				apply_language_settings()

func reset_all_save_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("game_save.dat")

	easy_difficulty_mode = true
	medium_difficulty_mode = false
	hard_difficulty_mode = false
	english = true
	portuguese = false
	mandarin = false
	spanish = false
	current_level = 1
	press_speed = 2.0
	coins = 0
	match_coins = 0
	is_premium = false
	losses_since_last_ad = 0
	unlocked_launchers = ["marble"]
	equipped_launcher = "marble"
	current_biome = "crystal_palace"
	completed_biomes.clear()
	revisited_after_completion.clear()
	temporary_launcher = ""
	temporary_launcher_levels_remaining = 0
	used_temporary_launchers.clear()
	is_bgm_muted = false
	is_sfx_muted = false
	bgm_volume_linear = 1.0
	sfx_volume_linear = 1.0
	just_beat_final_level = false
	launcher_level_progress = {
		"crystal_palace": 1,
		"ancient_ruins": 1,
		"heavy_metal": 1,
		"sub_zero": 1,
		"seabed": 1,
		"desert": 1,
		"house": 1,
		"space": 1
	}

	_recalculate_press_speed()
	apply_audio_settings()
	apply_language_settings()
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
