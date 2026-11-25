extends Control
## Screens and buttons: title menu, game, and the level-complete card.
## The UI is built in code so the whole game lives in a few readable files.

const BoardScript := preload("res://scripts/board.gd")
const BackdropScript := preload("res://scripts/backdrop.gd")
const MapViewScript := preload("res://scripts/map_view.gd")
const MenuSceneScript := preload("res://scripts/menu_scene.gd")
const IconButton := preload("res://scripts/icon_button.gd")
const LoadingScript := preload("res://scripts/loading.gd")
const LOGO_FONT := preload("res://fonts/Fredoka-Bold.woff2")
const UI_FONT := preload("res://fonts/Baloo2-Bold.woff2")
const UI_FONT_HEAVY := preload("res://fonts/Baloo2-ExtraBold.woff2")
const INK := Color("#f3f5ff")
const MUTED := Color("#9aa6d6")
const GOLD := Color("#ffd93b")

var board: Control
var backdrop: Control
var chapter_label: Label
var level_label: Label
var toast: PanelContainer
var info_label: Label
var hint_btn: Button
var undo_btn: Button
var sound_btn: Button
var menu_layer: Control
var menu_scene: Control
var menu_play_btn: Button
var map_layer: Control
var map_view: Control
var map_play_sub: Label
var map_coin_chip: Button
var _map_from := "menu"
var play_sub: Label
var hint_chip: Button
var settings_layer: Control
var privacy_layer: Control
var lang_layer: Control
var lang_btn: Button
var _lang_grid: GridContainer
var _switches := {}
var chapter_num: Label
var chapter_name: Label
var chapter_count: Label
var chapter_bar: ProgressBar
var daily_btn: Button
var daily_icon: Control
var daily_title: Label
var daily_sub: Label
var daily_streak: Label
var win_layer: Control
var win_title: Label
var win_label: Label
var next_btn: Button
var tip_layer: Control
var tip_title: Label
var tip_text: Label

var state: Dictionary = {}
var start_state: Dictionary = {}
var mode := "level"          # "level" or "daily"
var daily_date := ""
var tip_queue: Array = []
var history: Array = []
var moves := 0
var _info_timer := 0.0
var _clock := 0.0
## GUESS: 3 undos per level keeps it challenging. More can come from a rewarded ad.
const UNDOS_PER_LEVEL := 3
var undos_left := UNDOS_PER_LEVEL
var won := false        # the puzzle is solved and the celebration is running
var _round := 0         # changes whenever a new puzzle starts, so old timers can tell
# First-level tutorial: a hand shows the first pours, then the player finishes alone.
const TUT_GUIDED := 2   # GUESS: two guided pours teach "pick up, then pour"
var tut := {}           # {"step": [from, to], "pours": n} while the hand shows
var _toast_style: StyleBoxFlat
# Hard levels have a move limit, worked out on a background thread when the level starts.
var move_limit := 0             # fewest pours + buffer for this level (0 = no limit)
var moves_max := 0              # move_limit plus any +5 bought with a video
var _limit_task := -1
var _hint_plan := {}
# The next level is made on a background thread while the win card shows, so starting it never stutters.
var _prefetch_task := -1
var _prefetch := {}             # {"level", "state", "path"}            # {"keys": [position before each move], "moves": [...]}
var _limit_result := []
var _prefetch_state := {}         # {"level", "state"}: set by the background task as soon as the level is made
var _prefetch_mutex := Mutex.new()
var moves_pill: PanelContainer
var moves_label: Label
var out_layer: Control
var hard_tint: TextureRect     # red-violet glow around the edges on Hard levels
var hard_banner: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_sb: StyleBoxFlat
var _tint_hard: GradientTexture2D
var _tint_extreme: GradientTexture2D
var _toast_gold: StyleBoxFlat

# ---------- coins (v0.14) ----------
# Earned by solving puzzles, spent on hints, undos, moves and mending the cracked jar. Prices are high on
# purpose so the free video stays the easy choice. GUESS: all numbers can be tuned after launch.
const COIN_LEVEL := 10
const COIN_HARD := 25
const COIN_EXTREME := 50
const COIN_DAILY := 30
const PRICE := {"hint": 150, "undo": 100, "moves": 120, "jar": 200}
const CRACK_FROM := 3           # GUESS: the cracked jar appears from level 3 (and in the daily puzzle)
var level_coins: Button         # coin counter on the level screen
var coin_chip: Button           # coin counter on the menu
var win_coins_row: Control
var win_gain_label: Label
var win_total_label: Label
var double_btn: Button
var _win_gain := 0
var _used_hint := false
# Skill streak: on normal levels (from level 3) finish within `target` pours and without a hint.
# On Hard/Extreme levels, win with 3+ pours to spare and without losing a heart on that level.
const STREAK_FROM := 3
const STREAK_SPARE := 3
const STREAK_BONUS := {3: 15, 5: 30, 10: 60}   # GUESS: bonus sizes
var target := 0
var _heart_lost_at := 0
var side_streak: Button
var offer_layer: Control
var offer_title: Label
var offer_text: Label
var offer_ad_btn: Button
var offer_coin_btn: Button
var _offer_kind := ""
var store_layer: Control
var trophies_layer: Control
var trophy_list: VBoxContainer
var trophy_count: Label
var boards_btn: Button
var top_toast: PanelContainer
var top_toast_kind: Label
var top_toast_text: Label
var _toast_queue: Array = []
var _toast_busy := false
var moves_coin_btn: Button
var remove_ads_btn: Button
var skins_layer: Control
var skins_tab := "jar"
var skins_pick := ""
var skins_grid: GridContainer
var skins_tabs := {}
var skins_coins: Label
var skins_action: Button
var side_skins: Button
var privacy_choices_btn: Button
var _extra_token := 0

func _ready() -> void:
	Art.jar_skin = Save.jar_skin
	Art.fly_skin = Save.fly_skin
	Art.region = Art.chapter_of(Save.level).theme
	theme = _make_theme()
	_build_game_ui()
	_build_menu()
	_build_win()
	_build_map()
	_build_tip()
	Ads.reward_granted.connect(_on_reward)
	board.extra_tapped.connect(_on_extra_tapped)
	Store.purchase_done.connect(func(ok: bool, msg: String):
		_top_toast("Thank you!" if ok else "Purchase", msg, false)
		_refresh_store()
		_refresh_side())
	Store.restore_done.connect(func(found: bool): _top_toast("Restore purchases", "Remove ads is active" if found else "No purchases found", false); _refresh_store())
	Store.test_store_requested.connect(_show_test_store)
	Store.coins_bought.connect(func(n: int):
		_add_coins(n, "purchase")
		Sound.play("jar_done")
		_top_toast("Thank you!", I18n.t("+{0} coins", [n]), false)
		_refresh_skins())
	Services.changed.connect(_refresh)
	I18n.changed.connect(_on_language_changed)
	_build_offer()
	_build_top_toast()
	Services.check_trophies()   # quietly unlock anything earned before trophies existed
	Ads.reward_unavailable.connect(func(_kind): _say("No video available right now. Try again soon"))
	resized.connect(_place_hero)
	_show_menu()
	# loading screen on top; it fades away to reveal the menu
	var loading: Control = LoadingScript.new()
	loading.logo_font = LOGO_FONT
	loading.ui_font = UI_FONT_HEAVY
	loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(loading)

func _process(delta: float) -> void:
	if _limit_task != -1 and WorkerThreadPool.is_task_completed(_limit_task):
		WorkerThreadPool.wait_for_task_completion(_limit_task)
		_limit_task = -1
		if _limit_result.size() == 3 and _limit_result[0] == Save.level and mode == "level":
			if Puzzle.is_hard(Save.level):
				move_limit = _limit_result[1]
			else:
				target = _limit_result[1]
				if target > 0 and not Save.seen.has("streak"):
					_show_tip("streak")
			if not _limit_result[2].is_empty():
				_hint_plan = _plan_from(start_state, _limit_result[2])   # hints on this level follow the shortest route
			if moves_max == 0:
				moves_max = move_limit
			_refresh()
	if _info_timer > 0.0:
		_info_timer -= delta
		toast.modulate.a = clampf(_info_timer / 0.3, 0.0, 1.0)
		if _info_timer <= 0.0:
			toast.hide()
	_lives_clock += delta
	if _lives_clock > 1.0:
		_lives_clock = 0.0
		_refresh_lives()
		if side_gift and menu_layer.visible and side_gift.get_meta("badge"):
			side_gift.queue_redraw()
	if side_streak and menu_layer.visible and Save.skill > 0:
		side_streak.queue_redraw()
	if side_skins and menu_layer.visible:
		side_skins.queue_redraw()
	if skins_layer and skins_layer.visible:
		for t in skins_grid.get_children():
			t.queue_redraw()
	_clock += delta
	if _clock > 20.0 and menu_layer.visible:
		_clock = 0.0
		_refresh()

# ---------- building the screens ----------

func _glass(radius := 34, alpha := 0.6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.17, alpha)
	sb.border_color = Color(0.72, 0.8, 1.0, 0.28)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	return sb

func _gold(pressed := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ffb938") if pressed else Color("#ffc94a")
	sb.border_color = Color("#b8620f")
	sb.border_width_bottom = 2 if pressed else 12
	sb.set_corner_radius_all(40)
	sb.anti_aliasing = true
	sb.shadow_color = Color(1.0, 0.75, 0.2, 0.35)
	sb.shadow_size = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UI_FONT
	t.default_font_size = 34
	t.set_stylebox("normal", "Button", _gold())
	t.set_stylebox("hover", "Button", _gold())
	t.set_stylebox("pressed", "Button", _gold(true))
	t.set_stylebox("disabled", "Button", _gold())
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color("#3a2400"))
	t.set_color("font_pressed_color", "Button", Color("#3a2400"))
	t.set_color("font_hover_color", "Button", Color("#3a2400"))
	t.set_font("font", "Button", UI_FONT_HEAVY)
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _glass())
	return t

func _label(text: String, fs: int, col := INK, font: Font = UI_FONT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _spaced(font: Font, spacing: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = font
	fv.spacing_glyph = spacing
	return fv

func _icon_btn(icon_name: String, pos: Vector2, sz := Vector2(92, 92)) -> Button:
	var b: Button = IconButton.new()
	b.icon_name = icon_name
	b.font = UI_FONT_HEAVY
	b.position = pos
	b.size = sz
	b.custom_minimum_size = sz
	return b

## The glow around the screen edges on Hard (pink) and Extreme (red) levels.
func _tint_tex(mid: Color, edge: Color, start: float) -> GradientTexture2D:
	var tg := Gradient.new()
	tg.set_color(0, Color(mid, 0.0))
	tg.add_point(start, Color(mid, 0.0))
	tg.add_point(0.86, Color(mid, 0.3))
	tg.set_color(tg.get_point_count() - 1, edge)
	var tex := GradientTexture2D.new()
	tex.gradient = tg
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.08, 0.45)
	tex.width = 256
	tex.height = 256
	return tex

func _build_game_ui() -> void:
	backdrop = BackdropScript.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	hard_tint = TextureRect.new()
	_tint_hard = _tint_tex(Color(0.78, 0.16, 0.55), Color(0.47, 0.08, 0.43, 0.55), 0.62)
	_tint_extreme = _tint_tex(Color(0.9, 0.16, 0.12), Color(0.55, 0.04, 0.04, 0.6), 0.56)
	hard_tint.texture = _tint_hard
	hard_tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hard_tint.stretch_mode = TextureRect.STRETCH_SCALE
	hard_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hard_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hard_tint.hide()
	add_child(hard_tint)

	board = BoardScript.new()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.offset_top = 170
	board.offset_bottom = -190
	board.offset_left = 20
	board.offset_right = -20
	board.jar_tapped.connect(_on_jar_tapped)
	board.empty_tapped.connect(_on_empty_tapped)
	board.drag_dropped.connect(_on_drag_dropped)
	add_child(board)

	var home := _icon_btn("home", Vector2(32, 44))
	home.pressed.connect(func(): _confirm_leave("menu", _show_menu))
	add_child(home)
	sound_btn = _icon_btn("sound_on", Vector2.ZERO)
	sound_btn.pressed.connect(func():
		var on := not (Save.music_on or Save.sfx_on)
		Save.music_on = on
		Save.sfx_on = on
		Save.save_game()
		Sound.apply_settings()
		_refresh())
	add_child(sound_btn)
	sound_btn.hide()   # sound lives in Settings now; the coin counter takes its place
	var restart_btn := _icon_btn("restart", Vector2.ZERO)
	restart_btn.pressed.connect(_restart)
	add_child(restart_btn)
	level_coins = _icon_btn("coin", Vector2.ZERO, Vector2(160, 92))
	level_coins.round_shape = false
	level_coins.label = "0"
	level_coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_coins)
	# keep anchored buttons pinned to the right edge
	var bx := -32 - 92 - 16 - 160
	for b in [level_coins, restart_btn]:
		var w: float = b.custom_minimum_size.x
		b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		b.offset_left = bx
		b.offset_right = bx + w
		b.offset_top = 44
		b.offset_bottom = 136
		bx += int(w) + 16

	chapter_label = _label("MEADOW GLOW", 24, MUTED, _spaced(UI_FONT_HEAVY, 6))
	chapter_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.16, 0.55))   # readable on the bright regions too
	chapter_label.add_theme_constant_override("outline_size", 8)
	chapter_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	chapter_label.offset_left = 132
	chapter_label.offset_right = -312
	chapter_label.offset_top = 36
	chapter_label.offset_bottom = 72
	add_child(chapter_label)
	level_label = _label("Level 1", 60, Color("#fff3c4"), LOGO_FONT)
	level_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.16, 0.5))
	level_label.add_theme_constant_override("outline_size", 10)
	level_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	level_label.offset_left = 132
	level_label.offset_right = -312
	level_label.offset_top = 66
	level_label.offset_bottom = 146
	level_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.3, 0.45))
	level_label.add_theme_constant_override("shadow_outline_size", 14)
	level_label.add_theme_constant_override("shadow_offset_x", 0)
	level_label.add_theme_constant_override("shadow_offset_y", 0)
	add_child(level_label)

	var pill_row := CenterContainer.new()
	pill_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	pill_row.offset_top = 140
	pill_row.offset_bottom = 184
	pill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_pill = PanelContainer.new()
	moves_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_label = _label("", 24, Color("#ffe3f1"), UI_FONT_HEAVY)
	moves_pill.add_child(moves_label)
	moves_pill.hide()
	pill_row.add_child(moves_pill)
	add_child(pill_row)

	toast = PanelContainer.new()
	var ts := _glass(40, 0.8)
	ts.content_margin_top = 12
	ts.content_margin_bottom = 12
	toast.add_theme_stylebox_override("panel", ts)
	_toast_style = ts
	_toast_gold = ts.duplicate()
	_toast_gold.bg_color = Color(1.0, 0.85, 0.23, 0.95)
	_toast_gold.border_color = Color(1.0, 0.95, 0.7, 0.9)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toast_row := CenterContainer.new()
	toast_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_row.offset_top = 190
	toast_row.offset_bottom = 264
	toast_row.offset_left = 32
	toast_row.offset_right = -32
	toast_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_label = _label("", 28)
	toast.add_child(info_label)
	toast.hide()
	toast_row.add_child(toast)
	add_child(toast_row)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -164
	bottom.offset_bottom = -44
	bottom.offset_left = 32
	bottom.offset_right = -32
	bottom.add_theme_constant_override("separation", 28)
	add_child(bottom)
	undo_btn = _icon_btn("undo", Vector2.ZERO, Vector2(0, 120))
	undo_btn.round_shape = false
	undo_btn.label = "Undo"
	undo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_btn.pressed.connect(_undo)
	bottom.add_child(undo_btn)
	hint_btn = _icon_btn("bulb", Vector2.ZERO, Vector2(0, 120))
	hint_btn.round_shape = false
	hint_btn.label = "Hint"
	hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_btn.pressed.connect(_on_hint_pressed)
	bottom.add_child(hint_btn)

