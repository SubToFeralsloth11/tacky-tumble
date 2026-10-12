class_name Hud
extends CanvasLayer
## In-game HUD plus the pause and results overlays. Built in code.

signal resume_requested
signal restart_requested
signal menu_requested
signal next_requested
signal keep_rolling_requested

var _size_label: Label
var _goal_label: Label
var _bar: ProgressBar
var _ring: SizeRing
var _timer_label: Label
var _feed: VBoxContainer
var _banner: Label
var _hint: Label
var _overlay: Control
var _overlay_box: VBoxContainer
var _settings: SettingsPanel
var _last_tick := -1


class SizeRing extends Control:
	## Goal circle outline with the current ball size drawn inside it.
	var fraction := 0.1
	var color := Color.WHITE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 4.0
		draw_circle(c, r, Color(0, 0, 0, 0.35))
		draw_arc(c, r, 0, TAU, 64, Color(1, 1, 1, 0.9), 4.0, true)
		draw_circle(c, maxf(r * clampf(fraction, 0.0, 1.0), 2.0), color)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Game.ui_theme()
	add_child(root)

	# size readout, top left
	var size_panel := PanelContainer.new()
	size_panel.position = Vector2(24, 24)
	root.add_child(size_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	size_panel.add_child(hb)
	_ring = SizeRing.new()
	_ring.custom_minimum_size = Vector2(110, 110)
	_ring.color = Game.tape_color()
	hb.add_child(_ring)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)
	_size_label = _label(vb, "", 54)
	_goal_label = _label(vb, "", 22)
	_goal_label.modulate = Color(1, 1, 1, 0.8)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(260, 16)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	vb.add_child(_bar)

	# timer, top right
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 64)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_timer_label.offset_left = -300
	_timer_label.offset_right = -32
	_timer_label.offset_top = 20
	root.add_child(_timer_label)

	# pickup feed, bottom left
	_feed = VBoxContainer.new()
	_feed.alignment = BoxContainer.ALIGNMENT_END
	_feed.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_feed.offset_left = 32
	_feed.offset_top = -330
	_feed.offset_right = 600
	_feed.offset_bottom = -28
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_feed)

	# centre banner
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 110)
	_banner.add_theme_constant_override("outline_size", 18)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.offset_bottom = -200
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_hint = Label.new()
	_hint.text = "WASD / left stick: roll    Mouse / Q E / right stick: turn camera    Esc: pause"
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -700
	_hint.offset_right = 700
	_hint.offset_top = -70
	_hint.offset_bottom = -30
	root.add_child(_hint)
	var hint_tw := create_tween()
	hint_tw.tween_interval(9.0)
	hint_tw.tween_property(_hint, "modulate:a", 0.0, 1.5)

	# pause/results overlay
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	_overlay_box = VBoxContainer.new()
	_overlay_box.add_theme_constant_override("separation", 14)
	panel.add_child(_overlay_box)
	_settings = SettingsPanel.new()
	_settings.visible = false
	center.add_child(_settings)
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		panel.visible = true
		_focus_first())


func _label(parent: Control, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l


func update_status(size_cm: float, goal_cm: float, start_cm: float, time_left: float, timed: bool) -> void:
	_size_label.text = Game.format_size(size_cm)
	_goal_label.text = "Goal: %s" % Game.format_size(goal_cm)
	var frac := clampf(log(size_cm / start_cm) / log(goal_cm / start_cm), 0.0, 1.0)
	_bar.value = frac
	_ring.fraction = size_cm / goal_cm
	_ring.queue_redraw()
	_timer_label.visible = timed
	if timed:
		_timer_label.text = Game.format_time(time_left)
		var urgent := time_left <= 30.0
		_timer_label.modulate = Color(1, 0.4, 0.4) if urgent else Color.WHITE
		var whole := int(ceil(time_left))
		if urgent and whole <= 10 and whole != _last_tick:
			_last_tick = whole
			Sfx.play("tick", 1.0 + (10 - whole) * 0.05)


func add_feed(text: String, color: Color = Color(1, 0.95, 0.6)) -> void:
	var l := _label(_feed, text, 28)
	l.modulate = color
	if _feed.get_child_count() > 6:
		_feed.get_child(0).queue_free()
	var tw := l.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func banner(text: String, color: Color = Color.WHITE, hold: float = 1.0) -> void:
	_banner.text = text
	_banner.modulate = color
	_banner.modulate.a = 0.0
	_banner.scale = Vector2.ONE
	_banner.pivot_offset = _banner.size * 0.5
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_banner, "scale", Vector2.ONE * 1.08, 0.15)
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)


func show_pause() -> void:
	_clear_overlay()
	_title("Paused")
	_button("Resume", resume_requested)
	_button("Restart", restart_requested)
	_button("Settings", Signal(), func() -> void:
		_overlay_box.get_parent().visible = false
		_settings.visible = true)
	_button("Quit to menu", menu_requested)
	_open()


func show_results(won: bool, stars: int, time_used: float, size_cm: float, goal_cm: float, has_next: bool) -> void:
	_clear_overlay()
	if won:
		_title("Goal reached!")
		var s := _label(_overlay_box, Game.star_text(stars), 72)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.modulate = Color(1.0, 0.85, 0.3)
		_info("Time: %s" % Game.format_time(time_used))
		_info("Size: %s" % Game.format_size(size_cm))
		if has_next:
			_button("Next level", next_requested)
		_button("Keep rolling (free play)", keep_rolling_requested)
	else:
		_title("Time's up!")
		_info("You reached %s of %s." % [Game.format_size(size_cm), Game.format_size(goal_cm)])
		_info("So close. Grab the small stuff first!")
	_button("Retry", restart_requested)
	_button("Main menu", menu_requested)
	_open()


func hide_overlay() -> void:
	_overlay.visible = false
	_settings.visible = false


func is_overlay_open() -> bool:
	return _overlay.visible


func _open() -> void:
	_overlay.visible = true
	_settings.visible = false
	_overlay_box.get_parent().visible = true
	_focus_first.call_deferred()


func _focus_first() -> void:
	for c in _overlay_box.get_children():
		if c is Button:
			c.grab_focus()
			return


func _clear_overlay() -> void:
	for c in _overlay_box.get_children():
		_overlay_box.remove_child(c)
		c.queue_free()


func _title(text: String) -> void:
	var l := _label(_overlay_box, text, 52)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _info(text: String) -> void:
	var l := _label(_overlay_box, text, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _button(text: String, sig: Signal, action: Callable = Callable()) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		if action.is_valid():
			action.call()
		else:
			sig.emit())
	_overlay_box.add_child(b)
