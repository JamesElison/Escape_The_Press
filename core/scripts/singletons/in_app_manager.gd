extends Node

signal item_purchased(product_id)

var payment_plugin = null
var purchased_launchers: Array[String] = ["player1"] # Player 1 é o padrão (grátis)

var products = {
	"player2": "launcher_player2_2brl",
	"player3": "launcher_player3_5brl",
	"player4": "launcher_player4_8brl",
	"player5": "launcher_player5_11brl"
}

func _ready() -> void:
	load_local_purchases()
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		payment_plugin.connected.connect(_on_connected)
		payment_plugin.purchases_updated.connect(_on_purchases_updated)
		payment_plugin.start_connection()

func _on_connected() -> void:
	payment_plugin.queryPurchases("inapp") # Restaura compras já feitas no Google

func buy_launcher(launcher_key: String) -> void:
	if payment_plugin and launcher_key in products:
		payment_plugin.purchase(products[launcher_key])

func _on_purchases_updated(purchases: Array) -> void:
	for purchase in purchases:
		if purchase.purchase_state == 1:
			for key in products:
				if products[key] in purchase.products:
					unlock_launcher(key)
					if not purchase.is_acknowledged:
						payment_plugin.acknowledgePurchase(purchase.purchase_token)

func unlock_launcher(launcher_key: String) -> void:
	if not launcher_key in purchased_launchers:
		purchased_launchers.append(launcher_key)
		save_local_purchases()
		item_purchased.emit(launcher_key)

func save_local_purchases() -> void:
	var file = FileAccess.open("user://purchases.dat", FileAccess.WRITE)
	if file:
		file.store_var(purchased_launchers)

func load_local_purchases() -> void:
	if FileAccess.file_exists("user://purchases.dat"):
		var file = FileAccess.open("user://purchases.dat", FileAccess.READ)
		if file:
			purchased_launchers = file.get_var()

# --- RESET LOCAL DE COMPRAS IN-APP ---
func reset_local_purchases() -> void:
	if FileAccess.file_exists("user://purchases.dat"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("purchases.dat")
	
	purchased_launchers = ["player1"]