func _overlay() -> Control:
	var layer := ColorRect.new()
	layer.color = Color(0.02, 0.03, 0.09, 0.78)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	return layer

func _card(layer: Control, width := 600) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	var sb := _glass(48, 0.88)
	sb.content_margin_left = 44
	sb.content_margin_right = 44
	sb.content_margin_top = 44
	sb.content_margin_bottom = 44
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 30
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	panel.add_child(box)
	_wrap_texts.call_deferred(box)
	return box

## Long words in some languages (German, Russian...) must not push a card off the screen:
## titles, texts and buttons that span the card's width wrap onto a second line instead.
func _wrap_texts(n: Node) -> void:
	for c in n.get_children():
		if not c is Control:
			continue
		var in_column: bool = n is VBoxContainer and (n.get_parent() is PanelContainer or (n as Control).size_flags_horizontal & Control.SIZE_EXPAND)
		var in_row: bool = n is HBoxContainer and (c as Control).size_flags_horizontal & Control.SIZE_EXPAND
		var spans := in_column or in_row
		if spans and c is Label and c.autowrap_mode == TextServer.AUTOWRAP_OFF:
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		elif spans and c is Button and not c is IconButton and c.text != "":
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if c is Container:
			_wrap_texts(c)

func _build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)
	menu_scene = MenuSceneScript.new()
	menu_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_scene)

	hint_chip = _icon_btn("bulb", Vector2(28, 48), Vector2(124, 84))
	hint_chip.round_shape = false
	hint_chip.label = "3"
	hint_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(hint_chip)
	coin_chip = _icon_btn("coin", Vector2(28 + 124 + 10, 48), Vector2(150, 84))
	coin_chip.round_shape = false
	coin_chip.label = "0"
	coin_chip.pressed.connect(_show_skins)
	menu_layer.add_child(coin_chip)
	lives_chip = _lives_chip(Vector2(28 + 124 + 10 + 150 + 10, 48))
	menu_layer.add_child(lives_chip)
	var trophy := _icon_btn("trophy", Vector2.ZERO, Vector2(84, 84))
	trophy.icon_color = Color("#ffd24a")
	trophy.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	trophy.offset_left = -28 - 84 - 10 - 84
	trophy.offset_right = -28 - 84 - 10
	trophy.offset_top = 48
	trophy.offset_bottom = 132
	menu_layer.add_child(trophy)
	trophy.pressed.connect(_show_trophies)
	var gear := _icon_btn("gear", Vector2.ZERO, Vector2(84, 84))
	gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_left = -28 - 84
	gear.offset_right = -28
	gear.offset_top = 48
	gear.offset_bottom = 132
	menu_layer.add_child(gear)
	gear.pressed.connect(_show_settings)

	# logo: "Jar" in glowing gold, "WORLD" spaced out in a glass pill
	var logo := _label("Jar", 124, GOLD, LOGO_FONT)   # small enough to stay clear of the side buttons on the right
	logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo.offset_top = 150
	logo.offset_bottom = 340
	logo.add_theme_color_override("font_outline_color", Color("#ff9f43"))
	logo.add_theme_constant_override("outline_size", 10)
	logo.add_theme_color_override("font_shadow_color", Color(1.0, 0.78, 0.25, 0.5))
	logo.add_theme_constant_override("shadow_outline_size", 30)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	menu_layer.add_child(logo)
	var pill := PanelContainer.new()
	var ps := _glass(36, 0.88)
	ps.content_margin_top = 4
	ps.content_margin_bottom = 4
	ps.content_margin_left = 44
	ps.content_margin_right = 30
	pill.add_theme_stylebox_override("panel", ps)
	pill.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pill.offset_top = 330
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(_label("WORLD", 46, Color("#dfe7ff"), _spaced(UI_FONT_HEAVY, 26)))
	menu_layer.add_child(pill)

	# bottom panel: chapter progress, Play and the daily puzzle
	var panel := PanelContainer.new()
	var sb := _glass(48, 0.62)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_bottom = -40
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", -6)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(names)
	chapter_num = _label("CHAPTER 1", 26, MUTED, _spaced(UI_FONT_HEAVY, 5), HORIZONTAL_ALIGNMENT_LEFT)
	names.add_child(chapter_num)
	chapter_name = _label("Meadow Glow", 40, INK, UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT)
	names.add_child(chapter_name)
	chapter_count = _label("0 / 10", 30, MUTED, UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_RIGHT)
	chapter_count.text_direction = Control.TEXT_DIRECTION_LTR   # "4 / 10" must not turn into "10 / 4" in Arabic
	chapter_count.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.add_child(chapter_count)
	chapter_bar = ProgressBar.new()
	chapter_bar.show_percentage = false
	chapter_bar.max_value = 10
	chapter_bar.custom_minimum_size = Vector2(0, 18)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.08)
	bg.set_corner_radius_all(9)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#ffc23d")
	fill.set_corner_radius_all(9)
	chapter_bar.add_theme_stylebox_override("background", bg)
	chapter_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(chapter_bar)

	menu_play_btn = Button.new()
	menu_play_btn.custom_minimum_size = Vector2(0, 176)
	menu_play_btn.pressed.connect(func():
		Sound.play("select")
		_show_map("menu"))
	box.add_child(menu_play_btn)
	var pv := VBoxContainer.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", -18)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_play_btn.add_child(pv)
	pv.add_child(_label("Play", 80, Color("#2e1c00"), LOGO_FONT))
	play_sub = _label("Level 1", 34, Color("#6b4200"), UI_FONT_HEAVY)
	pv.add_child(play_sub)

	daily_btn = Button.new()
	daily_btn.custom_minimum_size = Vector2(0, 128)
	var ds := _glass(34, 0.35)
	ds.border_color = Color(1.0, 0.7, 0.3, 0.5)
	daily_btn.add_theme_stylebox_override("normal", ds)
	daily_btn.add_theme_stylebox_override("hover", ds)
	var dp := ds.duplicate()
	dp.bg_color = Color(0.16, 0.2, 0.39, 0.7)
	daily_btn.add_theme_stylebox_override("pressed", dp)
	daily_btn.pressed.connect(func():
		Sound.play("select")
		_start_daily())
	box.add_child(daily_btn)
	var dh := HBoxContainer.new()
	dh.set_anchors_preset(Control.PRESET_FULL_RECT)
	dh.offset_left = 28
	dh.offset_right = -28
	dh.add_theme_constant_override("separation", 24)
	dh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_btn.add_child(dh)
	daily_icon = Control.new()
	daily_icon.custom_minimum_size = Vector2(84, 84)
	daily_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	daily_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_icon.draw.connect(_draw_daily_icon)
	dh.add_child(daily_icon)
	var dv := VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_theme_constant_override("separation", -8)
	dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dh.add_child(dv)
	daily_title = _label("Daily puzzle", 40, Color("#fff3c4"), UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT)
	dv.add_child(daily_title)
	daily_sub = _label("A new puzzle every day", 26, MUTED, UI_FONT, HORIZONTAL_ALIGNMENT_LEFT)
	dv.add_child(daily_sub)
	var flame := Control.new()
	flame.custom_minimum_size = Vector2(40, 40)
	flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame.draw.connect(func(): Art.icon(flame, "flame", flame.size * 0.5, 40, Color("#ff9f43")))
	dh.add_child(flame)
	daily_streak = _label("", 36, Color("#ffb070"), UI_FONT_HEAVY)
	daily_streak.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dh.add_child(daily_streak)
	_build_side()
	_place_hero.call_deferred()

## The big menu jar stands between the logo and the bottom panel.
func _place_hero() -> void:
	if menu_scene == null:
		return
	var panel_top := size.y - 40.0 - 560.0
	for c in menu_layer.get_children():
		if c is PanelContainer and c.size.y > 300.0:
			panel_top = c.global_position.y
	var top := 430.0
	var space := panel_top - top
	var jh: float = min(space * 0.92, size.x * 0.62)
	var jw := jh * 0.62
	menu_scene.hero = Rect2(size.x * 0.5 - jw * 0.5, top + (space - jh) * 0.5 + jh * 0.04, jw, jh)

func _draw_daily_icon() -> void:
	var done := Save.daily_done == Save.today()
	var c := daily_icon.size * 0.5
	var col := Color("#3fcf6a") if done else Color("#ffb33b")
	Art.glow(daily_icon, c, 52, col, 0.5)
	daily_icon.draw_circle(c, 42, col)
	daily_icon.draw_circle(c + Vector2(-6, -8), 30, Color(col.lightened(0.35), 0.6))
	Art.icon(daily_icon, "check" if done else "sun", c, 52, Color("#0d3a1a") if done else Color("#3a2400"))

func _build_win() -> void:
	win_layer = _overlay()
	var box := _card(win_layer)
	win_title = _label("All glowing!", 76, GOLD, LOGO_FONT)
	win_title.add_theme_color_override("font_shadow_color", Color(1.0, 0.78, 0.25, 0.45))
	win_title.add_theme_constant_override("shadow_outline_size", 20)
	win_title.add_theme_constant_override("shadow_offset_y", 0)
	box.add_child(win_title)
	win_label = _label("", 32, INK)
	win_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(win_label)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.add_theme_constant_override("separation", 28)
	var gain := PanelContainer.new()
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color("#ffd24a")
	gs.set_corner_radius_all(40)
	gs.shadow_color = Color(1.0, 0.78, 0.25, 0.5)
	gs.shadow_size = 22
	gs.content_margin_left = 18
	gs.content_margin_right = 28
	gs.content_margin_top = 4
	gs.content_margin_bottom = 4
	gs.anti_aliasing = true
	gain.add_theme_stylebox_override("panel", gs)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 10)
	gh.add_child(_coin_icon(56))
	win_gain_label = _label("+10", 56, Color("#3a2205"), LOGO_FONT)
	gh.add_child(win_gain_label)
	gain.add_child(gh)
	gain.name = "Gain"
	cr.add_child(gain)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	th.add_child(_coin_icon(40))
	win_total_label = _label("0", 40, Color("#ffe8a3"), UI_FONT_HEAVY)
	th.add_child(win_total_label)
	th.name = "Total"
	cr.add_child(th)
	win_coins_row = cr
	box.add_child(cr)
	double_btn = _coin_btn("")
	double_btn.pressed.connect(func():
		double_btn.disabled = true
		_reward_or_say("double"))
	box.add_child(double_btn)
	next_btn = Button.new()
	next_btn.text = "Next level"
	next_btn.custom_minimum_size = Vector2(0, 120)
	next_btn.add_theme_font_size_override("font_size", 44)
	next_btn.pressed.connect(func():
		Sound.play("select")
		if mode == "practice":
			_show_menu()
		elif mode == "daily":
			_start_level()
		else:
			# a short ad between levels every few levels (see ads.gd), then the next level
			win_layer.hide()
			Ads.after_level(Save.level - 1, func():
				# finishing a chapter opens the map, where the next chapter lights up
				if map_view.new_chapter_waiting():
					_show_map("win")
				else:
					_start_level()))
	box.add_child(next_btn)
	win_layer.hide()

func _build_tip() -> void:
	tip_layer = _overlay()
	var box := _card(tip_layer, 620)
	tip_title = _label("", 56, GOLD, LOGO_FONT)
	box.add_child(tip_title)
	tip_text = _label("", 32, INK)
	tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_text.custom_minimum_size = Vector2(520, 0)
	box.add_child(tip_text)
	var ok := Button.new()
	ok.text = "Got it"
	ok.custom_minimum_size = Vector2(0, 110)
	ok.add_theme_font_size_override("font_size", 42)
	ok.pressed.connect(func():
		Sound.play("select")
		_show_next_tip())
	box.add_child(ok)
	tip_layer.hide()

