extends Control

signal opened
signal difficulty_menu_closed

@onready var menu_music = $MenuBGM
@onready var menu_button_sound = $MenuButtonSound
@onready var menu_glass = $MenuGlass
@onready var vbox_container = $DifficultyMenu


@onready var mode_label = $DifficultyMenu/ModeLabel
@onready var easy_button = $DifficultyMenu/Panel1/EasyButton
@onready var medium_button = $DifficultyMenu/Panel2/MediumButton
@onready var hard_button = $DifficultyMenu/Panel3/HardButton

@export var menu_ui: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if not is_instance_valid(menu_ui):
		if get_parent() and get_parent().has_node("Menu"):
			menu_ui = get_parent().get_node("Menu")
		elif get_node_or_null("../Menu") != null:
			menu_ui = get_node("../Menu")


func toggle_shop() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	if not GameManager.is_bgm_muted and menu_music and not menu_music.playing:
		menu_music.play()
	show()
	check_button_state()
	get_tree().paused = true
	opened.emit()

func close() -> void:
	if not GameManager.is_bgm_muted and menu_music and menu_music.playing:
		menu_music.stop()
	hide()
	get_tree().paused = false
	difficulty_menu_closed.emit()
	menu_ui.open()

func check_button_state() -> void:
	if GameManager.easy_difficulty_mode:
		mode_label.text = str("Easy Mode Selected")
		easy_button.disabled = true
		medium_button.disabled = false
		hard_button.disabled = false

	elif GameManager.medium_difficulty_mode:
		mode_label.text = str("Medium Mode Selected")
		easy_button.disabled = false
		medium_button.disabled = true
		hard_button.disabled = false

	elif GameManager.hard_difficulty_mode:
		mode_label.text = str("Hard Mode Selected")
		easy_button.disabled = false
		medium_button.disabled = false
		hard_button.disabled = true

func _on_easy_button_pressed() -> void:
	if not easy_button.disabled:
		menu_button_sound.play()
		GameManager.easy_difficulty_mode = true
		GameManager.medium_difficulty_mode = false
		GameManager.hard_difficulty_mode = false
		GameManager._recalculate_press_speed()
		mode_label.text = str("Easy Mode Selected")
		close()

func _on_medium_button_pressed() -> void:
	if not medium_button.disabled:
		menu_button_sound.play()
		GameManager.easy_difficulty_mode = false
		GameManager.medium_difficulty_mode = true
		GameManager.hard_difficulty_mode = false
		GameManager._recalculate_press_speed()
		mode_label.text = str("Medium Mode Selected")
		close()

func _on_hard_button_pressed() -> void:
	if not hard_button.disabled:
		menu_button_sound.play()
		GameManager.easy_difficulty_mode = false
		GameManager.medium_difficulty_mode = false
		GameManager.hard_difficulty_mode = true
		GameManager._recalculate_press_speed()
		mode_label.text = str("Hard Mode Selected")
		close()
