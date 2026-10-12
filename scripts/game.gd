extends Node
## Global game state: level definitions, save data, settings, input map, theme.

const SAVE_PATH := "user://save.cfg"
const MENU_SCENE := "res://scenes/menu.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"

## Fraction of the time limit that must remain for 3 / 2 stars. Reaching the goal at all = 1 star.
const STAR3_TIME_LEFT := 0.35
const STAR2_TIME_LEFT := 0.15

const TAPE_COLORS := [
	{"name": "Duct Silver", "color": Color(0.72, 0.75, 0.78), "stars": 0},
	{"name": "Bubblegum", "color": Color(1.0, 0.49, 0.71), "stars": 1},
	{"name": "Lime Zest", "color": Color(0.61, 0.9, 0.39), "stars": 2},
	{"name": "Sky Blue", "color": Color(0.37, 0.78, 1.0), "stars": 4},
	{"name": "Midnight", "color": Color(0.36, 0.25, 0.66), "stars": 6},
	{"name": "Gold Leaf", "color": Color(1.0, 0.81, 0.25), "stars": 9},
]

## Every distance in a level definition is in centimetres. `cm_per_unit` maps them to world units so
## each level's physics runs at a comfortable scale.
const LEVELS := [
	{
		"id": "kitchen", "name": "Kitchen Floor",
		"blurb": "Crumbs, coins and a very confused cat.",
		"cm_per_unit": 1.0, "start_d": 10.0, "goal_d": 100.0, "time": 240.0, "half": 650.0,
		"ground": "tiles", "walls": "kitchen", "growth": 0.36,
		"sky_top": Color(0.55, 0.74, 0.95), "sky_horizon": Color(1.0, 0.9, 0.8), "fog": 0.0,
		"music_root": 0,
		"spawns": [
			["crumb", 130], ["pea", 80], ["coin", 70], ["button", 60], ["sugar", 50], ["die", 45],
			["marble", 50], ["bottlecap", 50], ["candy", 50], ["strawberry", 40], ["eraser", 45],
			["crayon", 50], ["cookie", 35], ["spoon", 35], ["apple", 30], ["banana", 22], ["mug", 24],
			["duck", 22], ["toycar", 22], ["can", 24], ["book", 22], ["sneaker", 16], ["teddy", 12],
			["toaster", 8], ["pot", 9], ["cat", 5], ["watermelon", 7], ["basket", 5], ["bin", 4],
			["dogbed", 3], ["stool", 5], ["chair", 6], ["table", 2], ["fridge", 1],
		],
	},
	{
		"id": "backyard", "name": "Backyard",
		"blurb": "Gnomes, bikes and one suspicious trampoline.",
		"cm_per_unit": 10.0, "start_d": 50.0, "goal_d": 500.0, "time": 300.0, "half": 4200.0,
		"ground": "grass", "walls": "fence", "growth": 0.42,
		"sky_top": Color(0.35, 0.6, 0.95), "sky_horizon": Color(0.8, 0.9, 1.0), "fog": 0.0006,
		"music_root": 5,
		"spawns": [
			["tennisball", 70], ["pinecone", 70], ["duck", 40], ["can", 40], ["sneaker", 50],
			["soccerball", 45], ["flowerpot", 55], ["toybucket", 45], ["frisbee", 35], ["teddy", 30],
			["gnome", 45], ["wateringcan", 40], ["basket", 26], ["bin", 26], ["cat", 18], ["dog", 22],
			["lawnchair", 24], ["lawnmower", 16], ["bush", 50], ["bbq", 14], ["wheelbarrow", 16],
			["bicycle", 20], ["picnictable", 12], ["kiddiepool", 8], ["doghouse", 8], ["hottub", 6],
			["swingset", 6], ["trampoline", 5], ["shed", 5], ["car", 3], ["tree", 22],
		],
	},
	{
		"id": "downtown", "name": "Downtown",
		"blurb": "Swallow the city. Leave nothing.",
		"cm_per_unit": 100.0, "start_d": 300.0, "goal_d": 4000.0, "time": 360.0, "half": 30000.0,
		"ground": "city", "walls": "city", "growth": 0.26,
		"sky_top": Color(0.3, 0.45, 0.85), "sky_horizon": Color(1.0, 0.8, 0.65), "fog": 0.0012,
		"music_root": 7,
		"spawns": [
			["person_a", 70], ["person_b", 70], ["person_c", 70], ["hydrant", 45], ["mailbox", 35],
			["bin", 45], ["bench", 45], ["bush", 45], ["bicycle", 45], ["dog", 35], ["kiosk", 18],
			["car", 90], ["lamppost", 50], ["trafficlight", 22], ["van", 35], ["citytree", 55],
			["truck", 18], ["bus", 14], ["house", 34], ["shop", 22], ["apartment", 12], ["tower", 6],
		],
	},
]