const TIPS := {
	"color_jar": ["Color jars", "A jar with a colored ribbon on its neck only accepts fireflies of that color. Plan ahead!"],
	"lid": ["Lidded jars", "The fireflies in a lidded jar are asleep. The number counts down by one with every pour you make. At zero, the lid pops off and you can use the jar."],
	"cracked_jar": ["The cracked jar", "This jar is cracked. Tap it, and two helper fireflies will fly in and mend it. Then it's one more empty jar for this level."],
	"daily": ["Daily puzzle", "A new puzzle every day, with color jars and a lid. Solve it every day to grow your streak."],
	"hard": ["Hard level", "The 5th level of every chapter is Hard: more colors and a move limit (the number under the level). Win for 25 coins and a hint. If you give up, you lose a heart."],
	"extreme": ["Extreme level", "The last level of every chapter is Extreme: even more colors and fewer spare moves. Win for 50 coins and a hint. If you give up, you lose a heart."],
	"lives": ["Hearts", "You lost a heart. You have 5 for Hard and Extreme levels, and one comes back every 20 minutes. Normal levels never cost hearts."],
	"coins": ["Coins", "You earn coins for every level you solve. Spend them on hints, undos, extra moves, hearts and mending cracked jars."],
	"streak": ["Skill streak", "Finish a level within the target moves, without a hint, and your streak grows. On Hard and Extreme levels, win with 3 or more moves to spare without losing a heart. Bonus coins at 3, 5 and 10 in a row! Miss, and it starts again from 0."],
	"map": ["Your firefly trail", "Every level is a stone on this trail. Gold ones are done and yours glows. Hard levels have a pink star, Extreme levels a gold crown. Tap your level or Play to start."],
}

## Show one card now (or after the one on screen), also outside the start of a level.
func _show_tip(k: String) -> void:
	if not tip_queue.has(k):
		tip_queue.append(k)
	if not tip_layer.visible:
		_show_next_tip()

func _maybe_tip() -> void:
	tip_queue = []
	if mode == "daily":
		tip_queue.append("daily")
	if mode == "level" and Puzzle.is_extreme(Save.level):
		tip_queue.append("extreme")
	elif mode == "level" and Puzzle.is_hard(Save.level):
		tip_queue.append("hard")
	if state.only.any(func(x): return x >= 0):
		tip_queue.append("color_jar")
	if state.locks.any(func(x): return x > 0):
		tip_queue.append("lid")
	if board.extra_index() >= 0:
		tip_queue.append("cracked_jar")
	tip_queue = tip_queue.filter(func(k): return not Save.seen.has(k))
	_show_next_tip()

func _show_next_tip() -> void:
	if tip_queue.is_empty():
		tip_layer.hide()
		return
	var k: String = tip_queue.pop_front()
	Save.seen[k] = true
	Save.save_game()
	tip_title.text = I18n.t("New: {0}", [tr(TIPS[k][0])])
	tip_text.text = TIPS[k][1]
	move_child(tip_layer, -1)
	tip_layer.show()

# ---------- hearts (lives), daily rewards and the menu's side buttons ----------

const LIFE_PRICE := 100
var lives_chip: Button
var map_lives_chip: Button
var leave_layer: Control
var leave_title: Label
var leave_text: Label
var leave_yes: Button
var _leave_go: Callable
var _leave_what := ""
var nolives_layer: Control
var nolives_time: Label
var nolives_coin_btn: Button
var gifts_layer: Control
var gifts_sub: Label
var gifts_grid: VBoxContainer
var gifts_claim: Button
var gifts_done: Label
var side_noads: Button
var side_gift: Button
var _lives_clock := 0.0

static func _mmss(sec: float) -> String:
	var s := int(ceil(sec))
	return "%d:%02d" % [s / 60, s % 60]

func _lives_chip(pos: Vector2) -> Button:
	var b := _icon_btn("heart", pos, Vector2(184, 84))
	b.round_shape = false
	b.label = "5"
	b.badge = "Full"
	b.badge_color = Color(1.0, 0.3, 0.43, 0.9)
	b.badge_text_color = Color.WHITE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _refresh_lives() -> void:
	var n := Save.lives_now()
	var t := Save.next_life_in()
	for b in [lives_chip, map_lives_chip]:
		if b:
			b.label = str(n)
			b.badge = "Full" if n >= Save.LIVES_MAX else _mmss(t)
			b.queue_redraw()
	if nolives_layer and nolives_layer.visible:
		nolives_time.text = tr("You have a heart again!") if n > 0 else I18n.t("Next heart in {0}", [_mmss(t)])

func _leaving_costs_life() -> bool:
	return mode == "level" and Puzzle.is_hard(Save.level) and not won and moves > 0 and not menu_layer.visible

func _lose_life(why: String) -> void:
	Save.lose_life()
	if mode == "level":
		_heart_lost_at = Save.level
	_refresh_lives()
	Analytics.log_event("life_lost", {"level": Save.level, "why": why, "left": Save.lives})
	if not Save.seen.has("lives"):
		get_tree().create_timer(0.4).timeout.connect(func(): _show_tip("lives"))

## "Leave this level? You'll lose a heart" before quitting or restarting a Hard/Extreme level.
func _confirm_leave(what: String, go: Callable) -> void:
	if not _leaving_costs_life():
		go.call()
		return
	if leave_layer == null:
		leave_layer = _overlay()
		var box := _card(leave_layer, 620)
		leave_title = _label("", 56, GOLD, LOGO_FONT)
		box.add_child(leave_title)
		leave_text = _label("", 32, INK)
		leave_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		leave_text.custom_minimum_size = Vector2(520, 0)
		box.add_child(leave_text)
		var keep := Button.new()
		keep.text = "Keep playing"
		keep.custom_minimum_size = Vector2(0, 110)
		keep.add_theme_font_size_override("font_size", 42)
		keep.pressed.connect(func():
			Sound.play("drop")
			leave_layer.hide())
		box.add_child(keep)
		leave_yes = _ghost_btn("Leave (−1 heart)", func():
			leave_layer.hide()
			_lose_life(_leave_what)
			if _leave_what == "restart" and Save.lives_now() <= 0:
				_show_menu()
				_show_no_lives()
				return
			_leave_go.call())
		box.add_child(leave_yes)
	_leave_go = go
	_leave_what = what
	leave_title.text = "Restart this level?" if what == "restart" else "Leave this level?"
	leave_text.text = I18n.t("You'll lose a heart. Hard and Extreme levels cost a heart when you give up. You have {0} left.", [Save.lives_now()])
	leave_yes.text = "Restart (−1 heart)" if what == "restart" else "Leave (−1 heart)"
	Sound.play("select")
	move_child(leave_layer, -1)
	leave_layer.show()

## Out of hearts: wait, watch a video, or pay coins.
func _show_no_lives() -> void:
	if nolives_layer == null:
		nolives_layer = _overlay()
		var box := _card(nolives_layer, 620)
		var heart := Control.new()
		heart.custom_minimum_size = Vector2(0, 150)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.draw.connect(func():
			Art.glow(heart, heart.size * 0.5, 110, Color("#ff4d6d"), 0.45)
			Art.icon(heart, "heart", heart.size * 0.5, 150, Color.WHITE))
		box.add_child(heart)
		box.add_child(_label("Out of hearts", 60, GOLD, LOGO_FONT))
		var txt := _label("Hard and Extreme levels need a heart. One comes back every 20 minutes, and the daily puzzle is always free.", 32, INK)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(520, 0)
		box.add_child(txt)
		nolives_time = _label("", 28, MUTED, UI_FONT_HEAVY)
		box.add_child(nolives_time)
		var vid := Button.new()
		vid.text = "Video: +1 heart"
		vid.custom_minimum_size = Vector2(0, 110)
		vid.add_theme_font_size_override("font_size", 42)
		vid.pressed.connect(func():
			nolives_layer.hide()
			_reward_or_say("life"))
		box.add_child(vid)
		nolives_coin_btn = _coin_btn("")
		nolives_coin_btn.pressed.connect(func():
			if not _spend_coins(LIFE_PRICE, "life"):
				return
			nolives_layer.hide()
			Sound.play("coin")
			Analytics.log_event("reward_choice", {"item": "life", "via": "coins"})
			Save.add_life()
			_refresh_lives()
			_say("+1 heart"))
		box.add_child(nolives_coin_btn)
		box.add_child(_ghost_btn("Wait", func():
			Sound.play("drop")
			nolives_layer.hide()))
	_set_coin_btn(nolives_coin_btn, LIFE_PRICE, "+1 heart for {0}")
	Sound.play("nope")
	move_child(nolives_layer, -1)
	nolives_layer.show()
	_refresh_lives()

func _needs_life(lv: int) -> bool:
	return Puzzle.is_hard(lv) and Save.lives_now() <= 0

## The round glowing buttons on the right of the menu: No ads, and Daily rewards.
func _side_btn(icon_name: String, text: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(124, 140)
	b.size = b.custom_minimum_size
	b.set_meta("badge", false)
	b.draw.connect(func():
		var c := Vector2(b.size.x * 0.5, 56)
		var r := 54.0 * (0.94 if b.is_pressed() else 1.0)
		var hot: bool = b.has_meta("streak") and Save.skill > 0
		Art.glow(b, c, r * (1.6 + (0.25 * sin(Time.get_ticks_msec() / 280.0) if hot else 0.0)), Color("#ff8a2a") if hot else Color("#ffc83c"), 0.55 if hot else 0.3)
		b.draw_circle(c, r, Color(0.07, 0.09, 0.22, 0.95))
		b.draw_circle(c - Vector2(r, r) * 0.18, r * 0.75, Color(0.24, 0.29, 0.59, 0.55))
		b.draw_arc(c, r, 0, TAU, 48, Color(1.0, 0.85, 0.23, 0.75), 4.0, true)
		Art.icon(b, icon_name, c, r * 1.15, Color("#ff9f43") if b.has_meta("streak") else Color.WHITE)
		var fs := 26
		var txt: String = str(b.get_meta("label", tr(text)))
		var tw := UI_FONT_HEAVY.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pill := Rect2(c.x - tw * 0.5 - 14, 98, tw + 28, 38)
		# a long label (like "Ohne Werbung") slides inward so it stays on screen (buttons sit 24 px from the edge)
		pill.position.x = maxf(pill.position.x, -20.0) if b.get_meta("left", false) else minf(pill.position.x, b.size.x + 20.0 - pill.size.x)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.055, 0.14, 0.9)
		sb.border_color = Color(1.0, 0.85, 0.23, 0.45)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(19)
		b.draw_style_box(sb, pill)
		b.draw_string(UI_FONT_HEAVY, Vector2(pill.position.x + 14, pill.position.y + 29), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		if b.get_meta("badge"):
			var bc := c + Vector2(r * 0.75, -r * 0.75)
			var s := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 220.0)
			b.draw_circle(bc, 22 * s, Color.WHITE)
			b.draw_circle(bc, 18 * s, Color("#ff3b5c"))
			b.draw_string(UI_FONT_HEAVY, bc + Vector2(-5, 10), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE))
	return b

func _build_side() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	# just under the top bar on the right, so it never covers the Play panel
	col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	col.offset_left = -24 - 124
	col.offset_right = -24
	col.offset_top = 150
	col.offset_bottom = 150
	menu_layer.add_child(col)
	side_noads = _side_btn("noads", "No ads")
	side_noads.pressed.connect(func():
		Sound.play("select")
		if not Save.ads_removed:
			Store.buy_remove_ads())
	col.add_child(side_noads)
	side_gift = _side_btn("gift", "Daily")
	side_gift.pressed.connect(_show_gifts)
	col.add_child(side_gift)
	side_streak = _side_btn("flame", "0")
	side_streak.set_meta("streak", true)
	side_streak.pressed.connect(func():
		Sound.play("select")
		_show_tip("streak"))
	col.add_child(side_streak)
	# the skins shop sits on the left, under the moon, where the right column has no room left
	side_skins = _side_btn("skins", "Skins")
	side_skins.set_anchors_preset(Control.PRESET_TOP_LEFT)
	side_skins.set_meta("left", true)
	side_skins.position = Vector2(24, 520)
	side_skins.pressed.connect(_show_skins)
	menu_layer.add_child(side_skins)

func _refresh_side() -> void:
	if side_noads == null:
		return
	side_noads.visible = not Save.ads_removed
	side_gift.set_meta("badge", Save.gift_state().ready)
	side_gift.queue_redraw()
	side_streak.visible = Save.skill > 0 or Save.seen.has("streak")
	side_streak.set_meta("label", str(Save.skill))
	side_streak.queue_redraw()

## The biggest font size (up to fs) at which the text fits in max_w.
func _fit_fs(text: String, fs: int, max_w: float, font: Font = null) -> int:
	var w := (font if font else UI_FONT_HEAVY).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return fs if w <= max_w else maxi(12, int(fs * max_w / w))

static func _gift_label(g: Dictionary) -> String:
	if g.has("coins"):
		return I18n.t("{0} coins", [g.coins])
	if g.has("hints"):
		return I18n.t("{0} hints", [g.hints]) if g.hints > 1 else I18n.t("1 hint")
	return I18n.t("Full hearts")

