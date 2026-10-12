extends TextureButton

signal themeshop_closed

@export var menu_ui: Control  # Aponta para a tela de Menu
@export var theme_shop_ui: Control # Aponta para a loja de temas (ThemeShop)
@export var play_game_button: Control
@export var pause_button: Control
@export var turn_left_button: Control
@export var turn_right_button: Control
@export var level_label: Control

const ALPHA_MUTED: float = 130.0 / 255.0
const ALPHA_FULL: float = 1.0

var menu_avaliable = false
var themeshop_avaliable = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	set_alpha()

	if not is_instance_valid(menu_ui):
		if get_parent() and get_parent().has_node("Menu"):
			menu_ui = get_parent().get_node("Menu")
		elif get_node_or_null("../Menu") != null:
			menu_ui = get_node("../Menu")

	if menu_ui:
		if not menu_ui.opened.is_connected(_on_shop_opened):
			menu_ui.opened.connect(_on_shop_opened)
		if not menu_ui.closed.is_connected(_on_shop_closed):
			menu_ui.closed.connect(_on_shop_closed)
		if not menu_ui.themeshop_opened.is_connected(_on_themeshop_opened):
				menu_ui.themeshop_opened.connect(_on_themeshop_opened)

	if not is_instance_valid(theme_shop_ui):
		if get_parent() and get_parent().has_node("ThemeShop"):
			theme_shop_ui = get_parent().get_node("ThemeShop")
		elif get_node_or_null("../ThemeShop") != null:
			theme_shop_ui = get_node("../ThemeShop")



func set_alpha():
	var parent_name = get_parent()
	if parent_name and parent_name.name == "MapHUD":
		self_modulate.a = ALPHA_FULL
	else:
		self_modulate.a = ALPHA_MUTED

func _on_pressed() -> void:
	if is_instance_valid(menu_ui) and is_instance_valid(theme_shop_ui):
		if menu_ui.has_method("open") and menu_ui.has_method("close") and theme_shop_ui.has_method("close"):
			if not menu_avaliable and not themeshop_avaliable:
				menu_ui.open()
				print("Open Menu")
			
			elif menu_avaliable and not themeshop_avaliable:
				menu_ui.close()
				print("Close Menu")
			
			elif themeshop_avaliable:
				theme_shop_ui.close()
				themeshop_closed.emit()
				themeshop_avaliable = false
				menu_ui.open()
				print("Open Menu from theme shop")

func _on_shop_opened() -> void:
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

func _on_shop_closed() -> void:
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
