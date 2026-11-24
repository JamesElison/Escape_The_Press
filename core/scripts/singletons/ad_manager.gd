extends Node

signal rewarded_earned(purpose: String)
signal rewarded_dismissed(purpose: String)

var _rewarded_purpose: String = "coins"
var _earned_in_current_rewarded: bool = false

var interstitial_ad: InterstitialAd
var rewarded_ad: RewardedAd

var interstitial_load_callback := InterstitialAdLoadCallback.new()
var rewarded_load_callback := RewardedAdLoadCallback.new()
var rewarded_listener := OnUserEarnedRewardListener.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Inicializa a SDK do AdMob
	MobileAds.initialize()
	
	_setup_callbacks()
	
	await get_tree().process_frame
	_load_interstitial()
	_load_rewarded()

func _setup_callbacks() -> void:
	# Callbacks do Interstitial
	interstitial_load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
		print("Interstitial carregado com sucesso!")
		
		interstitial_ad.full_screen_content_callback = FullScreenContentCallback.new()
		interstitial_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			interstitial_ad = null
			_load_interstitial()

	interstitial_load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("Falha ao carregar Interstitial: ", error.message)

	# Callbacks do Rewarded
	rewarded_load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		rewarded_ad = ad
		print("Rewarded Ad carregado com sucesso!")
		
		rewarded_ad.full_screen_content_callback = FullScreenContentCallback.new()
		rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			var finished_purpose := _rewarded_purpose
			var earned := _earned_in_current_rewarded
			rewarded_ad = null
			_earned_in_current_rewarded = false
			_rewarded_purpose = "coins"
			_load_rewarded()
			rewarded_dismissed.emit(finished_purpose)
			if finished_purpose == "launcher_choice":
				rewarded_earned.emit(finished_purpose)
			elif earned and finished_purpose != "coins":
				rewarded_earned.emit(finished_purpose)

	rewarded_load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("Falha ao carregar Rewarded: ", error.message)

	# Listener de Recompensa do Rewarded (sem tipagem estrita para evitar erro de escopo)
	rewarded_listener.on_user_earned_reward = func(reward) -> void:
		print("Recompensa garantida pelo AdMob!")
		_earned_in_current_rewarded = true
		if _rewarded_purpose == "coins":
			GameManager.grant_ad_reward()

# --- INTERSTITIAL (Derrotas e Vitórias) ---
func _load_interstitial() -> void:
	var unit_id := "ca-app-pub-3940256099942544/1033173712" # ID de Teste do Google
	if OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/4411468910"
		
	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), interstitial_load_callback)

func show_interstitial() -> void:
	if GameManager.is_premium:
		return
		
	if interstitial_ad:
		interstitial_ad.show()
	else:
		print("Interstitial AdMob ainda não carregou.")
		_load_interstitial()


# --- REWARDED (Recompensa de 2.000 coins a cada 15 casas) ---
func _load_rewarded() -> void:
	var unit_id := "ca-app-pub-3940256099942544/5224354917" # ID de Teste do Google
	if OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/1712485313"
		
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), rewarded_load_callback)

func show_rewarded(purpose: String = "coins") -> void:
	_rewarded_purpose = purpose
	_earned_in_current_rewarded = false
	if rewarded_ad:
		rewarded_ad.show(rewarded_listener)
	else:
		print("Rewarded Ad ainda não carregou.")
		var fallback_purpose := _rewarded_purpose
		_rewarded_purpose = "coins"
		_load_rewarded()
		if fallback_purpose == "launcher_choice":
			rewarded_earned.emit(fallback_purpose)