func _show_gifts() -> void:
	Sound.play("select")
	if gifts_layer == null:
		gifts_layer = _overlay()
		var box := _card(gifts_layer, 640)
		box.add_child(_label("Daily rewards", 60, GOLD, LOGO_FONT))
		gifts_sub = _label("", 28, INK)
		gifts_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gifts_sub.custom_minimum_size = Vector2(540, 0)
		box.add_child(gifts_sub)
		gifts_grid = VBoxContainer.new()
		gifts_grid.add_theme_constant_override("separation", 12)
		box.add_child(gifts_grid)
		for r in 2:
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 12)
			gifts_grid.add_child(row)
		gifts_claim = Button.new()
		gifts_claim.text = "Claim today's gift"
		gifts_claim.custom_minimum_size = Vector2(0, 110)
		gifts_claim.add_theme_font_size_override("font_size", 42)
		gifts_claim.pressed.connect(_claim_gift)
		box.add_child(gifts_claim)
		gifts_done = _label("Today's gift is claimed ✓", 28, MUTED, UI_FONT_HEAVY)
		box.add_child(gifts_done)
		box.add_child(_ghost_btn("Close", func():
			Sound.play("drop")
			gifts_layer.hide()))
	var st := Save.gift_state()
	var done: int = Save.gift_day if Save.gift_last == Save.today() else st.day
	for row in gifts_grid.get_children():
		for c in row.get_children():
			c.queue_free()
	for i in 7:
		var g: Dictionary = Save.DAILY_GIFTS[i]
		var got := i < done
		var now_day: bool = i == st.day and st.ready
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(270 if i == 6 else 129, 150)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.draw.connect(func():
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(1.0, 0.85, 0.23, 0.14) if now_day else Color(1, 1, 1, 0.05)
			sb.border_color = Color("#ffd93b") if now_day else Color(0.72, 0.8, 1.0, 0.28)
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(24)
			if now_day:
				sb.shadow_color = Color(1.0, 0.85, 0.23, 0.35)
				sb.shadow_size = 14
			cell.draw_style_box(sb, Rect2(Vector2.ZERO, cell.size))
			var a := 0.55 if got else 1.0
			var day_txt := I18n.t("Day {0}", [i + 1])
			cell.draw_string(UI_FONT_HEAVY, Vector2(0, 32), day_txt, HORIZONTAL_ALIGNMENT_CENTER, cell.size.x, _fit_fs(day_txt, 22, cell.size.x - 8), Color(MUTED, a))
			var ic := "check" if got else ("coin" if g.has("coins") else ("bulb" if g.has("hints") else "heart"))
			Art.icon(cell, ic, Vector2(cell.size.x * 0.5, 74), 50, Color(Color("#7dff6b") if got else Color("#ffd93b"), a))
			var gift_txt := _gift_label(g)
			cell.draw_string(UI_FONT_HEAVY, Vector2(0, 134), gift_txt, HORIZONTAL_ALIGNMENT_CENTER, cell.size.x, _fit_fs(gift_txt, 24, cell.size.x - 8), Color(INK, a)))
		gifts_grid.get_child(0 if i < 4 else 1).add_child(cell)
	gifts_claim.visible = st.ready
	gifts_done.visible = not st.ready
	gifts_sub.text = tr("Come back every day for a new gift. Day 7 is the biggest! Miss a day and it starts again.") if st.ready else I18n.t("Come back tomorrow for day {0}. Miss a day and it starts again from day 1.", [done % 7 + 1])
	move_child(gifts_layer, -1)
	gifts_layer.show()

func _claim_gift() -> void:
	var st := Save.gift_state()
	if not st.ready:
		return
	var g: Dictionary = Save.DAILY_GIFTS[st.day]
	Save.gift_day = st.day + 1
	Save.gift_last = Save.today()
	if g.has("coins"):
		_add_coins(g.coins, "daily_gift")
	if g.has("hints"):
		Save.hints += g.hints
	if g.has("lives"):
		Save.lives_now()
		Save.lives = Save.LIVES_MAX
	Save.save_game()
	Sound.play("jar_done")
	Analytics.log_event("daily_gift", {"day": st.day + 1})
	var got_text := I18n.t("+{0} coins", [g.coins]) if g.has("coins") else (I18n.t("Hearts refilled") if g.has("lives") else (I18n.t("+{0} hints", [g.hints]) if g.hints > 1 else I18n.t("+1 hint")))
	_top_toast(I18n.t("Day {0} gift", [st.day + 1]), got_text, false)
	_refresh()
	_refresh_lives()
	_refresh_side()
	_show_gifts()

# ---------- chapter map ----------

func _build_map() -> void:
	map_layer = Control.new()
	map_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(map_layer)
	map_view = MapViewScript.new()
	map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_layer.add_child(map_view)
	map_view.play_requested.connect(_map_play)
	var back := _icon_btn("home", Vector2(32, 44))
	back.pressed.connect(func():
		Sound.play("select")
		map_layer.hide()
		if _map_from != "menu":
			_show_menu())
	map_layer.add_child(back)
	map_coin_chip = _icon_btn("coin", Vector2.ZERO, Vector2(190, 92))
	map_coin_chip.round_shape = false
	map_coin_chip.label = "0"
	map_coin_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_coin_chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	map_coin_chip.offset_left = -32 - 190
	map_coin_chip.offset_right = -32
	map_coin_chip.offset_top = 44
	map_coin_chip.offset_bottom = 136
	map_layer.add_child(map_coin_chip)
	map_lives_chip = _lives_chip(Vector2.ZERO)
	map_lives_chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	map_lives_chip.offset_left = -32 - 190 - 14 - 184
	map_lives_chip.offset_right = -32 - 190 - 14
	map_lives_chip.offset_top = 48
	map_lives_chip.offset_bottom = 132
	map_layer.add_child(map_lives_chip)
	var play := Button.new()
	play.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play.offset_left = -310
	play.offset_right = 310
	play.offset_top = -40 - 176
	play.offset_bottom = -40
	play.pressed.connect(_map_play)
	map_layer.add_child(play)
	var pv := VBoxContainer.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", -18)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(pv)
	pv.add_child(_label("Play", 80, Color("#2e1c00"), LOGO_FONT))
	map_play_sub = _label("Level 1", 34, Color("#6b4200"), UI_FONT_HEAVY)
	pv.add_child(map_play_sub)
	map_layer.hide()

func _show_map(from: String) -> void:
	_map_from = from
	var hard := Puzzle.is_hard(Save.level)
	map_play_sub.text = _level_text(Save.level)
	map_play_sub.add_theme_color_override("font_color", Color("#b3121f") if Puzzle.is_extreme(Save.level) else (Color("#a3165f") if hard else Color("#6b4200")))
	map_coin_chip.label = str(Save.coins)
	_refresh_lives()
	Art.region = Art.chapter_of(Save.level).theme
	map_layer.show()
	if not Save.seen.has("map"):
		get_tree().create_timer(3.4 if from == "win" else 0.5).timeout.connect(func():
			if map_layer.visible:
				_show_tip("map"))
	map_view.open()

func _map_play() -> void:
	Sound.play("select")
	map_layer.hide()
	_start_level()

# ---------- flow ----------

func _show_menu() -> void:
	if not menu_layer.visible and not won and moves > 0 and mode != "practice":
		Analytics.log_event("level_quit", {"level": Save.level, "mode": mode, "moves": moves, "hard": _hard_now()})
	_tut_stop()
	if out_layer:
		out_layer.hide()
	_round += 1   # leaving mid-celebration: progress is already saved, skip the card
	win_layer.hide()
	map_layer.hide()
	menu_layer.show()
	if hard_banner:
		hard_banner.hide()
	_prefetch_level(Save.level)
	_refresh()

func _start_level() -> void:
	if _needs_life(Save.level):
		map_layer.hide()
		_show_menu()
		_show_no_lives()
		return
	mode = "level"
	map_layer.hide()
	menu_layer.hide()
	win_layer.hide()
	move_limit = 0
	target = 0
	if _heart_lost_at != Save.level:
		_heart_lost_at = 0
	_hint_plan = {}
	# never wait for the background search: if it isn't finished, make the level now and work out
	# the move limit on a background thread (the pill shows "..." for a moment)
	if _prefetch_task != -1 and WorkerThreadPool.is_task_completed(_prefetch_task):
		WorkerThreadPool.wait_for_task_completion(_prefetch_task)
		_prefetch_task = -1
	_prefetch_mutex.lock()
	var made: Dictionary = _prefetch_state if _prefetch_state.get("level", -1) == Save.level else {}
	_prefetch_mutex.unlock()
	if _prefetch_task == -1 and _prefetch.get("level", -1) == Save.level:
		start_state = Puzzle.copy(_prefetch.state)
		if not _prefetch.path.is_empty():
			if Puzzle.is_hard(Save.level):
				move_limit = Puzzle.limit_for(_prefetch.path.size(), Save.level)
			else:
				target = _streak_target(_prefetch.path.size(), Save.level)
			_hint_plan = _plan_from(start_state, _prefetch.path)
	elif not made.is_empty():
		start_state = Puzzle.copy(made.state)   # the level is made; the limit is still being searched
	else:
		start_state = Puzzle.generate(Save.level)
	if move_limit == 0 and target == 0:
		_start_limit_task()
	_reset_extra()
	_load_state(Puzzle.copy(start_state), true)
	_maybe_tip()
	if target > 0 and not Save.seen.has("streak"):
		_show_tip("streak")
	Analytics.log_event("level_start", {"level": Save.level, "mode": mode, "hard": Puzzle.is_hard(Save.level), "extreme": Puzzle.is_extreme(Save.level)})
	if Puzzle.is_hard(Save.level):
		_show_hard_banner()

func _hard_now() -> bool:
	return mode == "level" and Puzzle.is_hard(Save.level) and not menu_layer.visible and not won

