class_name SettingsPanel
extends PanelContainer
## Volume, camera and display settings. Shared by the main menu and the pause menu.

signal closed


func _ready() -> void:
	theme = Game.ui_theme()
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var s: Dictionary = Game.data.settings
	_slider(box, "Master volume", "master", 0.0, 1.0)
	_slider(box, "Music", "music", 0.0, 1.0)
	_slider(box, "Sound effects", "sfx", 0.0, 1.0)
	_slider(box, "Camera sensitivity", "sensitivity", 0.3, 2.5)

	var invert := CheckButton.new()
	invert.text = "Invert camera"
	invert.button_pressed = s.invert
	invert.toggled.connect(func(on: bool) -> void: _store("invert", on))
	box.add_child(invert)

	var full := CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = s.fullscreen
	full.toggled.connect(func(on: bool) -> void: _store("fullscreen", on))
	box.add_child(full)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		Game.save()
		closed.emit())
	box.add_child(back)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			back.grab_focus.call_deferred())


func _slider(parent: Control, text: String, key: String, lo: float, hi: float) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(250, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 0.05
	sl.value = float(Game.data.settings[key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.custom_minimum_size = Vector2(0, 24)
	sl.value_changed.connect(func(v: float) -> void: _store(key, v))
	row.add_child(sl)
	parent.add_child(row)


func _store(key: String, value: Variant) -> void:
	Game.data.settings[key] = value
	Game.apply_settings()