var current_level := 0
var autotest := false
var autotest_level := -1

var data := {
	"stars": {},
	"best_time": {},
	"best_size": {},
	"color": 0,
	"settings": {
		"master": 0.9, "music": 0.6, "sfx": 0.8, "sensitivity": 1.0, "invert": false, "fullscreen": false,
	},
}


func _ready() -> void:
	_setup_input()
	_load()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autotest="):
			autotest = true
			autotest_level = int(arg.get_slice("=", 1))
		elif arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-at="):
			_shot_at = float(arg.get_slice("=", 1))
	apply_settings()
	if autotest:
		current_level = clampi(autotest_level, 0, LEVELS.size() - 1)
		get_tree().change_scene_to_file.call_deferred(LEVEL_SCENE)
	elif _shot_path.is_empty():
		set_process(false)


var _autotest_frames := 0
var _shot_path := ""  ## --shot=<png>: save a screenshot after --shot-at=<seconds> (default 3) and quit
var _shot_at := 3.0
var _clock := 0.0


## Dev tooling only: autotest watchdog (a broken level must not hang playtests) and screenshots.
func _process(delta: float) -> void:
	_clock += delta
	if not _shot_path.is_empty() and _clock >= _shot_at:
		get_viewport().get_texture().get_image().save_png(_shot_path)
		print("SHOT saved %s" % _shot_path)
		get_tree().quit()
		return
	if autotest:
		_autotest_frames += 1
		if _autotest_frames > int((float(LEVELS[current_level].time) + 30.0) * 60.0):
			print("AUTOTEST watchdog: level never finished")
			get_tree().quit(2)

# ---------------------------------------------------------------- input

func _setup_input() -> void:
	_bind("move_forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_back", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("cam_left", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_RIGHT_X, -1.0]])
	_bind("cam_right", [KEY_E], [JOY_BUTTON_RIGHT_SHOULDER], [[JOY_AXIS_RIGHT_X, 1.0]])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])


func _bind(action: StringName, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.25)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		InputMap.action_add_event(action, e)


# ---------------------------------------------------------------- save data

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in ["stars", "best_time", "best_size"]:
		var v = cfg.get_value("progress", key, {})
		if v is Dictionary:
			data[key] = v
	data.color = int(cfg.get_value("progress", "color", 0))
	var s = cfg.get_value("settings", "values", {})
	if s is Dictionary:
		for k in s:
			if data.settings.has(k):
				data.settings[k] = s[k]


func save() -> void:
	if autotest:
		return
	var cfg := ConfigFile.new()
	for key in ["stars", "best_time", "best_size"]:
		cfg.set_value("progress", key, data[key])
	cfg.set_value("progress", "color", data.color)
	cfg.set_value("settings", "values", data.settings)
	cfg.save(SAVE_PATH)


func apply_settings() -> void:
	var s: Dictionary = data.settings
	Sfx.set_volumes(s.master, s.music, s.sfx)
	if not autotest and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if s.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func stars_for(level_id: String) -> int:
	return int(data.stars.get(level_id, 0))


func total_stars() -> int:
	var t := 0
	for l in LEVELS:
		t += stars_for(l.id)
	return t


func is_unlocked(index: int) -> bool:
	return index == 0 or stars_for(LEVELS[index - 1].id) > 0


func color_unlocked(index: int) -> bool:
	return total_stars() >= int(TAPE_COLORS[index].stars)


func tape_color() -> Color:
	var i := clampi(int(data.color), 0, TAPE_COLORS.size() - 1)
	if not color_unlocked(i):
		i = 0
	return TAPE_COLORS[i].color


