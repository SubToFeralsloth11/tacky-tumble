extends Node3D
## Title screen: a spinning tape ball backdrop with main, level-select, colour and settings panels.

var _ball: Ball
var _cam: Camera3D
var _t := 0.0
var _ui: Control
var _panels := {}
var _stars_label: Label


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 9.8)
	_build_backdrop()
	_build_ui()
	_show("main")
	Sfx.play_music(0)


func _process(delta: float) -> void:
	_t += delta
	_ball.clump.rotate_y(delta * 0.35)
	_ball.clump.rotate_x(delta * 0.2)
	_cam.position = Vector3(sin(_t * 0.1) * 5.0, 2.2 + sin(_t * 0.3) * 0.2, cos(_t * 0.1) * 5.0)
	_cam.look_at(Vector3(-1.6, 1.0, 0).rotated(Vector3.UP, _t * 0.1), Vector3.UP)


# ---------------------------------------------------------------- backdrop

func _build_backdrop() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.45, 0.4, 0.95)
	sm.sky_horizon_color = Color(1.0, 0.75, 0.85)
	sm.ground_horizon_color = Color(1.0, 0.75, 0.85)
	sm.ground_bottom_color = Color(0.4, 0.3, 0.6)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	floor_mi.mesh = plane
	floor_mi.material_override = Props.material("ffc8dd")
	add_child(floor_mi)

	_ball = Ball.new()
	_ball.setup(1.0, Game.tape_color(), 0.0)
	_ball.freeze = true
	_ball.position = Vector3(0, 1.0, 0)
	add_child(_ball)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var kinds := ["duck", "apple", "die", "mug", "toycar", "can", "cookie", "crayon", "book", "strawberry",
		"banana", "eraser", "candy", "teddy", "spoon", "sneaker", "marble", "button"]
	for i in 60:
		var kind: String = kinds[i % kinds.size()]
		var p := Props.build(kind, 1.0)
		p.collision_layer = 0
		p.get_node("Shape").disabled = true
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		_ball.clump.add_child(p)
		p.basis = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT) * Basis(Vector3.RIGHT, -PI * 0.5)
		p.scale = Vector3.ONE * rng.randf_range(0.35, 0.6) / float(p.get_meta("size"))
		p.position = dir * 0.9

	for i in 26:
		var kind: String = kinds[rng.randi() % kinds.size()]
		var p := Props.build(kind, 0.06)
		var a := rng.randf() * TAU
		# Outside the camera's orbit (radius 5) so nothing blocks the view of the ball.
		p.position = Vector3(cos(a), 0, sin(a)) * rng.randf_range(6.5, 14.0)
		p.rotation.y = rng.randf() * TAU
		add_child(p)

	_cam = Camera3D.new()
	_cam.fov = 55
	add_child(_cam)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.theme = Game.ui_theme()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)

	_stars_label = Label.new()
	_stars_label.add_theme_font_size_override("font_size", 34)
	_stars_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_stars_label.offset_left = -300
	_stars_label.offset_right = -36
	_stars_label.offset_top = 24
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui.add_child(_stars_label)

	var main := _panel("main")
	var title := Label.new()
	title.text = "TACKY\nTUMBLE"
	title.add_theme_font_size_override("font_size", 108)
	title.add_theme_constant_override("outline_size", 22)
	title.add_theme_constant_override("line_spacing", -30)
	title.modulate = Color(1.0, 0.92, 0.5)
	main.add_child(title)
	var tag := Label.new()
	tag.text = "Stick it. Roll it. Swallow the world."
	tag.add_theme_font_size_override("font_size", 26)
	main.add_child(tag)
	main.add_child(_spacer(18))
	_menu_button(main, "Play", func() -> void: _show("levels"))
	_menu_button(main, "Tape colours", func() -> void: _show("colors"))
	_menu_button(main, "Settings", func() -> void: _show("settings"))
	if OS.get_name() != "Web":
		_menu_button(main, "Quit", func() -> void: get_tree().quit())

	var settings := SettingsPanel.new()
	settings.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	settings.position = Vector2(80, 180)
	settings.closed.connect(func() -> void: _show("main"))
	_ui.add_child(settings)
	_panels.settings = settings