## "Hard level" banner that pops in, stays a moment and fades away.
func _show_hard_banner() -> void:
	if hard_banner == null:
		hard_banner = PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#b02a8e")
		sb.border_color = Color(1.0, 0.75, 0.9, 0.85)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(44)
		sb.shadow_color = Color(1.0, 0.24, 0.63, 0.5)
		sb.shadow_size = 40
		sb.content_margin_left = 60
		sb.content_margin_right = 60
		sb.content_margin_top = 24
		sb.content_margin_bottom = 22
		sb.anti_aliasing = true
		hard_banner.add_theme_stylebox_override("panel", sb)
		hard_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		_banner_title = _label("Hard level", 68, Color.WHITE, LOGO_FONT)
		v.add_child(_banner_title)
		_banner_sub = _label("Limited moves. Win for +1 hint", 28, Color(1, 1, 1, 0.9), UI_FONT_HEAVY)
		v.add_child(_banner_sub)
		_banner_sb = sb
		hard_banner.add_child(v)
		add_child(hard_banner)
	var ext := Puzzle.is_extreme(Save.level)
	_banner_title.text = Puzzle.tier_name(Save.level) + " level"   # an English key: the label translates it
	var prize := COIN_EXTREME if ext else COIN_HARD
	_banner_sub.text = I18n.t("{0} moves. Win for {1} coins + 1 hint", [move_limit, prize]) if move_limit > 0 else I18n.t("Limited moves. Win for {0} coins + 1 hint", [prize])
	# a long name ("Сложный уровень") gets a smaller size so the banner never reaches the screen edges
	_banner_title.add_theme_font_size_override("font_size", _fit_fs(tr(_banner_title.text), 68, 540, LOGO_FONT))
	_banner_sub.add_theme_font_size_override("font_size", _fit_fs(_banner_sub.text, 28, 540))
	_banner_sb.bg_color = Color("#c4261a") if ext else Color("#b02a8e")
	_banner_sb.border_color = Color(1.0, 0.8, 0.68, 0.9) if ext else Color(1.0, 0.75, 0.9, 0.85)
	_banner_sb.shadow_color = Color(1.0, 0.24, 0.12, 0.55) if ext else Color(1.0, 0.24, 0.63, 0.5)
	move_child(hard_banner, -1)
	hard_banner.reset_size()
	var sz := hard_banner.get_combined_minimum_size()
	hard_banner.size = sz
	hard_banner.position = Vector2((size.x - sz.x) * 0.5, size.y * 0.38 - sz.y * 0.5)
	hard_banner.pivot_offset = sz * 0.5
	hard_banner.show()
	hard_banner.modulate.a = 0.0
	hard_banner.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(hard_banner, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(hard_banner, "scale", Vector2(1.08, 1.08), 0.25)
	tw.tween_property(hard_banner, "scale", Vector2.ONE, 0.17)
	tw.tween_interval(1.25)
	tw.tween_property(hard_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(hard_banner.hide)
	get_tree().create_timer(0.25).timeout.connect(func(): Sound.play("unlock", 0.8))

func _start_daily() -> void:
	mode = "daily"
	move_limit = 0
	_hint_plan = {}
	daily_date = Save.today()
	menu_layer.hide()
	win_layer.hide()
	start_state = Puzzle.generate_daily(daily_date)
	_reset_extra()
	_load_state(Puzzle.copy(start_state), true)
	Analytics.log_event("level_start", {"level": Save.level, "mode": mode, "hard": false})
	_maybe_tip()
	if Save.daily_done == daily_date:
		_say("Already solved today. Play again for fun!")

func _restart() -> void:
	if won or board.win_time >= 0.0 or start_state.is_empty():
		return
	_confirm_leave("restart", func(): _load_state(Puzzle.copy(start_state), true))

func _load_state(new_state: Dictionary, fly_in: bool) -> void:
	# a mended jar stays mended if the level is restarted (a repair cut short counts as done: it was paid for)
	if board.extra_state == "repairing" or board.extra_state == "fixed":
		board.extra_state = "fixed"
		_extra_token += 1
		_add_jar(new_state)
	_used_hint = false
	state = new_state
	won = false
	moves_max = move_limit
	if out_layer:
		out_layer.hide()
	undos_left = UNDOS_PER_LEVEL
	_info_timer = 0.0
	toast.hide()
	_round += 1
	history.clear()
	moves = 0
	board.set_state(state, fly_in)
	if fly_in:
		Sound.play("whoosh", 1.0, -3.0)
	_tut_start()
	_refresh()

func _refresh() -> void:
	var ch := Art.chapter_of(Save.level)
	backdrop.theme_index = 4 if mode == "daily" else ch.theme
	Art.region = backdrop.theme_index if (mode == "daily" and not menu_layer.visible and not map_layer.visible) else ch.theme
	if mode == "daily":
		chapter_label.text = I18n.up(tr("Daily puzzle"))
		var d := Time.get_date_dict_from_system()
		level_label.text = I18n.date_text(int(d.month), int(d.day))
	else:
		chapter_label.text = I18n.up(tr(Puzzle.tier_name(Save.level) + " level")) if _hard_now() else I18n.up(str(ch.name))
		level_label.text = tr("Tutorial") if mode == "practice" else I18n.t("Level {0}", [Save.level])
	var hard := _hard_now()
	var ext := hard and Puzzle.is_extreme(Save.level)
	chapter_label.add_theme_color_override("font_color", Color("#ff6b5c") if ext else (Color("#ff8fc8") if hard else MUTED))
	level_label.add_theme_color_override("font_color", Color("#ffd9d2") if ext else (Color("#ffd6ec") if hard else Color("#fff3c4")))
	hard_tint.texture = _tint_extreme if ext else _tint_hard
	hard_tint.visible = hard
	var limited := mode == "level" and Puzzle.is_hard(Save.level) and not won and not menu_layer.visible
	var tgt := mode == "level" and not Puzzle.is_hard(Save.level) and target > 0 and not won and not menu_layer.visible
	moves_pill.visible = limited or tgt
	if tgt:
		moves_label.text = I18n.t("Target: {0} / {1}", [moves, target])
		var off := _used_hint or moves > target
		var tsb := StyleBoxFlat.new()
		tsb.set_corner_radius_all(22)
		tsb.set_border_width_all(2)
		tsb.content_margin_left = 22
		tsb.content_margin_right = 22
		tsb.content_margin_top = 4
		tsb.content_margin_bottom = 4
		tsb.anti_aliasing = true
		tsb.bg_color = Color(1, 1, 1, 0.06) if off else Color(0.24, 0.67, 1.0, 0.16)
		tsb.border_color = Color(1, 1, 1, 0.18) if off else Color(0.47, 0.78, 1.0, 0.55)
		moves_label.add_theme_color_override("font_color", Color(0.86, 0.9, 1.0, 0.55) if off else Color("#d9f6ff"))
		moves_pill.add_theme_stylebox_override("panel", tsb)
	if limited:
		var left := moves_max - moves
		moves_label.text = "..." if moves_max == 0 else (tr("1 move left") if left == 1 else I18n.t("{0} moves left", [left]))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(22)
		sb.set_border_width_all(2)
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		sb.anti_aliasing = true
		if moves_max > 0 and left <= 2:
			sb.bg_color = Color("#ff3b5c"); sb.border_color = Color("#ffb3c0")
			moves_label.add_theme_color_override("font_color", Color.WHITE)
		elif moves_max > 0 and left <= 5:
			sb.bg_color = Color("#ffc94a"); sb.border_color = Color("#ffe39a")
			moves_label.add_theme_color_override("font_color", Color("#3a2205"))
		else:
			sb.bg_color = Color(0.84, 0.2, 0.55, 0.35); sb.border_color = Color(1.0, 0.67, 0.84, 0.5)
			moves_label.add_theme_color_override("font_color", Color("#ffe3f1"))
		moves_pill.add_theme_stylebox_override("panel", sb)
	undo_btn.disabled = history.is_empty()
	undo_btn.badge = str(undos_left) if undos_left > 0 else "+"
	undo_btn.queue_redraw()
	hint_btn.badge = str(Save.hints) if Save.hints > 0 else "+"
	hint_chip.label = str(Save.hints)
	_refresh_side()
	coin_chip.label = str(Save.coins)
	level_coins.label = str(Save.coins)
	sound_btn.icon_name = "sound_on" if (Save.music_on or Save.sfx_on) else "sound_off"
	chapter_num.text = I18n.up(I18n.t("Chapter {0}", [ch.num]))
	chapter_name.text = ch.name
	chapter_count.text = "%d / 10" % ch.done
	chapter_bar.value = ch.done
	play_sub.text = _level_text(Save.level)
	play_sub.add_theme_color_override("font_color", Color("#b3121f") if Puzzle.is_extreme(Save.level) else (Color("#a3165f") if Puzzle.is_hard(Save.level) else Color("#6b4200")))
	var done_today := Save.daily_done == Save.today()
	var alive := Save.daily_done == Save.today() or Save.daily_done == Save.yesterday()
	daily_sub.text = I18n.t("Solved! Next puzzle in {0}", [_until_midnight()]) if done_today else tr("A new puzzle every day")
	daily_streak.text = str(Save.streak) if alive and Save.streak > 0 else ""
	daily_streak.get_parent().get_child(daily_streak.get_index() - 1).visible = daily_streak.text != ""
	# long translations ("Gelöst! Nächstes in 12 Std. 7 Min.") shrink to fit, so the flame and count stay inside the row
	var text_w := 528.0 - 84.0 - 24.0 * 3 - (96.0 if daily_streak.text != "" else 0.0)
	daily_title.add_theme_font_size_override("font_size", _fit_fs(tr(daily_title.text), 40, text_w))
	daily_sub.add_theme_font_size_override("font_size", _fit_fs(daily_sub.text, 26, text_w))
	daily_icon.queue_redraw()

func _until_midnight() -> String:
	var t := Time.get_time_dict_from_system()
	var mins: int = max(1, 24 * 60 - (int(t.hour) * 60 + int(t.minute)))
	return I18n.t("{0}h {1}m", [mins / 60, mins % 60]) if mins >= 60 else I18n.t("{0}m", [mins])

## "Level 5" or "Level 5 · Hard", in the player's language.
func _level_text(lv: int) -> String:
	if Puzzle.is_hard(lv):
		return I18n.t("Level {0} · {1}", [lv, tr(Puzzle.tier_name(lv))])
	return I18n.t("Level {0}", [lv])

func _say(text: String, sticky := false) -> void:
	toast.add_theme_stylebox_override("panel", _toast_gold if sticky else _toast_style)
	info_label.add_theme_color_override("font_color", Color("#2b2150") if sticky else INK)
	info_label.text = text
	toast.show()
	toast.modulate.a = 1.0
	_info_timer = 99999.0 if sticky else 2.8

# ---------- playing ----------

func _jars() -> Array:
	return state.jars

func _on_jar_tapped(i: int) -> void:
	if board.is_busy() or tip_layer.visible:
		return
	if not tut.is_empty() and i != _tut_target():
		board.tut_nudge = board.now()   # during the tutorial only the jar under the hand responds
		return
	if _out_of_moves():
		_show_out_of_moves()
		return
	_on_jar_tapped_inner(i)
	_tut_update()

func _on_jar_tapped_inner(i: int) -> void:
	board.hint_move = []
	var jars := _jars()
	if state.locks[i] > 0:
		_nope(i)
		_say(tr("This jar opens after 1 more pour") if state.locks[i] == 1 else I18n.t("This jar opens after {0} more pours", [state.locks[i]]))
		board.selected = -1
		return
	var sel: int = board.selected
	if sel == -1:
		if not jars[i].is_empty() and not Puzzle.is_jar_done(jars[i]):
			board.selected = i
			Sound.play("select", randf_range(0.95, 1.05))
			board.sparkle(board.jar_top_point(i), board.COLORS[jars[i][-1]], 8, 0.8)
		else:
			_nope(i)
		return
	if sel == i:
		board.selected = -1
		Sound.play("drop")
		return
	if Puzzle.can_pour(state, sel, i):
		_pour(sel, i)
	elif state.only[i] >= 0 and jars[i].size() < Puzzle.CAPACITY and (jars[i].is_empty() or jars[i][-1] == jars[sel][-1]):
		_nope(i)
		_say(I18n.t("That jar only takes {0} fireflies", [tr(COLOR_NAMES[state.only[i]])]))
		board.selected = -1
	elif not jars[i].is_empty() and not Puzzle.is_jar_done(jars[i]):
		board.selected = i
		Sound.play("select", 1.1)
	else:
		_nope(i)
		board.selected = -1

const COLOR_NAMES := ["yellow", "sky blue", "pink", "green", "violet", "orange", "blue", "white", "red", "mint"]

func _on_empty_tapped() -> void:
	if board.selected != -1 and not board.is_busy():
		board.selected = -1
		Sound.play("drop")
		_tut_update()

## Fireflies dragged with a finger and let go over jar j (-1 = in the air).
func _on_drag_dropped(from: int, j: int) -> void:
	if board.selected != from or won:
		return
	if j == -1 or j == from:
		board.selected = -1   # dropped in the air: they fly home
		Sound.play("drop")
		_tut_update()
		return
	if not tut.is_empty() and j != _tut_target():
		board.tut_nudge = board.now()
		return
	if Puzzle.can_pour(state, from, j) or state.only[j] >= 0 or state.locks[j] > 0:
		_on_jar_tapped(j)
		board.selected = -1
	else:
		_nope(j)   # full jar or wrong color: they fly home
		board.selected = -1
	_tut_update()

func _nope(i: int) -> void:
	board.shake(i)
	Sound.play("nope")
	Save.buzz(30)

func _pour(a: int, b: int) -> void:
	var snap := Puzzle.copy(state)
	var locks_before: Array = state.locks.duplicate()
	var n := Puzzle.pour(state, a, b)
	history.append({"snap": snap, "a": a, "b": b, "n": n})
	moves += 1
	board.selected = -1
	if moves_max > 0 and moves >= moves_max:
		var round_id := _round
		get_tree().create_timer((n - 1) * 0.08 + 0.65).timeout.connect(func():
			if round_id == _round and _out_of_moves():
				_show_out_of_moves())
	if not tut.is_empty():
		tut.pours += 1
		_tut_next()
	Sound.play("pour", randf_range(0.9, 1.1))
	Save.buzz(15)
	for i in state.locks.size():
		if locks_before[i] > 0 and state.locks[i] == 0:
			get_tree().create_timer(0.25).timeout.connect(func():
				board.pop_lid(i)
				Sound.play("unlock")
				_say("A lid popped open!"))
	board.move_flies(a, b, n, func(): _on_landed(b))
	_refresh()

func _on_landed(b: int) -> void:
	var jars := _jars()
	if jars[b].is_empty():
		return   # an undo already took these fireflies back
	board.sparkle(board.jar_top_point(b) + Vector2(0, 30), board.COLORS[jars[b][-1]], 6, 0.6)
	if Puzzle.is_jar_done(jars[b]) and not board.corks.has(b):
		board.pop_cork(b)
		Sound.play("jar_done", 1.0, -3.0)
	if Puzzle.is_solved(state):
		_on_win()

func _undo() -> void:
	if history.is_empty() or board.is_busy() or won:
		return
	if undos_left <= 0:
		_offer("undo")
		return
	undos_left -= 1
	moves = maxi(0, moves - 1)   # undo gives the move back
	var h: Dictionary = history.pop_back()
	state = h.snap
	board.replace_state(state)
	if board.corks.has(h.b) and not Puzzle.is_jar_done(state.jars[h.b]):
		board.remove_cork(h.b)
	board.selected = -1
	board.hint_move = []
	board.move_flies(h.b, h.a, h.n)
	if not tut.is_empty():
		tut.pours = maxi(0, tut.pours - 1)
		_tut_next()
	Sound.play("whoosh", 1.2, -4.0)
	_refresh()

func _on_hint_pressed() -> void:
	if board.is_busy():
		return
	if Save.hints > 0:
		_use_hint()
	else:
		_offer("hint")

func _on_reward(kind: String) -> void:
	if kind == "life":
		Analytics.log_event("reward_choice", {"item": "life", "via": "ad"})
		Save.add_life()
		_refresh_lives()
		_say("+1 heart")
	if kind in ["hint", "undo", "moves", "jar"]:
		Analytics.log_event("reward_choice", {"item": kind, "via": "ad"})
	if kind == "jar":
		_start_repair()
	if kind == "double":
		Analytics.log_event("reward_choice", {"item": "double_coins", "via": "ad"})
		var from := Save.coins
		_add_coins(_win_gain, "double_ad")
		double_btn.hide()
		win_gain_label.text = "+%d" % (_win_gain * 2)
		_count_coins(from, Save.coins, 0.15)
		_trophy_toasts()
	if kind == "undo":
		undos_left += 1
		_refresh()
		_undo()
	if kind == "moves":
		moves_max += 5
		_say("+5 moves")
		_refresh()
	if kind == "hint":
		Save.hints += 1
		Save.save_game()
		_use_hint()

func _use_hint() -> void:
	var path = _hint_path()
	if path.is_empty():
		_say("You're stuck. Try Undo or Restart")
		_refresh()
		return
	Save.hints -= 1
	Save.save_game()
	_used_hint = true
	board.selected = -1
	board.hint_move = path[0]
	Sound.play("hint")
	_say("Move the glowing fireflies into the gold jar")
	_refresh()

func _on_win() -> void:
	if won:
		return
	won = true
	# a happy double tap on the phone
	Save.buzz(40)
	get_tree().create_timer(0.18).timeout.connect(func(): Save.buzz(70))
	var round_id := _round
	var title := "All glowing!"
	var text := I18n.t("Solved in {0} moves", [moves])
	var sfx := "win"
	var gain := 0
	Analytics.log_event("level_end", {"level": Save.level, "mode": mode, "moves": moves, "success": true, "hard": mode == "level" and Puzzle.is_hard(Save.level), "used_hint": _used_hint})
	if mode == "daily":
		if Save.daily_done != daily_date:
			gain = COIN_DAILY
		Save.complete_daily(daily_date)
		title = "Daily solved!"
		text = I18n.t("Solved in {0} moves", [moves]) + "\n" + I18n.t("{0}-day streak, +1 hint", [Save.streak]) + "\n" + tr("Come back tomorrow for a new puzzle.")
		sfx = "daily"
		next_btn.text = "Back to levels"
	elif mode == "practice":
		title = "Well done!"
		text = tr("That's all there is to it.")
		_tut_stop()
		next_btn.text = "Back to menu"
	else:
		if not tut.is_empty() or Save.level == 1:
			Save.seen["tutorial"] = true
			_tut_stop()
		gain = COIN_LEVEL
		# skill streak: -1 = this level doesn't count (too early, or the target isn't known yet)
		var ok := -1   # -1 = doesn't count, 0 = missed, 1 = kept
		var why := ""
		if Puzzle.is_hard(Save.level) and move_limit > 0:
			ok = 1 if move_limit - moves >= STREAK_SPARE and _heart_lost_at != Save.level else 0
			why = "Streak lost: a heart was lost" if _heart_lost_at == Save.level else "Streak lost: win with 3 moves to spare"
		elif not Puzzle.is_hard(Save.level) and target > 0:
			ok = 1 if not _used_hint and moves <= target else 0
			why = "Streak lost: a hint was used" if _used_hint else "Streak lost: over the target moves"
		var streak_text := ""
		var bonus := 0
		if ok == 1:
			Save.skill += 1
			Save.stats.best_skill = maxi(int(Save.stats.get("best_skill", 0)), Save.skill)
			bonus = _streak_bonus(Save.skill)
			streak_text = "\n" + I18n.t("Skill streak: {0}", [Save.skill])
			if bonus > 0:
				streak_text += "\n" + I18n.t("Streak bonus: +{0} coins", [bonus])
		elif ok == 0 and Save.skill > 0:
			Save.skill = 0
			streak_text = "\n" + tr(why)
		Analytics.log_event("skill_streak", {"level": Save.level, "ok": ["na", "no", "yes"][ok + 1], "streak": Save.skill})
		if Puzzle.is_hard(Save.level):
			var ext := Puzzle.is_extreme(Save.level)
			title = "Extreme level beaten!" if ext else "Hard level beaten!"
			text += "\n" + tr("+1 hint")
			gain = COIN_EXTREME if ext else COIN_HARD
			if not _used_hint:
				Save.stats.pure = int(Save.stats.get("pure", 0)) + 1
		if not Save.seen.has("tutorial_done"):
			Save.seen["tutorial_done"] = true
			Analytics.log_event("tutorial_complete", {})
		gain += bonus
		text += streak_text
		Save.complete_level()
		next_btn.text = "Next level"
		_prefetch_level(Save.level)
	_win_gain = gain
	if gain > 0:
		_add_coins(gain, "daily" if mode == "daily" else "level")
	Services.submit_scores()
	# wait for the last lid to screw on and click before celebrating
	board.hold(board.CAP_TOTAL + 2.0)
	await get_tree().create_timer(board.CAP_TOTAL + 0.25).timeout
	if round_id != _round:
		return
	board.celebrate()
	Sound.play(sfx)
	await get_tree().create_timer(1.6).timeout
	if round_id != _round:
		return
	win_title.text = title
	win_label.text = text
	win_layer.show()
	_refresh()
	_show_win_coins(_win_gain)
	_trophy_toasts()
	if _win_gain > 0 and not Save.seen.has("coins"):
		await get_tree().create_timer(0.3).timeout
		if round_id == _round and win_layer.visible:
			_show_tip("coins")

# ---------- first-level tutorial ----------

func _tut_start() -> void:
	_tut_stop()
	if mode != "practice" and (mode != "level" or Save.level != 1 or Save.seen.has("tutorial")):
		return
	tut = {"step": [], "pours": 0}
	_tut_next()

func _tut_stop() -> void:
	if tut.is_empty():
		return
	tut = {}
	board.tut_jar = -1
	board.tut_drag_from = -1
	board.tut_drag_to = -1
	_info_timer = 0.0
	toast.hide()

func _tut_next() -> void:
	var path = Puzzle.solve(state) if tut.pours < TUT_GUIDED else null
	if path == null or path.is_empty():
		_tut_stop()
		if not Puzzle.is_solved(state):
			_say("Now finish it yourself: one color in each jar!")
		return
	tut.step = path[0]
	tut.key = Puzzle._key(state)
	_tut_update()

func _tut_target() -> int:
	if not tut.is_empty() and tut.get("key", "") != Puzzle._key(state):
		_tut_next()   # the hand always follows the board as it is now, whatever changed it
	if tut.is_empty() or tut.step.is_empty():
		return -1
	return tut.step[1] if board.selected == tut.step[0] else tut.step[0]

func _tut_update() -> void:
	if tut.is_empty() or tut.step.is_empty():
		return
	board.tut_jar = _tut_target()
	board.tut_drag_from = tut.step[0] if tut.pours > 0 else -1
	board.tut_drag_to = tut.step[1] if tut.pours > 0 else -1
	var msg := "Tap this jar to pick up the top fireflies"
	if board.selected == tut.step[0] and tut.pours > 0:
		msg = "Drag them to the glowing jar, or tap it"
	elif board.selected == tut.step[0]:
		msg = "Now tap this jar to pour them in"
	elif tut.pours > 0:
		msg = "Now try dragging: hold this jar and slide to the glowing one"
	if info_label.text != msg or not toast.visible:
		_say(msg, true)

# ---------- move limit on Hard levels ----------

## Normal levels: the fewest possible pours plus a little room (25%, at least 3). 0 = no target.
static func _streak_target(best: int, lv: int) -> int:
	if Puzzle.is_hard(lv) or lv < STREAK_FROM or best <= 0:
		return 0
	return best + maxi(3, ceili(best * 0.25))

static func _streak_bonus(n: int) -> int:
	if STREAK_BONUS.has(n):
		return STREAK_BONUS[n]
	return 60 if n > 10 and n % 5 == 0 else 0

func _start_limit_task() -> void:
	if not Puzzle.is_hard(Save.level) and Save.level < STREAK_FROM:
		return
	if _limit_task != -1:
		WorkerThreadPool.wait_for_task_completion(_limit_task)
	var lv := Save.level
	var s := Puzzle.copy(start_state)
	_limit_result = []
	_limit_task = WorkerThreadPool.add_task(func():
		var p = Puzzle.shortest_path(s)
		if p == null:
			p = Puzzle.solve(s)
		var n: int = p.size() if p != null else 60
		_limit_result = [lv, Puzzle.limit_for(n, lv) if Puzzle.is_hard(lv) else _streak_target(n if p != null else 0, lv), p if p != null else []])

func _out_of_moves() -> bool:
	return moves_max > 0 and moves >= moves_max and not won and not Puzzle.is_solved(state)

func _show_out_of_moves() -> void:
	if out_layer == null:
		out_layer = _overlay()
		var box := _card(out_layer, 620)
		box.add_child(_label("Out of moves", 60, GOLD, LOGO_FONT))
		var txt := _label("So close! Watch a short video for 5 more moves, or try the level again.", 32, INK)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(520, 0)
		box.add_child(txt)
		var more := Button.new()
		more.text = "+5 moves (video)"
		more.custom_minimum_size = Vector2(0, 110)
		more.add_theme_font_size_override("font_size", 42)
		more.pressed.connect(func():
			out_layer.hide()
			if Ads.is_rewarded_ready():
				Ads.show_rewarded("moves")
			else:
				_say("No video available right now")
				_show_out_of_moves.call_deferred())
		box.add_child(more)
		moves_coin_btn = _coin_btn("")
		moves_coin_btn.pressed.connect(func():
			if not _spend_coins(PRICE.moves, "moves"):
				return
			out_layer.hide()
			Sound.play("coin")
			Analytics.log_event("reward_choice", {"item": "moves", "via": "coins"})
			moves_max += 5
			_say("+5 moves")
			_refresh())
		box.add_child(moves_coin_btn)
		var retry := Button.new()
		retry.text = "Try again (−1 heart)"
		retry.custom_minimum_size = Vector2(0, 90)
		retry.add_theme_font_size_override("font_size", 34)
		for st in ["normal", "hover", "pressed", "focus"]:
			retry.add_theme_stylebox_override(st, _glass(30, 0.5))
		retry.add_theme_color_override("font_color", Color.WHITE)
		retry.pressed.connect(func():
			out_layer.hide()
			_lose_life("fail")
			if Save.lives_now() <= 0:
				_show_menu()
				_show_no_lives()
				return
			_load_state(Puzzle.copy(start_state), true))
		box.add_child(retry)
	_set_coin_btn(moves_coin_btn, PRICE.moves, "+5 moves for {0}")
	if not out_layer.visible:
		Sound.play("nope")
		out_layer.show()
		Analytics.log_event("level_fail", {"level": Save.level, "mode": mode, "moves": moves})

# ---------- settings ----------

const PRIVACY_TEXT := """Jar World is a puzzle game. This policy explains what data the game uses. Last updated: November 2026.

DATA KEPT ON YOUR DEVICE
Your progress (level, hints, coins, trophies, daily streak) and settings are saved only on your phone. We don't have accounts and we don't collect your name, email, contacts, photos or location.

ADS
The free game shows ads from Google AdMob. To show and measure ads, Google may collect your device's advertising ID, IP address, rough location from that IP, and how you interact with ads. Depending on your choice in the consent message, ads may be personalized or not. You can reset or limit your advertising ID in your phone's settings. See how Google uses data: policies.google.com/technologies/partner-sites.

GAME STATISTICS (FIREBASE ANALYTICS)
The game uses Google Firebase Analytics to count things like which levels are played, where players stop, and whether coins or videos are used. This helps us make the game better. It uses an app-instance ID, not your name, and Google handles it under its own privacy policy (policies.google.com/privacy).

PURCHASES
The "Remove ads" purchase is handled by the App Store or Google Play. We never see your payment details.

GAME CENTER AND GOOGLE PLAY GAMES
If you sign in to Apple Game Center or Google Play Games, your scores, achievements and saved progress are stored by Apple or Google under their own privacy policies.

CHILDREN
The game is not directed at children under 13, and we don't knowingly collect their personal data.

CONTACT
Questions? Write to fireflyjars.support@gmail.com."""

func _switch_row(box: VBoxContainer, title: String, sub: String, on: bool, changed: Callable) -> Button:
	var row := HBoxContainer.new()
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_label(title, 36, INK, UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT))
	if sub != "":
		col.add_child(_label(sub, 24, MUTED, UI_FONT, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(col)
	# an ON / OFF pill: gold when on, glass when off
	var sw := Button.new()
	sw.toggle_mode = true
	sw.custom_minimum_size = Vector2(130, 64)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.add_theme_font_size_override("font_size", 28)
	var on_sb := _gold(true)
	on_sb.content_margin_top = 4
	on_sb.content_margin_bottom = 4
	var off_sb := _glass(32, 0.5)
	for st in ["normal", "hover", "focus"]:
		sw.add_theme_stylebox_override(st, off_sb)
	for st in ["pressed", "hover_pressed"]:
		sw.add_theme_stylebox_override(st, on_sb)
	sw.add_theme_color_override("font_color", MUTED)
	sw.add_theme_color_override("font_hover_color", MUTED)
	sw.add_theme_color_override("font_focus_color", MUTED)
	sw.add_theme_color_override("font_pressed_color", Color("#3a2205"))
	sw.add_theme_color_override("font_hover_pressed_color", Color("#3a2205"))
	sw.toggled.connect(func(v: bool): sw.text = "ON" if v else "OFF")
	sw.toggled.connect(changed)
	sw.set_pressed_no_signal(on)
	sw.text = "ON" if on else "OFF"
	row.add_child(sw)
	box.add_child(row)
	return sw

func _ghost_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", 36)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, _glass(30, 0.5))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(cb)
	return b

func _show_settings() -> void:
	Sound.play("select")
	if settings_layer == null:
		settings_layer = _overlay()
		var box := _card(settings_layer, 640)
		box.add_theme_constant_override("separation", 18)
		box.add_child(_label("Settings", 64, GOLD, LOGO_FONT))
		_switches.music = _switch_row(box, "Music", "", Save.music_on, func(on: bool):
			Save.music_on = on
			Save.save_game()
			Sound.apply_settings())
		_switches.sfx = _switch_row(box, "Sounds", "", Save.sfx_on, func(on: bool):
			Save.sfx_on = on
			Save.save_game()
			Sound.play("select"))
		_switches.vibrate = _switch_row(box, "Vibration", "", Save.vibrate_on, func(on: bool):
			Save.vibrate_on = on
			Save.save_game()
			Save.buzz(20))
		_switches.cb = _switch_row(box, "Color-blind mode", "A shape on every firefly color", Save.color_blind, func(on: bool):
			Save.color_blind = on
			Save.save_game())
		var lrow := HBoxContainer.new()
		lrow.add_theme_constant_override("separation", 16)
		var ltitle := _label("Language", 36, INK, UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT)
		ltitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lrow.add_child(ltitle)
		lang_btn = _ghost_btn("", _show_languages)
		lang_btn.custom_minimum_size = Vector2(200, 72)
		lang_btn.add_theme_font_size_override("font_size", 30)
		lrow.add_child(lang_btn)
		box.add_child(lrow)
		var shop := HBoxContainer.new()
		shop.add_theme_constant_override("separation", 16)
		remove_ads_btn = _ghost_btn(I18n.t("Remove ads · {0}", [Store.price_text]), func():
			Sound.play("select")
			Store.buy_remove_ads())
		var restore := _ghost_btn("Restore purchases", func():
			Sound.play("select")
			Store.restore())
		for b in [remove_ads_btn, restore]:
			b.add_theme_font_size_override("font_size", 26)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 88)
			var slim := _glass(30, 0.5)
			slim.content_margin_left = 12
			slim.content_margin_right = 12
			slim.content_margin_top = 8
			slim.content_margin_bottom = 8
			for st in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(st, slim)
			shop.add_child(b)
		box.add_child(shop)
		var tut_btn := _ghost_btn("Show tutorial again", func():
			settings_layer.hide()
			_start_practice())
		var priv_btn := _ghost_btn("Privacy policy", _show_privacy)
		# Europe and the UK: players can change their ads choice at any time
		privacy_choices_btn = _ghost_btn("Privacy choices", func():
			Sound.play("select")
			Ads.show_privacy_options())
		for b in [tut_btn, priv_btn, privacy_choices_btn]:
			b.custom_minimum_size = Vector2(0, 84)
			b.add_theme_font_size_override("font_size", 32)
			box.add_child(b)
		var done := Button.new()
		done.text = "Done"
		done.custom_minimum_size = Vector2(0, 110)
		done.add_theme_font_size_override("font_size", 42)
		done.pressed.connect(func():
			Sound.play("select")
			settings_layer.hide()
			_refresh())
		box.add_child(done)
	for k in _switches:
		var v: bool = {"music": Save.music_on, "sfx": Save.sfx_on, "vibrate": Save.vibrate_on, "cb": Save.color_blind}[k]
		_switches[k].set_pressed_no_signal(v)
		_switches[k].text = "ON" if v else "OFF"
	_refresh_store()
	_refresh_lang_btn()
	privacy_choices_btn.visible = Ads.privacy_options_required()
	move_child(settings_layer, -1)
	settings_layer.show()

# ---------- language ----------

func _refresh_lang_btn() -> void:
	if lang_btn:
		lang_btn.text = I18n.native_name(I18n.lang)

func _show_languages() -> void:
	Sound.play("select")
	if lang_layer == null:
		lang_layer = _overlay()
		var box := _card(lang_layer, 640)
		box.add_child(_label("Language", 64, GOLD, LOGO_FONT))
		_lang_grid = GridContainer.new()
		_lang_grid.columns = 2
		_lang_grid.add_theme_constant_override("h_separation", 16)
		_lang_grid.add_theme_constant_override("v_separation", 14)
		for code in [""] + I18n.languages():
			var b := _ghost_btn("Automatic" if code == "" else I18n.native_name(code), _pick_language.bind(code))
			b.custom_minimum_size = Vector2(0, 84)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 32)
			b.set_meta("code", code)
			_lang_grid.add_child(b)
		box.add_child(_lang_grid)
		var close := Button.new()
		close.text = "Close"
		close.custom_minimum_size = Vector2(0, 100)
		close.add_theme_font_size_override("font_size", 40)
		close.pressed.connect(func():
			Sound.play("select")
			lang_layer.hide())
		box.add_child(close)
	_mark_language()
	move_child(lang_layer, -1)
	lang_layer.show()

## The chosen language's button is gold.
func _mark_language() -> void:
	for b in _lang_grid.get_children():
		var on: bool = b.get_meta("code") == Save.language
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, _gold(true) if on else _glass(30, 0.5))
		b.add_theme_color_override("font_color", Color("#3a2205") if on else Color.WHITE)

