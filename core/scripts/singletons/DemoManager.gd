extends Node

var recorded_frames: Array = []
var initial_blocks_colors: Dictionary = {}
var initial_charger_queue: Array = []
var current_frame_index: int = 0
var fixed_seed: int = 12345

# Chama no _enter_tree() do Level (antes de qualquer nó filho nascer)
func prepare_early_seed() -> void:
	if GameManager.is_recording_demo:
		recorded_frames.clear()
		initial_blocks_colors.clear()
		initial_charger_queue.clear()
		fixed_seed = randi()
		seed(fixed_seed)
		print("GRAVAÇÃO DE DEMO INICIADA! Seed: ", fixed_seed)
		
	elif GameManager.is_attract_mode:
		current_frame_index = 0
		_load_next_demo_file() # Carrega o JSON da próxima demo e define bioma/nível/lançador
		seed(fixed_seed)       # Aplica a seed exata da gravação

# Chama no _ready() do Level
func capture_or_restore_board_state(tree: SceneTree) -> void:
	var all_blocks = tree.get_nodes_in_group("blocks")
	var charger_node = tree.current_scene.find_child("Charger", true, false)

	if GameManager.is_recording_demo:
		initial_blocks_colors.clear()
		for block in all_blocks:
			if is_instance_valid(block) and "block_color" in block:
				initial_blocks_colors[str(block.get_path())] = block.block_color
				
		if charger_node and "ball_queue" in charger_node:
			initial_charger_queue = charger_node.ball_queue.duplicate()
			
	elif GameManager.is_attract_mode:
		for block in all_blocks:
			if is_instance_valid(block) and "block_color" in block:
				var path_key = str(block.get_path())
				if initial_blocks_colors.has(path_key):
					block.block_color = int(initial_blocks_colors[path_key])
					if block.has_method("update_color_visuals"):
						block.update_color_visuals()
						
		if charger_node and "ball_queue" in charger_node and not initial_charger_queue.is_empty():
			charger_node.ball_queue.clear()
			for c in initial_charger_queue:
				charger_node.ball_queue.append(int(c))
			if charger_node.has_method("update_visuals"):
				charger_node.update_visuals()
			if charger_node.has_method("get_top_ball_color"):
				charger_node.emit_signal("top_color_changed", charger_node.get_top_ball_color())

func record_frame(player_x: float, player_rot: float, did_shoot: bool) -> void:
	if not GameManager.is_recording_demo:
		return
	recorded_frames.append({
		"x": snapped(player_x, 0.1),
		"r": snapped(player_rot, 0.01),
		"s": did_shoot
	})

func get_next_playback_frame() -> Dictionary:
	if current_frame_index < recorded_frames.size():
		var data = recorded_frames[current_frame_index]
		current_frame_index += 1
		return data
	return {}

func save_recording_to_disk() -> void:
	if not GameManager.is_recording_demo or recorded_frames.is_empty():
		return
		
	var active_launcher = GameManager.equipped_launcher
	if GameManager.temporary_launcher != "":
		active_launcher = GameManager.temporary_launcher
		
	var save_data = {
		"seed": fixed_seed,
		"biome": GameManager.current_biome,
		"level": GameManager.current_level,
		"launcher": active_launcher,
		"blocks": initial_blocks_colors,
		"charger": initial_charger_queue,
		"frames": recorded_frames
	}
	
	var slot_num = (GameManager.current_demo_index % GameManager.DEMO_FILES.size()) + 1
	var out_path = "user://demo_replay_" + str(slot_num) + ".json"
	
	var file = FileAccess.open(out_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("DEMO SALVA COM SUCESSO em: ", ProjectSettings.globalize_path(out_path))

func _load_next_demo_file() -> void:
	recorded_frames.clear()
	initial_blocks_colors.clear()
	initial_charger_queue.clear()
	
	# Lista com os caminhos diretos
	var demo_paths = [
		"res://core/resources/demo_replay_1.json",
		"res://core/resources/demo_replay_2.json",
		"res://core/resources/demo_replay_3.json"
	]
	
	var valid_demos: Array[String] = []
	
	# Testa cada caminho abrindo diretamente (mais seguro no Android)
	for path in demo_paths:
		var f = FileAccess.open(path, FileAccess.READ)
		if f != null:
			valid_demos.append(path)
			f.close()
			
	# Também checa se há arquivos salvos na pasta user:// do celular
	for i in range(1, 4):
		var user_path = "user://demo_replay_" + str(i) + ".json"
		if FileAccess.file_exists(user_path) and not user_path in valid_demos:
			valid_demos.append(user_path)

	print("Demos válidas encontradas: ", valid_demos)
	
	if valid_demos.is_empty():
		print("AVISO: Nenhuma demo encontrada!")
		return
		
	# Alterna o índice de forma segura entre as demos encontradas
	var idx = GameManager.current_demo_index % valid_demos.size()
	var selected_path = valid_demos[idx]
	GameManager.current_demo_index = (GameManager.current_demo_index + 1) % valid_demos.size()
	
	var file = FileAccess.open(selected_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			fixed_seed = int(data.get("seed", 12345))
			GameManager.current_biome = data.get("biome", "crystal_palace")
			GameManager.current_level = int(data.get("level", 1))
			GameManager.temporary_launcher = ""
			GameManager.equipped_launcher = data.get("launcher", "marble")
			GameManager._recalculate_press_speed()
			initial_blocks_colors = data.get("blocks", {})
			initial_charger_queue = data.get("charger", [])
			recorded_frames = data.get("frames", [])
			print("--> Rodando demo [", selected_path, "] | Bioma: ", GameManager.current_biome, " | Nível: ", GameManager.current_level, " | Lançador: ", GameManager.equipped_launcher)
