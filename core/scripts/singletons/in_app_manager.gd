extends Node

signal ad_free_purchased
signal ad_free_state_changed(is_purchased: bool)

const PURCHASES_SAVE_PATH := "user://purchases.dat"
const REMOVE_ADS_PRODUCT_ID := "remove_mandatory_ads_5usd" # Ajuste para o ID exato criado no Play Console

var payment_plugin = null
var is_ad_free_purchased: bool = false
var _is_ready_to_purchase: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_local_purchases()
	_sync_game_manager_premium_state()

	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		if payment_plugin.has_signal("connected") and not payment_plugin.connected.is_connected(_on_connected):
			payment_plugin.connected.connect(_on_connected)
		if payment_plugin.has_signal("purchases_updated") and not payment_plugin.purchases_updated.is_connected(_on_purchases_updated):
			payment_plugin.purchases_updated.connect(_on_purchases_updated)
		if payment_plugin.has_signal("query_purchases_response") and not payment_plugin.query_purchases_response.is_connected(_on_query_purchases_response):
			payment_plugin.query_purchases_response.connect(_on_query_purchases_response)
		#payment_plugin.start_connection()
		_start_billing_connection()

func _start_billing_connection() -> void:
	if not payment_plugin:
		return
	if payment_plugin.has_method("start_connection"):
		payment_plugin.start_connection()
	elif payment_plugin.has_method("startConnection"):
		payment_plugin.startConnection()
	else:
		push_warning("Método de conexão não encontrado no GodotGooglePlayBilling.")

func _on_connected() -> void:
	_is_ready_to_purchase = true
	if payment_plugin and payment_plugin.has_method("queryPurchases"):
		payment_plugin.queryPurchases("inapp")

func buy_ad_free() -> void:
	if is_ad_free_purchased:
		_set_ad_free_purchased(true)
		return

	if payment_plugin and _is_ready_to_purchase and payment_plugin.has_method("purchase"):
		payment_plugin.purchase(REMOVE_ADS_PRODUCT_ID)
	else:
		push_warning("Google Play Billing ainda não conectado ou indisponível neste ambiente.")

func _on_query_purchases_response(query_result: Dictionary) -> void:
	if query_result.get("response_code", -1) == 0:
		var purchases: Array = query_result.get("purchases", [])
		_process_purchases_list(purchases)

func _on_purchases_updated(purchases: Array) -> void:
	_process_purchases_list(purchases)

func _process_purchases_list(purchases: Array) -> void:
	var found_ad_free := false
	for purchase in purchases:
		var state := int(purchase.get("purchase_state", -1))
		var products: Array = purchase.get("products", [])
		if state == 1 and REMOVE_ADS_PRODUCT_ID in products:
			found_ad_free = true
			var is_ack := bool(purchase.get("is_acknowledged", false))
			var token := str(purchase.get("purchase_token", ""))
			if not is_ack and token != "" and payment_plugin and payment_plugin.has_method("acknowledgePurchase"):
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
				# Compatibilidade com formato antigo caso exista save anterior
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
