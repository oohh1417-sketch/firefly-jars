extends Node
## The $2.99 "Remove ads" purchase, and three packs of coins (used up when bought, so they can be bought again).
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
signal test_store_requested(product: String)    # main.gd shows the pretend store card
signal coins_bought(n: int)

const PRODUCT_ID := "remove_ads"   # the same ID must be created in Play Console and App Store Connect
const PRICE_TEXT := "$2.99"        # the store shows the real local price once the plugin is in
## Coin packs: [product ID, coins, US price]. The IDs must be created in App Store Connect as "Consumable".
## GUESS: sizes, with a bigger bonus on the bigger packs. Skins cost 200 to 800 coins.
const COIN_PACKS := [["coins_500", 500, "$0.99"], ["coins_1800", 1800, "$2.99"], ["coins_3500", 3500, "$4.99"]]
var pack_prices := {}              # product ID -> local price text from the store
var _test_product := ""

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
		_apple_request_info()

func _apple_request_info() -> void:
	var ids := [PRODUCT_ID]
	for pk in COIN_PACKS:
		ids.append(pk[0])
	_apple.request_product_info({"product_ids": ids})

## Buying an item App Store Connect doesn't know yet (not created, or the Paid Apps agreement
## isn't active) makes the plugin return an error with no event, so the button looked dead.
## Say so instead, and ask Apple again for the products.
func _apple_buy(id: String) -> void:
	if _apple.purchase({"product_id": id}) != OK:
		_apple_request_info()
		purchase_done.emit(false, "The purchase didn't go through")

func buy_remove_ads() -> void:
	if Save.ads_removed:
		purchase_done.emit(true, "Ads are already removed")
		return
	match backend:
		"play":
			_play.purchase(PRODUCT_ID)
		"apple":
			_apple_buy(PRODUCT_ID)
		_:
			_test_product = PRODUCT_ID
			test_store_requested.emit(PRODUCT_ID)

func pack_price(id: String) -> String:
	for pk in COIN_PACKS:
		if pk[0] == id:
			return str(pack_prices.get(id, pk[2]))
	return ""

func buy_coins(id: String) -> void:
	match backend:
		"play":
			_play.purchase(id)
		"apple":
			_apple_buy(id)
		_:
			_test_product = id
			test_store_requested.emit(id)

## Called by the pretend store card when the player taps Buy.
func confirm_test_purchase() -> void:
	if _test_product == PRODUCT_ID:
		_grant()
	else:
		_grant_coins(_test_product)

func _grant_coins(id: String) -> bool:
	for pk in COIN_PACKS:
		if pk[0] == id:
			Analytics.log_event("purchase", {"item_id": id, "value": float(str(pk[2]).substr(1)), "currency": "USD"})
			coins_bought.emit(int(pk[1]))
			return true
	return false

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
			_play.call(m, [PRODUCT_ID] + COIN_PACKS.map(func(pk): return pk[0]), "inapp")
			break

func _on_play_details(details: Array) -> void:
	for d in details:
		var did := str(d.get("product_id", d.get("sku", "")))
		if did != PRODUCT_ID:
			pack_prices[did] = str(d.get("price", d.get("one_time_purchase_offer_details", {}).get("formatted_price", "")))
		if did == PRODUCT_ID:
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
		if int(p.get("purchase_state", 1)) == 1 and not ids.is_empty() and _grant_coins(str(ids[0])):
			_play.consumePurchase(p.get("purchase_token", ""))   # used up, so the pack can be bought again
			continue
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
	purchase_done.emit(false, I18n.t("The purchase didn't go through: {0}", [message]))

# ---------------- Apple StoreKit ----------------

func _process(_delta: float) -> void:
	if _apple == null:
		return
	while _apple.get_pending_event_count() > 0:
		var e: Dictionary = _apple.pop_pending_event()
		match e.get("type", ""):
			"product_info":
				var prices: Array = e.get("localized_prices", e.get("prices", []))
				var pids: Array = e.get("ids", [])
				for k in prices.size():
					var pid: String = str(pids[k]) if k < pids.size() else PRODUCT_ID
					if pid == PRODUCT_ID:
						price_text = str(prices[k])
					else:
						pack_prices[pid] = str(prices[k])
			"purchase":
				if e.get("result", "") == "ok" and e.get("product_id", "") == PRODUCT_ID:
					_grant()
				elif e.get("result", "") == "ok" and _grant_coins(str(e.get("product_id", ""))):
					pass
				else:
					purchase_done.emit(false, "The purchase didn't go through")
			"restore":
				# one event per restored item; the "completion" event below reports once at the end
				if e.get("result", "") == "ok" and e.get("product_id", "") == PRODUCT_ID:
					Ads.set_ads_removed(true)
				elif e.get("result", "") != "ok":
					restore_done.emit(Save.ads_removed)   # restore failed (offline, cancelled sign-in)
			"completion":
				restore_done.emit(Save.ads_removed)
