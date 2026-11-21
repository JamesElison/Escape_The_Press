extends Control

signal opened
signal language_menu_closed

@onready var menu_music = $MenuBGM
@onready var menu_button_sound = $MenuButtonSound
@onready var menu_glass = $MenuGlass
@onready var vbox_container = $LanguageMenu


@onready var mode_label = $LanguageMenu/ModeLabel
@onready var english_button = $LanguageMenu/Panel1/EnglishButton
@onready var portuguese_button = $LanguageMenu/Panel2/PortugueseButton
@onready var mandarin_button = $LanguageMenu/Panel3/MandarinButton
@onready var spanish_button = $LanguageMenu/Panel4/SpanishButton

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
	language_menu_closed.emit()
	menu_ui.open()

func check_button_state() -> void:
	if GameManager.english:
		mode_label.text = str("English Selected")
		english_button.disabled = true
		portuguese_button.disabled = false
		mandarin_button.disabled = false
		spanish_button.disabled = false

	elif GameManager.portuguese:
		mode_label.text = str("Português Selecionado")
		english_button.disabled = false
		portuguese_button.disabled = true
		mandarin_button.disabled = false
		spanish_button.disabled = false

	elif GameManager.mandarin:
		mode_label.text = str("已选择中文")
		english_button.disabled = false
		portuguese_button.disabled = false
		mandarin_button.disabled = true
		spanish_button.disabled = false

	elif GameManager.spanish:
		mode_label.text = str("Español seleccionado")
		english_button.disabled = false
		portuguese_button.disabled = false
		mandarin_button.disabled = false
		spanish_button.disabled = true

func _on_english_button_pressed() -> void:
	if not english_button.disabled:
		menu_button_sound.play()
		GameManager.english = true
		GameManager.portuguese = false
		GameManager.mandarin = false
		GameManager.spanish = false
		mode_label.text = str("English Selected")
		close()

func _on_portuguese_button_pressed() -> void:
	if not portuguese_button.disabled:
		menu_button_sound.play()
		GameManager.english = false
		GameManager.portuguese = true
		GameManager.mandarin = false
		GameManager.spanish = false
		mode_label.text = str("Português Selecionado")
		close()

func _on_mandarin_button_pressed() -> void:
	if not mandarin_button.disabled:
		menu_button_sound.play()
		GameManager.english = false
		GameManager.portuguese = false
		GameManager.mandarin = true
		GameManager.spanish = false
		mode_label.text = str("已选择中文")
		close()

func _on_spanish_button_pressed() -> void:
	if not spanish_button.disabled:
		menu_button_sound.play()
		GameManager.english = false
		GameManager.portuguese = false
		GameManager.mandarin = false
		GameManager.spanish = true
		mode_label.text = str("Español seleccionado")
		close()
