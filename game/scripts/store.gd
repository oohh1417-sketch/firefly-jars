extends Node
## The $2.99 "Remove ads" purchase.
##
## Android: Google Play Billing, through the official Godot plugin (singleton "GodotGooglePlayBilling").
## iPhone:  Apple StoreKit, through the official Godot iOS plugin (singleton "InAppStore").
## Both plugins are added in the final store build step. Without them (computer, editor, test builds)
## a pretend store asks "Buy for $2.99?" and no money is charged.
##
## Buying it turns off the between-level ads only. Videos that players choose to watch for a reward
## stay, and coins are not affected. "Restore purchases" brings it back on a new phone.

signal purchase_done(ok: bool, message: String)
signal restore_done(found: bool)
signal test_store_requested    # main.gd shows the pretend store card

const PRODUCT_ID := "remove_ads"   # the same ID must be created in Play Console and App Store Connect
const PRICE_TEXT := "$2.99"        # the store shows the real local price once the plugin is in

var backend := "test"             # "play", "apple" or "test"
var price_text := PRICE_TEXT
var _play = null
var _apple = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
		_play = Engine.get_singleton("GodotGooglePlayBilling")
		backend = "play"
		_connect_play()
	elif OS.get_name() == "iOS" and Engine.has_singleton("InAppStore"):
		_apple = Engine.get_singleton("InAppStore")
		backend = "apple"
		_apple.set_auto_finish_transaction(true)
		_apple.request_product_info({"product_ids": [PRODUCT_ID]})

func buy_remove_ads() -> void:
	if Save.ads_removed:
		purchase_done.emit(true, "Ads are already removed")
		return
	match backend:
		"play":
			_play.purchase(PRODUCT_ID)
		"apple":
			_apple.purchase({"product_id": PRODUCT_ID})
		_:
			test_store_requested.emit()

## Called by the pretend store card when the player taps Buy.
func confirm_test_purchase() -> void:
	_grant()

func restore() -> void:
	match backend:
		"play":
			_play.queryPurchases("inapp")
		"apple":
			_apple.restore_purchases()
		_:
			restore_done.emit(Save.ads_removed)

func _grant() -> void:
	var first := not Save.ads_removed
	Ads.set_ads_removed(true)
	if first:
		Analytics.log_event("purchase", {"item_id": PRODUCT_ID, "value": 2.99, "currency": "USD"})
	purchase_done.emit(true, "Ads between levels are gone")

# ---------------- Google Play Billing ----------------

func _connect_play() -> void:
	for sig in [["connected", _on_play_connected], ["purchases_updated", _on_play_purchases],
			["query_purchases_response", _on_play_query], ["purchase_error", _on_play_error],
			["sku_details_query_completed", _on_play_details], ["product_details_query_completed", _on_play_details]]:
		if _play.has_signal(sig[0]):
			_play.connect(sig[0], sig[1])
	_play.startConnection()

func _on_play_connected() -> void:
	_play.queryPurchases("inapp")   # catches a purchase made on another phone or before a crash
	for m in ["queryProductDetails", "querySkuDetails"]:
		if _play.has_method(m):
			_play.call(m, [PRODUCT_ID], "inapp")
			break

func _on_play_details(details: Array) -> void:
	for d in details:
		if str(d.get("product_id", d.get("sku", ""))) == PRODUCT_ID:
			price_text = str(d.get("price", d.get("one_time_purchase_offer_details", {}).get("formatted_price", PRICE_TEXT)))

func _on_play_purchases(purchases: Array) -> void:
	_handle_play(purchases, false)

func _on_play_query(result: Dictionary) -> void:
	var list: Array = result.get("purchases", [])
	var found := _handle_play(list, true)
	restore_done.emit(found or Save.ads_removed)

func _handle_play(purchases: Array, quiet: bool) -> bool:
	var found := false
	for p in purchases:
		var ids: Array = p.get("products", p.get("skus", [p.get("sku", "")]))
		if not ids.has(PRODUCT_ID) or int(p.get("purchase_state", 1)) != 1:   # 1 = purchased
			continue
		found = true
		if not bool(p.get("is_acknowledged", false)):
			_play.acknowledgePurchase(p.get("purchase_token", ""))
		if quiet:
			Ads.set_ads_removed(true)
		else:
			_grant()
	return found

func _on_play_error(_code, message) -> void:
	purchase_done.emit(false, "The purchase didn't go through: %s" % message)

# ---------------- Apple StoreKit ----------------

func _process(_delta: float) -> void:
	if _apple == null:
		return
	while _apple.get_pending_event_count() > 0:
		var e: Dictionary = _apple.pop_pending_event()
		match e.get("type", ""):
			"product_info":
				var prices: Array = e.get("localized_prices", e.get("prices", []))
				if not prices.is_empty():
					price_text = str(prices[0])
			"purchase":
				if e.get("result", "") == "ok" and e.get("product_id", "") == PRODUCT_ID:
					_grant()
				else:
					purchase_done.emit(false, "The purchase didn't go through")
			"restore":
				if e.get("result", "") == "ok" and e.get("product_id", "") == PRODUCT_ID:
					Ads.set_ads_removed(true)
					restore_done.emit(true)
			"completion":
				restore_done.emit(Save.ads_removed)