func _pick_language(code: String) -> void:
	Sound.play("select")
	Save.language = code
	Save.save_game()
	I18n.apply(code)
	_mark_language()
	lang_layer.hide()

## Labels with an English key change by themselves; text with numbers in it is filled in again here.
func _on_language_changed() -> void:
	_refresh()
	_refresh_store()
	_refresh_side()
	_refresh_lives()
	_refresh_lang_btn()
	_redraw_all(self)

func _redraw_all(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for c in n.get_children():
		_redraw_all(c)

func _show_privacy() -> void:
	if privacy_layer == null:
		privacy_layer = _overlay()
		var box := _card(privacy_layer, 660)
		box.add_child(_label("Privacy policy", 54, GOLD, LOGO_FONT))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(580, 760)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var txt := _label(PRIVACY_TEXT, 26, INK, UI_FONT, HORIZONTAL_ALIGNMENT_LEFT)
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.custom_minimum_size = Vector2(560, 0)
		scroll.add_child(txt)
		box.add_child(scroll)
		var close := Button.new()
		close.text = "Close"
		close.custom_minimum_size = Vector2(0, 100)
		close.add_theme_font_size_override("font_size", 40)
		close.pressed.connect(func(): privacy_layer.hide())
		box.add_child(close)
	move_child(privacy_layer, -1)
	privacy_layer.show()

## Replay the tutorial on the first level without touching saved progress.
func _start_practice() -> void:
	mode = "practice"
	move_limit = 0
	_hint_plan = {}
	menu_layer.hide()
	win_layer.hide()
	start_state = Puzzle.generate(1)
	_reset_extra()
	_load_state(Puzzle.copy(start_state), true)
	Analytics.log_event("tutorial_begin", {"replay": true})

# ---------- hints ----------
# A hint follows one planned route to the end, so pressing Hint again and again always finishes the level.
# The route is only searched again when the player leaves it. Searching is the slow part, so this also avoids lag.

func _plan_from(s: Dictionary, path: Array) -> Dictionary:
	var keys := []
	var t := Puzzle.copy(s)
	for m in path:
		keys.append(Puzzle._key(t))
		Puzzle.pour(t, m[0], m[1])
	return {"keys": keys, "moves": path}

func _hint_path() -> Array:
	if not _hint_plan.is_empty():
		var i: int = _hint_plan.keys.find(Puzzle._key(state))
		if i >= 0:
			return _hint_plan.moves.slice(i)
	# a hint always comes from a real route to the finish: the shortest one, else a quick near-shortest one
	var p = Puzzle.shortest_path(state, 8000)
	if p == null:
		p = Puzzle.shortest_path(state, 20000, 3)
	if p == null:
		p = Puzzle.solve(state)
	if p == null or p.is_empty():
		return []
	_hint_plan = _plan_from(state, p)
	return p

func _prefetch_level(lv: int) -> void:
	if _prefetch_task != -1:
		if not WorkerThreadPool.is_task_completed(_prefetch_task):
			return
		WorkerThreadPool.wait_for_task_completion(_prefetch_task)
		_prefetch_task = -1
	if _prefetch.get("level", -1) == lv:
		return
	_prefetch = {}
	_prefetch_task = WorkerThreadPool.add_task(func():
		var s := Puzzle.generate(lv)
		_prefetch_mutex.lock()
		_prefetch_state = {"level": lv, "state": s}   # the level itself is ready; its move limit may follow later
		_prefetch_mutex.unlock()
		var p = []
		if Puzzle.is_hard(lv) or lv >= STREAK_FROM:
			p = Puzzle.shortest_path(s)
			if p == null:
				p = Puzzle.solve(s)
			if p == null:
				p = []
		_prefetch = {"level": lv, "state": s, "path": p})

# ---------- coins ----------

func _coin_icon(sz: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz, sz)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): Art.icon(c, "coin", c.size * 0.5, c.size.y, Color.WHITE))
	return c

