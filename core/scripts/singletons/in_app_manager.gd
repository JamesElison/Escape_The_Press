extends Node

signal ad_free_purchased
signal ad_free_state_changed(is_purchased: bool)

const PURCHASES_SAVE_PATH := "user://purchases.dat"
const REMOVE_ADS_PRODUCT_ID := "remove_mandatory_ads_5usd" # ID exato criado no Play Console

var payment_plugin = null
var is_ad_free_purchased: bool = false
var _is_ready_to_purchase: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_local_purchases()
	_sync_game_manager_premium_state()

	var has_single := Engine.has_singleton("GodotGooglePlayBilling")
	print("[IAP] Tem singleton GodotGooglePlayBilling? ", has_single)

	if has_single:
		payment_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		print("[IAP] Plugin carregado: ", payment_plugin)
		_connect_billing_signals()
		_init_and_connect_billing()
	else:
		push_warning("Singleton 'GodotGooglePlayBilling' não encontrado neste ambiente.")

func _connect_billing_signals() -> void:
	if not payment_plugin:
		return

	if payment_plugin.has_signal("connected") and not payment_plugin.connected.is_connected(_on_connected):
		payment_plugin.connected.connect(_on_connected)

	if payment_plugin.has_signal("disconnected") and not payment_plugin.disconnected.is_connected(_on_disconnected):
		payment_plugin.disconnected.connect(_on_disconnected)

	if payment_plugin.has_signal("connect_error") and not payment_plugin.connect_error.is_connected(_on_connect_error):
		payment_plugin.connect_error.connect(_on_connect_error)

	if payment_plugin.has_signal("query_product_details_response") and not payment_plugin.query_product_details_response.is_connected(_on_product_details_response):
		payment_plugin.query_product_details_response.connect(_on_product_details_response)

	if payment_plugin.has_signal("on_purchase_updated") and not payment_plugin.on_purchase_updated.is_connected(_on_purchases_updated_any):
		payment_plugin.on_purchase_updated.connect(_on_purchases_updated_any)
	elif payment_plugin.has_signal("purchases_updated") and not payment_plugin.purchases_updated.is_connected(_on_purchases_updated_any):
		payment_plugin.purchases_updated.connect(_on_purchases_updated_any)

	if payment_plugin.has_signal("query_purchases_response") and not payment_plugin.query_purchases_response.is_connected(_on_query_purchases_response_any):
		payment_plugin.query_purchases_response.connect(_on_query_purchases_response_any)

func _init_and_connect_billing() -> void:
	if not payment_plugin:
		return

	print("[IAP] Chamando initPlugin() e startConnection()...")
	payment_plugin.initPlugin()
	payment_plugin.startConnection()

func _on_connect_error(response_code: int, debug_message: String) -> void:
	_is_ready_to_purchase = false
	print("[IAP] ERRO de conexão | código=", response_code, " | msg=", debug_message)

func _on_disconnected() -> void:
	_is_ready_to_purchase = false
	print("[IAP] Billing desconectado.")

func _on_connected(_arg1 = null, _arg2 = null) -> void:
	_is_ready_to_purchase = true
	print("[IAP] Conectado ao Google Play Billing! _is_ready_to_purchase=true")
	payment_plugin.queryPurchases("inapp", false)
	payment_plugin.queryProductDetails(PackedStringArray([REMOVE_ADS_PRODUCT_ID]), "inapp")

func _on_product_details_response(response: Dictionary) -> void:
	print("[IAP] query_product_details_response: ", response)

func buy_ad_free() -> void:
	print("[IAP] buy_ad_free() chamado | is_ad_free_purchased=", is_ad_free_purchased, " | ready=", _is_ready_to_purchase, " | plugin=", payment_plugin)
	if is_ad_free_purchased:
		_set_ad_free_purchased(true)
		return

	if not payment_plugin or not _is_ready_to_purchase:
		push_warning("Google Play Billing ainda não conectado ou indisponível neste ambiente.")
		return

	print("[IAP] Chamando purchase() para: ", REMOVE_ADS_PRODUCT_ID)
	var result = payment_plugin.purchase(REMOVE_ADS_PRODUCT_ID, "", "", false)
	print("[IAP] Retorno de purchase(): ", result)

func _on_query_purchases_response_any(arg1, arg2 = null) -> void:
	print("[IAP] query_purchases_response: ", arg1, " | ", arg2)
	if arg1 is Dictionary:
		if int(arg1.get("response_code", -1)) == 0:
			var purchases: Array = arg1.get("purchases", [])
			_process_purchases_list(purchases)
	elif arg2 is Array:
		if int(arg1) == 0:
			_process_purchases_list(arg2)

func _on_purchases_updated_any(arg1, arg2 = null) -> void:
	print("[IAP] on_purchase_updated: ", arg1, " | ", arg2)
	if arg1 is Dictionary:
		if int(arg1.get("response_code", -1)) == 0:
			var purchases: Array = arg1.get("purchases", [])
			_process_purchases_list(purchases)
	elif arg1 is Array:
		_process_purchases_list(arg1)
	elif arg2 is Array:
		if arg1 == null or int(arg1) == 0:
			_process_purchases_list(arg2)

func _process_purchases_list(purchases: Array) -> void:
	var found_ad_free := false
	for purchase in purchases:
		if not (purchase is Dictionary):
			continue
		var state := int(purchase.get("purchase_state", -1))
		var products: Array = purchase.get("products", [])
		if state == 1 and REMOVE_ADS_PRODUCT_ID in products:
			found_ad_free = true
			var is_ack := bool(purchase.get("is_acknowledged", false))
			var token := str(purchase.get("purchase_token", ""))
			if not is_ack and token != "" and payment_plugin:
				payment_plugin.acknowledgePurchase(token)

	if found_ad_free:
		_set_ad_free_purchased(true)

func _set_ad_free_purchased(purchased: bool) -> void:
	var changed := (is_ad_free_purchased != purchased)
	is_ad_free_purchased = purchased
	save_local_purchases()
	_sync_game_manager_premium_state()
	if changed and purchased:
		ad_free_purchased.emit()
	ad_free_state_changed.emit(is_ad_free_purchased)

func _sync_game_manager_premium_state() -> void:
	if GameManager:
		var should_be_premium := bool(GameManager.is_premium or is_ad_free_purchased)
		if is_ad_free_purchased:
			GameManager.is_premium = true
		elif GameManager.is_premium:
			is_ad_free_purchased = true
		if should_be_premium:
			GameManager.save_game_data()

func save_local_purchases() -> void:
	var file = FileAccess.open(PURCHASES_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({
			"is_ad_free_purchased": is_ad_free_purchased
		})

func load_local_purchases() -> void:
	if FileAccess.file_exists(PURCHASES_SAVE_PATH):
		var file = FileAccess.open(PURCHASES_SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				is_ad_free_purchased = bool(data.get("is_ad_free_purchased", false))
			elif data is Array:
				is_ad_free_purchased = "remove_ads" in data or "ad_free" in data

# Mantém compatibilidade com chamadas existentes no menu.gd
func reset_local_purchases() -> void:
	if FileAccess.file_exists(PURCHASES_SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("purchases.dat")
	is_ad_free_purchased = false
	if GameManager:
		GameManager.is_premium = false
		GameManager.save_game_data()
	ad_free_state_changed.emit(false)
