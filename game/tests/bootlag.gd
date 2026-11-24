extends Node
## Records slow frames from start-up through the loading screen into the menu.
var t := 0.0
var slow := []
var deltas := []
var main
func _ready():
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
func _process(delta):
	t += delta
	if t > 0.5:
		deltas.append(delta)
		if delta > 0.05: slow.append("%.2fs:%dms" % [t, int(delta * 1000)])
	if t > 9.0:
		deltas.sort()
		print("BOOT slow=", slow, " median=", int(deltas[deltas.size() / 2] * 1000), "ms")
		get_tree().quit()
