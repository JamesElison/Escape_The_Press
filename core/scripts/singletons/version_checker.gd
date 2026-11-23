extends ConfirmationDialog

# URL RAW do arquivo JSON hospedado
const JSON_URL: String = "https://raw.githubusercontent.com/JamesElison/Escape_The_Press/refs/heads/main/version.json"

# Pacote exato do jogo na Play Store
const PLAY_STORE_URL: String = "https://play.google.com/store/apps/details?id=com.JEP.escape_the_press"

# Controle interno numérico (comparação real de atualização)
const CURRENT_VERSION_CODE: int = 14

# Nome público da versão atual instalada no jogo
const CURRENT_VERSION_NAME: String = "0.10.6"

@onready var http_request: HTTPRequest = HTTPRequest.new()
var _current_notes: String = ""
var _current_is_forced: bool = false

func _ready() -> void:
	hide()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	# --- TEST RÁPIDO ---
	#_show_update_popup("test", false, "0.11.0")

	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)

	# Inicia a verificação de versão em segundo plano
	_check_for_updates()

func _check_for_updates() -> void:
	var error := http_request.request(JSON_URL)
	if error != OK:
		print("[VersionChecker] Failed to initiate HTTP request: ", error)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[VersionChecker] Error retrieving version from the cloud. HTTP code: ", response_code)
		return

	var json := JSON.new()
	var parse_result := json.parse(body.get_string_from_utf8())

	if parse_result == OK:
		var data: Dictionary = json.data
		var latest_code: int = int(data.get("latest_version_code", 0))
		var latest_version_name: String = str(data.get("latest_version_name", ""))
		var release_notes: String = str(data.get("release_notes", ""))
		var force_update: bool = bool(data.get("force_update", false))

		if latest_code > CURRENT_VERSION_CODE:
			_show_update_popup(release_notes, force_update, latest_version_name)
		else:
			print("[VersionChecker] Current version ", CURRENT_VERSION_NAME, " (code ", CURRENT_VERSION_CODE, ") is up to date.")
	else:
		print("[VersionChecker] Error processing the returned JSON.")

func _show_update_popup(notes: String, is_forced: bool, new_version_name: String = "") -> void:
	_current_notes = notes
	_current_is_forced = is_forced

	var parts: PackedStringArray = []

	if new_version_name != "":
		parts.append(CURRENT_VERSION_NAME + " -> " + new_version_name)

	if not notes.strip_edges().is_empty():
		parts.append(notes.strip_edges())

	parts.append(tr("VS_DO_YOU_WANT"))

	# Usa "\n\n" para deixar uma linha em branco entre os blocos (ou troque para "\n" se quiser mais junto)
	dialog_text = "\n\n".join(parts)

	#var cancel_btn := get_cancel_button()
	#if cancel_btn:
		#cancel_btn.visible = not is_forced

	popup_centered()

func _on_confirmed() -> void:
	print("[VersionChecker] Confirmed!")
	OS.shell_open(PLAY_STORE_URL)
	if _current_is_forced:
		popup_centered.call_deferred()

func _on_canceled() -> void:
	print("[VersionChecker] Canceled!")
	if _current_is_forced:
		popup_centered.call_deferred()
