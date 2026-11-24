extends Node
func _ready():
	var A = get_tree().root.get_node("Ads")
	var S = get_tree().root.get_node("Save")
	S.ads_removed = false
	var shown := []
	var ran := [0]
	for lv in range(1, 20):
		var due: bool = A.interstitial_due(lv)
		A.after_level(lv, func(): ran[0] += 1)
		if due: shown.append(lv)
		A._last_ad_time = -1000.0   # pretend time passed
	var quick := []
	for lv in range(20, 30):
		if A.interstitial_due(lv): quick.append(lv)
		A.after_level(lv, func(): ran[0] += 1)
	A.set_ads_removed(true)
	A._last_ad_time = -1000.0
	var removed := []
	for lv in range(30, 40):
		if A.interstitial_due(lv): removed.append(lv)
		A.after_level(lv, func(): ran[0] += 1)
	S.ads_removed = false; S.save_game()
	print("ADS backend=", A.backend, " ads after levels ", shown, " | within 90s: ", quick, " | after remove-ads: ", removed, " | next level started ", ran[0], "/39")
	get_tree().quit()