## Records a finished run and returns the stars earned (0 when the goal was missed).
func record_result(index: int, won: bool, time_used: float, size_cm: float) -> int:
	var def: Dictionary = LEVELS[index]
	var stars := 0
	if won:
		var left := 1.0 - time_used / float(def.time)
		stars = 3 if left >= STAR3_TIME_LEFT else (2 if left >= STAR2_TIME_LEFT else 1)
		var best = data.best_time.get(def.id)
		if best == null or time_used < float(best):
			data.best_time[def.id] = time_used
	data.stars[def.id] = maxi(stars_for(def.id), stars)
	data.best_size[def.id] = maxf(float(data.best_size.get(def.id, 0.0)), size_cm)
	save()
	return stars


# ---------------------------------------------------------------- scene flow

func start_level(index: int) -> void:
	current_level = index
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SCENE)


func go_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)


func level_def() -> Dictionary:
	return LEVELS[current_level]


# ---------------------------------------------------------------- formatting & theme

static func format_size(cm: float) -> String:
	if cm < 10.0:
		return "%.1f cm" % cm
	if cm < 100.0:
		return "%d cm" % int(cm)
	if cm < 1000.0:
		return "%.2f m" % (cm / 100.0)
	return "%.1f m" % (cm / 100.0)


static func format_time(seconds: float) -> String:
	var s := maxi(int(ceil(seconds)), 0)
	return "%d:%02d" % [s / 60, s % 60]


static func star_text(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(3 - n)


var _theme: Theme


func ui_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Nunito", "Arial Rounded MT Bold", "Avenir Next", "Segoe UI", "Verdana", "sans-serif"])
	font.font_weight = 800
	t.default_font = font
	t.default_font_size = 24

	var normal := _box(Color(1, 1, 1, 0.92), 14)
	var hover := _box(Color(1.0, 0.87, 0.35), 14)
	var pressed := _box(Color(1.0, 0.6, 0.78), 14)
	var disabled := _box(Color(0.6, 0.6, 0.65, 0.6), 14)
	for style in [["normal", normal], ["hover", hover], ["pressed", pressed], ["focus", hover.duplicate()], ["disabled", disabled]]:
		t.set_stylebox(style[0], "Button", style[1])
	(t.get_stylebox("focus", "Button") as StyleBoxFlat).draw_center = false
	(t.get_stylebox("focus", "Button") as StyleBoxFlat).border_color = Color(0.25, 0.15, 0.4)
	(t.get_stylebox("focus", "Button") as StyleBoxFlat).set_border_width_all(4)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color(0.18, 0.12, 0.3))
	t.set_color("font_disabled_color", "Button", Color(0.3, 0.3, 0.35))

	t.set_stylebox("panel", "PanelContainer", _box(Color(0.13, 0.1, 0.22, 0.9), 22, 28))
	t.set_color("font_color", "Label", Color(1, 1, 1))
	t.set_color("font_outline_color", "Label", Color(0.12, 0.06, 0.2))
	t.set_constant("outline_size", "Label", 8)
	var check_bg := _box(Color(1, 1, 1, 0.06), 12)
	var check_hover := _box(Color(1, 1, 1, 0.16), 12)
	for style in [["normal", check_bg], ["pressed", check_bg], ["hover", check_hover], ["hover_pressed", check_hover], ["focus", check_hover]]:
		t.set_stylebox(style[0], "CheckButton", style[1])
	for c in ["font_color", "font_pressed_color"]:
		t.set_color(c, "CheckButton", Color(1, 1, 1))
	for c in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "CheckButton", Color(1, 0.87, 0.35))

	var bar_bg := _box(Color(0, 0, 0, 0.45), 10, 0)
	var bar_fill := _box(Color(1.0, 0.49, 0.71), 10, 0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_stylebox("slider", "HSlider", _box(Color(1, 1, 1, 0.3), 6, 8))
	t.set_stylebox("grabber_area", "HSlider", _box(Color(1.0, 0.49, 0.71), 6, 8))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(Color(1.0, 0.87, 0.35), 6, 8))
	_theme = t
	return t


static func _box(color: Color, radius: int, margin: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.5
	s.content_margin_bottom = margin * 0.5
	return s
