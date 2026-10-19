extends Node

# Altere para a URL RAW do seu arquivo JSON hospedado
const JSON_URL: String = "https://raw.githubusercontent.com/JamesElison/Escape_The_Press/refs/heads/main/version.json"

# Altere para o pacote exato do seu jogo na Play Store
const PLAY_STORE_URL: String = "https://play.google.com/store/apps/details?id=com.JEP.escape_the_press"

# Defina o Version Code atual desta compilação instalada no celular
const CURRENT_VERSION_CODE: int = 1

@onready var http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Inicia a verificação de versão em segundo plano
	_check_for_updates()

func _check_for_updates() -> void:
	var error = http_request.request(JSON_URL)
	if error != OK:
		print("[VersionChecker] Falha ao iniciar requisição HTTP: ", error)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[VersionChecker] Erro ao buscar versão na nuvem. Código HTTP: ", response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result == OK:
		var data: Dictionary = json.data
		var latest_code: int = int(data.get("latest_version_code", 0))
		var release_notes: String = data.get("release_notes", "")
		var force_update: bool = data.get("force_update", false)
		
		# Compara se a versão da nuvem é superior à do app instalado
		if latest_code > CURRENT_VERSION_CODE:
			_show_update_popup(release_notes, force_update)
		else:
			print("[VersionChecker] O jogo já está na versão mais recente.")
	else:
		print("[VersionChecker] Erro ao processar o JSON retornado.")

func _show_update_popup(notes: String, is_forced: bool) -> void:
	# Aqui você pode instanciar uma cena de UI própria com o estilo do seu jogo,
	# ou usar uma caixa de diálogo nativa rápida do Control (AcceptDialog/ConfirmationDialog):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Atualização Disponível!"
	dialog.dialog_text = notes + "\n\nDeseja abrir a Play Store para atualizar?"
	dialog.ok_button_text = "Atualizar"
	dialog.cancel_button_text = "Agora não"
	
	dialog.confirmed.connect(func():
		OS.shell_open(PLAY_STORE_URL)
	)
	
	if is_forced:
		dialog.get_cancel_button().visible = false
		# Se for forçada, reabre o popup caso o jogador tente fechar no botão 'X'
		dialog.canceled.connect(func():
			_show_update_popup(notes, is_forced)
		)

	add_child(dialog)
	dialog.popup_centered()