func _panel(id: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.position = Vector2(90, 70)
	box.custom_minimum_size = Vector2(520, 0)
	_ui.add_child(box)
	_panels[id] = box
	return box


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _menu_button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		action.call())
	parent.add_child(b)
	return b


func _show(id: String) -> void:
	if id == "levels":
		_rebuild_levels()
	elif id == "colors":
		_rebuild_colors()
	for k in _panels:
		_panels[k].visible = k == id
	_stars_label.text = "★ %d / %d" % [Game.total_stars(), Game.LEVELS.size() * 3]
	var first := _first_button(_panels[id])
	if first:
		_focus.call_deferred(first)


func _focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree():
		c.grab_focus()


func _first_button(n: Node) -> Button:
	for c in n.get_children():
		if c is Button and not c.disabled:
			return c
		var deeper := _first_button(c)
		if deeper:
			return deeper
	return null


func _rebuild_levels() -> void:
	if _panels.has("levels"):
		_panels.levels.queue_free()
		_panels.erase("levels")
	var box := _panel("levels")
	var head := Label.new()
	head.text = "Choose a level"
	head.add_theme_font_size_override("font_size", 56)
	box.add_child(head)
	for i in Game.LEVELS.size():
		var l: Dictionary = Game.LEVELS[i]
		var unlocked := Game.is_unlocked(i)
		var stars := Game.stars_for(l.id)
		var text := "%d. %s   %s\n" % [i + 1, l.name, Game.star_text(stars)]
		if unlocked:
			text += "Grow to %s in %s" % [Game.format_size(l.goal_d), Game.format_time(l.time)]
			if Game.data.best_time.has(l.id):
				text += "  ·  best %s" % Game.format_time(Game.data.best_time[l.id])
		else:
			text += "Locked: finish %s first" % Game.LEVELS[i - 1].name
		var b := _menu_button(box, text, func() -> void: Game.start_level(i))
		b.custom_minimum_size = Vector2(620, 96)
		b.add_theme_font_size_override("font_size", 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not unlocked
		b.tooltip_text = l.blurb
	box.add_child(_spacer(8))
	_menu_button(box, "Back", func() -> void: _show("main"))


func _rebuild_colors() -> void:
	if _panels.has("colors"):
		_panels.colors.queue_free()
		_panels.erase("colors")
	var box := _panel("colors")
	var head := Label.new()
	head.text = "Tape colours"
	head.add_theme_font_size_override("font_size", 56)
	box.add_child(head)
	var info := Label.new()
	info.text = "Earn stars to unlock more tape."
	info.add_theme_font_size_override("font_size", 24)
	box.add_child(info)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for i in Game.TAPE_COLORS.size():
		var c: Dictionary = Game.TAPE_COLORS[i]
		var unlocked := Game.color_unlocked(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 70)
		var selected := int(Game.data.color) == i
		b.text = ("✔ " if selected else "") + (c.name if unlocked else "%s  (★%d)" % [c.name, c.stars])
		b.disabled = not unlocked
		var sb := Game._box(c.color if unlocked else Color(0.4, 0.4, 0.45), 14)
		b.add_theme_stylebox_override("normal", sb)
		var hover := Game._box((c.color as Color).lightened(0.3), 14)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("disabled", sb)
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			Game.data.color = i
			Game.save()
			_recolor_ball()
			_show("colors"))
		grid.add_child(b)
	box.add_child(_spacer(8))
	_menu_button(box, "Back", func() -> void: _show("main"))


func _recolor_ball() -> void:
	var old := _ball
	var clump_basis := old.clump.basis
	_ball = Ball.new()
	_ball.setup(1.0, Game.tape_color(), 0.0)
	_ball.freeze = true
	_ball.position = old.position
	add_child(_ball)
	_ball.clump.basis = clump_basis
	for p in old.clump.get_children():
		if p is StaticBody3D:
			p.reparent(_ball.clump, false)
	old.queue_free()
