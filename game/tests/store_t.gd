extends Node
## Stress test for the iPhone store event handling, with a fake InAppStore plugin that sends
## the same events as godot-ios-plugins/inappstore (progress, ok, error, restore ok/completed/error).

class FakeApple:
	var q: Array = []
	var bought := {}
	func get_pending_event_count() -> int: return q.size()
	func pop_pending_event() -> Variant: return q.pop_front()
	func request_product_info(_p: Dictionary) -> int: return OK
	func set_auto_finish_transaction(_b: bool) -> void: pass
	func purchase(p: Dictionary) -> int:
		if not p["product_id"] in ["remove_ads", "coins_500", "coins_1800", "coins_3500"]:
			return ERR_INVALID_PARAMETER
		q.append({"type": "purchase", "result": "progress", "product_id": p["product_id"]})
		return OK
	func restore_purchases() -> int: return OK

var log: Array = []
var bad: Array = []
var main

func _ready():
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().create_timer(0.5).timeout
	var S = get_tree().root.get_node("Save")
	var St = get_tree().root.get_node("Store")
	var fake := FakeApple.new()
	St._apple = fake
	St.backend = "apple"
	St.purchase_done.connect(func(ok, msg): log.append("purchase:%s:%s" % [ok, msg]))
	St.restore_done.connect(func(found): log.append("restore:%s" % found))
	St.coins_bought.connect(func(n): log.append("coins:%d" % n))
	for round in 5:
		S.ads_removed = false
		# 1) coin pack: buy sheet open (progress) for a while, then success
		log.clear()
		var c0: int = S.coins
		St.buy_coins("coins_500")
		await _frames(10)
		if log.size() != 0: bad.append("r%d progress produced %s" % [round, log])
		fake.q.append({"type": "purchase", "result": "ok", "product_id": "coins_500"})
		await _frames(5)
		if log != ["coins:500"]: bad.append("r%d coins ok -> %s" % [round, log])
		await _frames(5)
		if S.coins != c0 + 500: bad.append("r%d coins not added %d -> %d" % [round, c0, S.coins])
		# 2) cancelled / failed purchase -> one failure message
		log.clear()
		St.buy_coins("coins_1800")
		await _frames(3)
		fake.q.append({"type": "purchase", "result": "error", "error": "cancelled", "product_id": "coins_1800"})
		await _frames(5)
		if log != ["purchase:false:The purchase didn't go through"]: bad.append("r%d error -> %s" % [round, log])
		# 3) restore with nothing bought -> one "not found"
		log.clear()
		St.restore()
		fake.q.append({"type": "restore", "result": "completed"})
		await _frames(5)
		if log != ["restore:false"]: bad.append("r%d empty restore -> %s" % [round, log])
		# 4) buy remove_ads with progress then ok
		log.clear()
		St.buy_remove_ads()
		await _frames(3)
		fake.q.append({"type": "purchase", "result": "progress", "product_id": "remove_ads"})
		fake.q.append({"type": "purchase", "result": "ok", "product_id": "remove_ads"})
		await _frames(5)
		if not S.ads_removed or log != ["purchase:true:Ads between levels are gone"]: bad.append("r%d remove_ads -> %s removed=%s" % [round, log, S.ads_removed])
		# 5) new phone: restore brings it back
		S.ads_removed = false
		log.clear()
		St.restore()
		fake.q.append({"type": "restore", "result": "ok", "product_id": "remove_ads"})
		fake.q.append({"type": "restore", "result": "completed"})
		await _frames(5)
		if not S.ads_removed or log != ["restore:true"]: bad.append("r%d restore -> %s removed=%s" % [round, log, S.ads_removed])
		# 6) restore fails (offline / sign-in cancelled)
		S.ads_removed = false
		log.clear()
		St.restore()
		fake.q.append({"type": "restore", "result": "error", "error": "offline"})
		await _frames(5)
		if log != ["restore:false"]: bad.append("r%d restore error -> %s" % [round, log])
		# 7) unknown product (not set up in App Store Connect) -> message, not silence
		log.clear()
		St._apple_buy("coins_unknown")
		await _frames(3)
		if log != ["purchase:false:The purchase didn't go through"]: bad.append("r%d unknown -> %s" % [round, log])
	print("STORE bad=", bad)
	print("STORE PASS" if bad.is_empty() else "STORE FAIL")
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