## A button with a gold outline, for paying with coins.
func _coin_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 96)
	b.add_theme_font_size_override("font_size", 34)
	var sb := _glass(30, 0.5)
	sb.bg_color = Color(1.0, 0.78, 0.24, 0.14)
	sb.border_color = Color(1.0, 0.78, 0.24, 0.75)
	var off := _glass(30, 0.3)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_color_override("font_color", Color("#ffe8a3"))
	b.add_theme_color_override("font_pressed_color", Color("#ffe8a3"))
	b.add_theme_color_override("font_hover_color", Color("#ffe8a3"))
	b.add_theme_color_override("font_disabled_color", MUTED)
	return b

func _set_coin_btn(b: Button, price: int, verb: String) -> void:
	var ok := Save.coins >= price
	b.disabled = not ok
	var cost := I18n.t("{0} coins", [price])
	b.text = I18n.t(verb, [cost]) if ok else I18n.t("{0} needed · you have {1}", [cost, Save.coins])

func _add_coins(n: int, source: String) -> void:
	Save.coins += n
	Save.stats.earned = int(Save.stats.get("earned", 0)) + n
	Save.save_game()
	Analytics.log_event("earn_virtual_currency", {"virtual_currency_name": "coins", "value": n, "source": source})
	_refresh()

func _spend_coins(n: int, item: String) -> bool:
	if Save.coins < n:
		return false
	Save.coins -= n
	Save.save_game()
	Analytics.log_event("spend_virtual_currency", {"virtual_currency_name": "coins", "value": n, "item_name": item})
	_refresh()
	return true

