extends TextureButton

signal themeshop_closed
signal biome_shop_closed
signal difficulty_menu_closed
signal language_menu_closed

@export var menu_ui: Control  # Aponta para a tela de Menu
@export var theme_shop_ui: Control # Aponta para a loja de temas (ThemeShop)
@export var biome_shop_ui: Control
@export var difficulty_menu_ui: Control # Aponta para o menu de dificuldade
@export var language_menu_ui: Control
@export var play_game_button: Control
@export var pause_button: Control
@export var turn_left_button: Control
@export var turn_right_button: Control
@export var level_label: Control

const ALPHA_MUTED: float = 1.0 #130.0 / 255.0
const ALPHA_FULL: float = 1.0

var menu_avaliable = false
var themeshop_avaliable = false
var biome_shop_avaliable = false
var difficulty_menu_avaliable = false
var language_menu_avaliable = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	set_alpha()

	if not is_instance_valid(menu_ui):
		if get_parent() and get_parent().has_node("Menu"):
			menu_ui = get_parent().get_node("Menu")
		elif get_node_or_null("../Menu") != null:
			menu_ui = get_node("../Menu")

	if not is_instance_valid(theme_shop_ui):
		if get_parent() and get_parent().has_node("ThemeShop"):
			theme_shop_ui = get_parent().get_node("ThemeShop")
		elif get_node_or_null("../ThemeShop") != null:
			theme_shop_ui = get_node("../ThemeShop")

	if not is_instance_valid(biome_shop_ui):
		if get_parent() and get_parent().has_node("BiomeShop"):
			biome_shop_ui = get_parent().get_node("BiomeShop")
		elif get_node_or_null("../BiomeShop") != null:
			biome_shop_ui = get_node("../BiomeShop")

	if not is_instance_valid(difficulty_menu_ui):
		if get_parent() and get_parent().has_node("DifficultyMenu"):
			difficulty_menu_ui = get_parent().get_node("DifficultyMenu")
		elif get_node_or_null("../DifficultyMenu") != null:
			difficulty_menu_ui = get_node("../DifficultyMenu")

	if not is_instance_valid(language_menu_ui):
		if get_parent() and get_parent().has_node("LanguageMenu"):
			language_menu_ui = get_parent().get_node("LanguageMenu")
		elif get_node_or_null("../LanguageMenu") != null:
			language_menu_ui = get_node("../LanguageMenu")

	if is_instance_valid(menu_ui):
		if not menu_ui.opened.is_connected(_on_menu_opened):
			menu_ui.opened.connect(_on_menu_opened)
		if not menu_ui.closed.is_connected(_on_menu_closed):
			menu_ui.closed.connect(_on_menu_closed)
		if not menu_ui.themeshop_opened.is_connected(_on_themeshop_opened):
			menu_ui.themeshop_opened.connect(_on_themeshop_opened)
		if menu_ui.has_signal("biome_shop_opened") and not menu_ui.biome_shop_opened.is_connected(_on_biome_shop_opened):
			menu_ui.biome_shop_opened.connect(_on_biome_shop_opened)
		if not menu_ui.difficulty_menu_opened.is_connected(_on_difficulty_menu_opened):
			menu_ui.difficulty_menu_opened.connect(_on_difficulty_menu_opened)
		if menu_ui.has_signal("language_menu_opened") and not menu_ui.language_menu_opened.is_connected(_on_language_menu_opened):
			menu_ui.language_menu_opened.connect(_on_language_menu_opened)

	if is_instance_valid(biome_shop_ui):
		if biome_shop_ui.has_signal("closed") and not biome_shop_ui.closed.is_connected(_on_biome_shop_closed):
			biome_shop_ui.closed.connect(_on_biome_shop_closed)

	if is_instance_valid(difficulty_menu_ui):
		if difficulty_menu_ui.has_signal("difficulty_menu_closed") and not difficulty_menu_ui.difficulty_menu_closed.is_connected(_on_difficulty_menu_closed):
			difficulty_menu_ui.difficulty_menu_closed.connect(_on_difficulty_menu_closed)

	if is_instance_valid(language_menu_ui):
		if language_menu_ui.has_signal("language_menu_closed") and not language_menu_ui.language_menu_closed.is_connected(_on_language_menu_closed):
			language_menu_ui.language_menu_closed.connect(_on_language_menu_closed)


func set_alpha():
	var parent_name = get_parent()
	if parent_name and parent_name.name == "MapHUD":
		self_modulate.a = ALPHA_FULL
	else:
		self_modulate.a = ALPHA_MUTED

func _on_pressed() -> void:
	if not is_instance_valid(menu_ui) or not menu_ui.has_method("open") or not menu_ui.has_method("close"):
		return

	var any_submenu_open := themeshop_avaliable or biome_shop_avaliable or difficulty_menu_avaliable or language_menu_avaliable

	if not menu_avaliable and not any_submenu_open:
		menu_ui.open()
		print("Open Menu")

	elif menu_avaliable and not any_submenu_open:
		menu_ui.close()
		print("Close Menu")

	elif themeshop_avaliable:
		if is_instance_valid(theme_shop_ui) and theme_shop_ui.has_method("close"):
			theme_shop_ui.close()
		themeshop_closed.emit()
		themeshop_avaliable = false
		menu_ui.open()
		print("Open Menu from theme shop")

	elif biome_shop_avaliable:
		if is_instance_valid(biome_shop_ui):
			if biome_shop_ui.has_method("close"):
				biome_shop_ui.close()
			else:
				biome_shop_ui.hide()
		biome_shop_closed.emit()
		biome_shop_avaliable = false
		menu_ui.open()
		print("Open Menu from biome shop")

	elif difficulty_menu_avaliable:
		if is_instance_valid(difficulty_menu_ui) and difficulty_menu_ui.has_method("close"):
			difficulty_menu_ui.close()
		difficulty_menu_closed.emit()
		difficulty_menu_avaliable = false
		menu_ui.open()
		print("Open Menu from difficulty menu")

	elif language_menu_avaliable:
		if is_instance_valid(language_menu_ui) and language_menu_ui.has_method("close"):
			language_menu_ui.close()
		language_menu_closed.emit()
		language_menu_avaliable = false
		menu_ui.open()
		print("Open Menu from language menu")


func _on_menu_opened() -> void:
	menu_avaliable = true
	self_modulate.a = ALPHA_FULL
	if play_game_button:
		play_game_button.visible = false
	if pause_button:
		pause_button.visible = false
	if turn_left_button:
		turn_left_button.visible = false
	if turn_right_button:
		turn_right_button.visible = false
	if level_label:
		level_label.visible = false

func _on_menu_closed() -> void:
	menu_avaliable = false
	set_alpha()
	if play_game_button:
		play_game_button.visible = true
	if pause_button:
		pause_button.visible = true
		if pause_button.has_method("sync_state"):
			pause_button.sync_state()
	if turn_left_button:
		turn_left_button.visible = true
	if turn_right_button:
		turn_right_button.visible = true
	if level_label:
		level_label.visible = true

func _on_themeshop_opened() -> void:
	themeshop_avaliable = true

func _on_biome_shop_opened() -> void:
	biome_shop_avaliable = true

func _on_biome_shop_closed() -> void:
	biome_shop_avaliable = false

func _on_difficulty_menu_opened() -> void:
	difficulty_menu_avaliable = true

func _on_difficulty_menu_closed() -> void:
	difficulty_menu_avaliable = false

func _on_language_menu_opened() -> void:
	language_menu_avaliable = true

func _on_language_menu_closed() -> void:
	language_menu_avaliable = false