## Win card: "+10" pops in, little coins fly to the total, and the total counts up.
func _show_win_coins(gain: int) -> void:
	win_coins_row.visible = gain > 0
	double_btn.visible = gain > 0
	if gain <= 0:
		return
	win_gain_label.text = "+%d" % gain
	double_btn.disabled = false
	double_btn.text = I18n.t("Watch a video: +{0} more coins", [gain])
	var g: Control = win_coins_row.get_node("Gain")
	g.pivot_offset = g.size * 0.5
	g.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(g, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_count_coins(Save.coins - gain, Save.coins, 0.45)

func _count_coins(from: int, to: int, delay: float) -> void:
	win_total_label.text = str(from)
	var round_id := _round
	await get_tree().create_timer(delay).timeout
	if round_id != _round or not win_layer.visible:
		win_total_label.text = str(to)
		return
	var g: Control = win_coins_row.get_node("Gain")
	var t: Control = win_coins_row.get_node("Total")
	var n: int = mini(8, 3 + (to - from) / 8)
	for k in n:
		var c := _coin_icon(44)
		c.top_level = true
		win_layer.add_child(c)
		var a := g.global_position + Vector2(g.size.x * randf_range(0.2, 0.5), g.size.y * 0.5) - Vector2(22, 22)
		var b := t.global_position + Vector2(20, t.size.y * 0.5) - Vector2(22, 22)
		c.global_position = a
		c.pivot_offset = Vector2(22, 22)
		var tw := create_tween()
		tw.tween_interval(0.03 + k * 0.075)
		tw.tween_property(c, "global_position", b, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(c, "rotation", randf_range(3.0, 7.0), 0.65)
		tw.tween_callback(func(): Sound.play("coin", 1.0 + k * 0.06, -5.0))
		tw.tween_property(c, "modulate:a", 0.0, 0.15)
		tw.tween_callback(c.queue_free)
	var count := create_tween()
	count.tween_interval(0.38)
	count.tween_method(func(v: float): win_total_label.text = str(int(round(v))), float(from), float(to), 0.65)

func _reward_or_say(kind: String) -> void:
	if Ads.is_rewarded_ready():
		Ads.show_rewarded(kind)
	else:
		_say("No video available right now. Try again soon")
		Ads.reload_rewarded()
		if kind == "double":
			double_btn.disabled = false

# ---------- "free video or coins" card ----------

const OFFERS := {
	"hint": ["Need a hint?", "You're out of hints. Watch a short video for a free one, or use your coins.", "Use {0}"],
	"undo": ["One more undo?", "You've used this level's 3 undos. Watch a short video for one more, or use your coins.", "Use {0}"],
	"jar": ["Mend the jar?", "Two helper fireflies will repair the cracked jar, so you get one more empty jar for this level.", "Mend for {0}"],
}

func _build_offer() -> void:
	offer_layer = _overlay()
	var box := _card(offer_layer, 620)
	offer_title = _label("", 60, GOLD, LOGO_FONT)
	box.add_child(offer_title)
	offer_text = _label("", 32, INK)
	offer_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offer_text.custom_minimum_size = Vector2(520, 0)
	box.add_child(offer_text)
	offer_ad_btn = Button.new()
	offer_ad_btn.text = "Free video"
	offer_ad_btn.custom_minimum_size = Vector2(0, 110)
	offer_ad_btn.add_theme_font_size_override("font_size", 42)
	offer_ad_btn.pressed.connect(func():
		offer_layer.hide()
		_reward_or_say(_offer_kind))
	box.add_child(offer_ad_btn)
	offer_coin_btn = _coin_btn("")
	offer_coin_btn.pressed.connect(func():
		var kind := _offer_kind
		if not _spend_coins(PRICE[kind], kind):
			return
		offer_layer.hide()
		Sound.play("coin")
		Analytics.log_event("reward_choice", {"item": kind, "via": "coins"})
		_grant_offer(kind))
	box.add_child(offer_coin_btn)
	box.add_child(_ghost_btn("Not now", func():
		Sound.play("drop")
		offer_layer.hide()))
	offer_layer.hide()

func _grant_offer(kind: String) -> void:
	if kind == "hint":
		Save.hints += 1
		Save.save_game()
		_use_hint()
	elif kind == "undo":
		undos_left += 1
		_refresh()
		_undo()
	elif kind == "jar":
		_start_repair()

func _offer(kind: String) -> void:
	_offer_kind = kind
	Sound.play("select")
	offer_title.text = OFFERS[kind][0]
	offer_text.text = OFFERS[kind][1]
	_set_coin_btn(offer_coin_btn, PRICE[kind], OFFERS[kind][2])
	move_child(offer_layer, -1)
	offer_layer.show()

# ---------- the cracked jar ----------
# From level 3 (and in the daily puzzle) a cracked jar stands on the shelf. A video, or coins, sends two
# helper fireflies to mend it; then it is one more empty jar for this level only.

func _reset_extra() -> void:
	_extra_token += 1
	board.extra_state = "cracked" if (mode == "level" and Save.level >= CRACK_FROM) or mode == "daily" else ""

func _add_jar(s: Dictionary) -> void:
	s.jars.append([])
	s.only.append(-1)
	s.locks.append(0)

func _on_extra_tapped() -> void:
	if board.extra_state != "cracked" or won or not tut.is_empty() or board.is_busy():
		return
	board.selected = -1
	_offer("jar")

func _start_repair() -> void:
	if board.extra_state != "cracked" or won:
		return
	board.start_repair()
	_extra_token += 1
	var tok := _extra_token
	get_tree().create_timer(board.FLY_IN - 0.1).timeout.connect(func():
		if tok == _extra_token:
			Sound.play("repair", 1.0, -2.0))
	get_tree().create_timer(board.FLY_IN + board.MEND).timeout.connect(func(): _finish_repair(tok))

func _finish_repair(tok: int) -> void:
	if tok != _extra_token or board.extra_state != "repairing":
		return
	_add_jar(state)
	for h in history:
		_add_jar(h.snap)
	_hint_plan = {}
	board.hint_move = []
	board.repair_done()
	Save.stats.repairs = int(Save.stats.get("repairs", 0)) + 1
	Save.save_game()
	Sound.play("jar_done", 1.25, -4.0)
	Save.buzz(15)
	_say("The jar is mended!")
	_trophy_toasts()
	_refresh()

# ---------- Remove ads (pretend store when the store plugin isn't in the build) ----------

func _refresh_store() -> void:
	if remove_ads_btn:
		remove_ads_btn.text = tr("Ads removed ✓") if Save.ads_removed else I18n.t("Remove ads · {0}", [Store.price_text])
		remove_ads_btn.disabled = Save.ads_removed

var _test_title: Label
var _test_text: Label
var _test_buy: Button

func _show_test_store(product: String) -> void:
	if store_layer == null:
		store_layer = _overlay()
		var box := _card(store_layer, 620)
		box.add_child(_label("TEST STORE", 24, Color("#3a2400"), _spaced(UI_FONT_HEAVY, 4)))
		box.get_child(0).add_theme_color_override("font_color", GOLD)
		_test_title = _label("", 60, GOLD, LOGO_FONT)
		box.add_child(_test_title)
		_test_text = _label("", 28, INK)
		_test_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_test_text.custom_minimum_size = Vector2(520, 0)
		box.add_child(_test_text)
		_test_buy = Button.new()
		_test_buy.custom_minimum_size = Vector2(0, 110)
		_test_buy.add_theme_font_size_override("font_size", 42)
		_test_buy.pressed.connect(func():
			store_layer.hide()
			Sound.play("jar_done")
			Store.confirm_test_purchase())
		box.add_child(_test_buy)
		box.add_child(_ghost_btn("Cancel", func():
			Sound.play("drop")
			store_layer.hide()))
	var note := tr("In the real game, the App Store or Google Play asks you to confirm. No money is charged in this test version.")
	if product == Store.PRODUCT_ID:
		_test_title.text = tr("Remove ads")
		_test_text.text = tr("No more ads between levels, forever. Videos you choose to watch for rewards stay available.") + "\n\n" + note
		_test_buy.text = I18n.t("Buy for {0}", [Store.price_text])
	else:
		for pk in Store.COIN_PACKS:
			if pk[0] == product:
				_test_title.text = I18n.t("{0} coins", [pk[1]])
				_test_text.text = note
		_test_buy.text = I18n.t("Buy for {0}", [Store.pack_price(product)])
	move_child(store_layer, -1)
	store_layer.show()

# ---------- trophies ----------

func _trophy_toasts() -> void:
	for name in Services.check_trophies():
		_top_toast("Trophy unlocked", name, true)

func _build_top_toast() -> void:
	top_toast = PanelContainer.new()
	var sb := _glass(50, 0.95)
	sb.bg_color = Color("#1b2353")
	sb.border_color = Color(1.0, 0.82, 0.31, 0.8)
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.content_margin_left = 20
	sb.content_margin_right = 36
	top_toast.add_theme_stylebox_override("panel", sb)
	top_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(64, 64)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.draw.connect(func():
		badge.draw_circle(badge.size * 0.5, 32, Color("#ffc23d"))
		Art.icon(badge, "trophy", badge.size * 0.5, 46, Color("#3a2205")))
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	top_toast_kind = _label("", 20, GOLD, _spaced(UI_FONT_HEAVY, 4), HORIZONTAL_ALIGNMENT_LEFT)
	top_toast_text = _label("", 32, Color("#fff3c4"), UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(top_toast_kind)
	v.add_child(top_toast_text)
	h.add_child(v)
	top_toast.add_child(h)
	add_child(top_toast)
	top_toast.hide()

func _top_toast(kind: String, text: String, trophy: bool) -> void:
	_toast_queue.append([kind, text, trophy])
	if not _toast_busy:
		_next_top_toast()

func _next_top_toast() -> void:
	if _toast_queue.is_empty():
		_toast_busy = false
		top_toast.hide()
		return
	_toast_busy = true
	var t: Array = _toast_queue.pop_front()
	top_toast_kind.text = I18n.up(tr(str(t[0])))
	top_toast_text.text = t[1]
	if t[2]:
		Sound.play("hint", 1.1)
	move_child(top_toast, -1)
	top_toast.show()
	top_toast.reset_size()
	var sz := top_toast.get_combined_minimum_size()
	top_toast.size = sz
	var x := (size.x - sz.x) * 0.5
	top_toast.position = Vector2(x, -sz.y - 10)
	var tw := create_tween()
	tw.tween_property(top_toast, "position:y", 30.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.3)
	tw.tween_property(top_toast, "position:y", -sz.y - 10, 0.35)
	tw.tween_callback(_next_top_toast)

func _show_trophies() -> void:
	Sound.play("select")
	if trophies_layer == null:
		trophies_layer = _overlay()
		var box := _card(trophies_layer, 640)
		box.add_child(_label("Trophies", 64, GOLD, LOGO_FONT))
		trophy_count = _label("", 28, MUTED)
		box.add_child(trophy_count)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(552, 640)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		trophy_list = VBoxContainer.new()
		trophy_list.add_theme_constant_override("separation", 14)
		trophy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(trophy_list)
		box.add_child(scroll)
		var note := _label("Trophies and leaderboards also show in Game Center (iPhone) or Google Play Games (Android) when you're signed in, and your progress is backed up there.", 22, MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(540, 0)
		box.add_child(note)
		boards_btn = _ghost_btn("Leaderboards", func(): Services.show_leaderboards())
		box.add_child(boards_btn)
		var done := Button.new()
		done.text = "Done"
		done.custom_minimum_size = Vector2(0, 110)
		done.add_theme_font_size_override("font_size", 42)
		done.pressed.connect(func():
			Sound.play("select")
			trophies_layer.hide())
		box.add_child(done)
	for c in trophy_list.get_children():
		c.queue_free()
	var got := 0
	for t in Services.TROPHIES:
		var have := Save.ach.has(t[0])
		got += 1 if have else 0
		var row := PanelContainer.new()
		var rs := _glass(28, 0.35)
		rs.content_margin_top = 12
		rs.content_margin_bottom = 12
		rs.content_margin_left = 18
		rs.content_margin_right = 18
		row.add_theme_stylebox_override("panel", rs)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 20)
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(72, 72)
		badge.draw.connect(func():
			if have:
				Art.glow(badge, badge.size * 0.5, 50, Color("#ffc23d"), 0.4)
			badge.draw_circle(badge.size * 0.5, 34, Color("#ffc23d") if have else Color(1, 1, 1, 0.08))
			Art.icon(badge, "trophy", badge.size * 0.5, 48, Color("#3a2205") if have else MUTED))
		h.add_child(badge)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -6)
		v.add_child(_label(t[1], 32, INK if have else MUTED, UI_FONT_HEAVY, HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(_label(t[2], 24, MUTED, UI_FONT, HORIZONTAL_ALIGNMENT_LEFT))
		h.add_child(v)
		row.add_child(h)
		trophy_list.add_child(row)
	trophy_count.text = I18n.t("{0} of {1} unlocked", [got, Services.TROPHIES.size()])
	boards_btn.visible = Services.can_show_boards()
	move_child(trophies_layer, -1)
	trophies_layer.show()

## Let background puzzle searches finish before the game closes, so nothing is freed while a thread uses it.
func _exit_tree() -> void:
	for t in [_limit_task, _prefetch_task]:
		if t != -1:
			WorkerThreadPool.wait_for_task_completion(t)
	_limit_task = -1
	_prefetch_task = -1


# ---------- skins shop: new looks for the jars and the fireflies, paid with coins ----------

func _skin_list() -> Array:
	return Art.SKINS[skins_tab]

func _skin_owned(kind: String, id: String) -> bool:
	return id == "classic" or Save.skins.has(kind + "_" + id)

func _skin_in_use(kind: String, id: String) -> bool:
	return (Save.jar_skin if kind == "jar" else Save.fly_skin) == id

func _show_skins() -> void:
	Sound.play("select")
	if skins_layer == null:
		skins_layer = _overlay()
		var box := _card(skins_layer, 660)
		box.add_theme_constant_override("separation", 16)
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 10)
		var title := _label("Skins", 60, GOLD, LOGO_FONT, HORIZONTAL_ALIGNMENT_LEFT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crow.add_child(title)
		crow.add_child(_coin_icon(40))
		skins_coins = _label("0", 38, Color("#ffe8a3"), UI_FONT_HEAVY)
		crow.add_child(skins_coins)
		box.add_child(crow)
		var tabs := HBoxContainer.new()
		tabs.add_theme_constant_override("separation", 14)
		for k in ["jar", "fly"]:
			var b := _ghost_btn("Jars" if k == "jar" else "Fireflies", func():
				Sound.play("select")
				skins_tab = k
				skins_pick = ""
				_refresh_skins())
			b.custom_minimum_size = Vector2(0, 76)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 32)
			skins_tabs[k] = b
			tabs.add_child(b)
		box.add_child(tabs)
		skins_grid = GridContainer.new()
		skins_grid.columns = 3
		skins_grid.add_theme_constant_override("h_separation", 14)
		skins_grid.add_theme_constant_override("v_separation", 14)
		for n in 5:
			skins_grid.add_child(_skin_tile(n))
		box.add_child(skins_grid)
		skins_action = _coin_btn("")
		skins_action.pressed.connect(_skins_action)
		box.add_child(skins_action)
		box.add_child(_label("Get more coins", 28, MUTED, UI_FONT_HEAVY))
		var packs := HBoxContainer.new()
		packs.add_theme_constant_override("separation", 14)
		for n in Store.COIN_PACKS.size():
			packs.add_child(_pack_btn(n))
		box.add_child(packs)
		var done := Button.new()
		done.text = "Done"
		done.custom_minimum_size = Vector2(0, 92)
		done.add_theme_font_size_override("font_size", 40)
		done.pressed.connect(func():
			Sound.play("select")
			skins_layer.hide())
		box.add_child(done)
	skins_pick = ""
	_refresh_skins()
	move_child(skins_layer, -1)
	skins_layer.show()

## One tile: a live preview, the skin's name, and its price or "In use".
func _skin_tile(n: int) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(176, 232)
	for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.pressed.connect(func():
		var it: Array = _skin_list()[n]
		Sound.play("select")
		if _skin_owned(skins_tab, it[0]):
			_use_skin(skins_tab, it[0])
		skins_pick = it[0]
		_refresh_skins())
	b.draw.connect(func():
		var it: Array = _skin_list()[n]
		var id: String = it[0]
		var owned := _skin_owned(skins_tab, id)
		var using := _skin_in_use(skins_tab, id)
		var picked := skins_pick == id
		var sb := _glass(26, 0.5)
		sb.bg_color = Color(1.0, 0.85, 0.23, 0.12) if using or picked else Color(0.12, 0.15, 0.36, 0.55)
		sb.border_color = Color(1.0, 0.85, 0.23, 0.9) if using or picked else Color(0.6, 0.7, 1.0, 0.25)
		sb.set_border_width_all(4 if using or picked else 2)
		b.draw_style_box(sb, Rect2(Vector2.ZERO, b.size))
		var t := Time.get_ticks_msec() / 1000.0
		var cx := b.size.x * 0.5
		if skins_tab == "jar":
			var r := Rect2(cx - 40, 26, 80, 124)
			Art.jar_back(b, r, null, id)
			for k in 2:
				var p := Vector2(cx + (-14 if k == 0 else 14), 118 - k * 34 + sin(t * 2.0 + k) * 2.0)
				Art.fly(b, p, 14, Art.COLORS[[0, 2][k]], t * 9.0 + k, true, false, k * 3.0, t)
			Art.jar_front(b, r, Art.jar_line(id), 3.0, id)
		else:
			var p := Vector2(cx, 96 + sin(t * 2.2 + n) * 5.0)
			Art.glow(b, p, 70, Art.COLORS[(n * 3) % 10], 0.25)
			Art.fly(b, p, 30, Art.COLORS[(n * 3) % 10], t * 9.0 + n, true, true, n * 2.0, t, id)
		var name := tr(it[1])
		var fs := _fit_fs(name, 26, b.size.x - 16)
		var nw := UI_FONT_HEAVY.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		b.draw_string(UI_FONT_HEAVY, Vector2(cx - nw * 0.5, 180), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		var st := ""
		var col := MUTED
		if using:
			st = tr("In use")
			col = GOLD
		elif owned:
			st = tr("Owned")
		else:
			st = str(it[2])
			col = Color("#ffe8a3") if Save.coins >= int(it[2]) else MUTED
		var sfs := _fit_fs(st, 26, b.size.x - 60)
		var sw := UI_FONT_HEAVY.get_string_size(st, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
		var x0 := cx - sw * 0.5
		if not owned:
			x0 += 16
			Art.icon(b, "coin", Vector2(x0 - 20, 208), 28, Color.WHITE)
		elif using:
			x0 += 14
			Art.icon(b, "check", Vector2(x0 - 20, 208), 26, GOLD)
		b.draw_string(UI_FONT_HEAVY, Vector2(x0, 218), st, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, col))
	return b

## A coin pack for real money: a little pile of coins, how many, and the price.
func _pack_btn(n: int) -> Button:
	var pk: Array = Store.COIN_PACKS[n]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 132)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := _glass(26, 0.5)
	sb.bg_color = Color(1.0, 0.78, 0.24, 0.12)
	sb.border_color = Color(1.0, 0.78, 0.24, 0.6)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(func():
		Sound.play("select")
		Store.buy_coins(pk[0]))
	b.draw.connect(func():
		var cx := b.size.x * 0.5
		for k in n + 1:
			Art.icon(b, "coin", Vector2(cx - n * 12 + k * 24, 34 - (k % 2) * 6), 40, Color.WHITE)
		var amt := str(pk[1])
		var aw := UI_FONT_HEAVY.get_string_size(amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		b.draw_string(UI_FONT_HEAVY, Vector2(cx - aw * 0.5, 88), amt, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#ffe8a3"))
		var pr := Store.pack_price(pk[0])
		var pfs := _fit_fs(pr, 26, b.size.x - 12)
		var pw := UI_FONT_HEAVY.get_string_size(pr, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs).x
		b.draw_string(UI_FONT_HEAVY, Vector2(cx - pw * 0.5, 122), pr, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs, INK))
	return b

func _refresh_skins() -> void:
	if skins_layer == null:
		return
	skins_coins.text = str(Save.coins)
	for k in skins_tabs:
		var b: Button = skins_tabs[k]
		var on: bool = k == skins_tab
		var sb := _gold(false) if on else _glass(30, 0.5)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_color_override("font_color", Color("#3a2205") if on else Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color("#3a2205") if on else Color.WHITE)
		b.add_theme_font_size_override("font_size", _fit_fs(tr(b.text), 32, 180))   # "Glühwürmchen" stays on one line
	for t in skins_grid.get_children():
		t.queue_redraw()
	# the button under the tiles: buy the picked skin, or a short note
	var it = null
	for x in _skin_list():
		if x[0] == skins_pick:
			it = x
	if it == null or _skin_owned(skins_tab, it[0]):
		skins_action.disabled = true
		skins_action.text = tr("Tap a look to choose it") if it == null else tr("You're using it now")
	else:
		_set_coin_btn(skins_action, int(it[2]), "Buy for {0}")
	# one line in every language, so the card never grows past the bottom of the screen
	skins_action.add_theme_font_size_override("font_size", _fit_fs(skins_action.text, 34, 490))

func _skins_action() -> void:
	for it in _skin_list():
		if it[0] == skins_pick and not _skin_owned(skins_tab, it[0]):
			if not _spend_coins(int(it[2]), "skin_" + skins_tab + "_" + it[0]):
				return
			Save.skins[skins_tab + "_" + it[0]] = true
			_use_skin(skins_tab, it[0])
			Sound.play("jar_done")
			Save.buzz(25)
			_top_toast("New look!", tr(it[1]), false)
			_refresh_skins()
			return

func _use_skin(kind: String, id: String) -> void:
	if kind == "jar":
		Save.jar_skin = id
		Art.jar_skin = id
	else:
		Save.fly_skin = id
		Art.fly_skin = id
	Save.save_game()
	Analytics.log_event("skin_use", {"kind": kind, "skin": id})
	_redraw_all(self)
