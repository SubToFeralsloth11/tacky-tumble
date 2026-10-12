extends Node3D
## Builds the current level (environment, ground, walls, props) and runs the timed roll-up loop.

enum State { INTRO, PLAY, FREE, DONE }

var def: Dictionary
var unit := 1.0  ## world units per centimetre
var half := 1.0  ## half the side length of the play area, world units
var ball: Ball
var hud: Hud
var items_root: Node3D

var _state := State.INTRO
var _time_left := 0.0
var _elapsed := 0.0
var _rng := RandomNumberGenerator.new()
var _sorted: Array[StaticBody3D] = []  ## every prop, smallest first
var _next_pickable := 0
var _announced := {}
var _cam_pivot: Node3D
var _spring: SpringArm3D
var _camera: Camera3D
var _cam_yaw := 0.0
var _shake := 0.0
var _sun: DirectionalLight3D
var _bursts: Array[CPUParticles3D] = []
var _burst_index := 0


func _ready() -> void:
	def = Game.level_def()
	unit = 1.0 / float(def.cm_per_unit)
	half = float(def.half) * unit
	_rng.seed = hash(def.id)
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 980.0 * unit)

	_build_environment()
	_build_ground()
	_build_walls()
	items_root = Node3D.new()
	items_root.name = "Props"
	add_child(items_root)
	_spawn_props()
	_build_ball()
	_build_camera()
	_build_bursts()

	hud = Hud.new()
	add_child(hud)
	hud.resume_requested.connect(_resume)
	hud.restart_requested.connect(func() -> void: Game.start_level(Game.current_level))
	hud.menu_requested.connect(Game.go_menu)
	hud.next_requested.connect(func() -> void: Game.start_level(Game.current_level + 1))
	hud.keep_rolling_requested.connect(_keep_rolling)

	_time_left = float(def.time)
	_refresh_pickable()
	_update_hud()
	Sfx.play_music(int(def.music_root))
	if Game.autotest:
		ball.autopilot = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.banner(def.name, Color.WHITE, 0.6)
	get_tree().create_timer(1.4).timeout.connect(_start)


func _start() -> void:
	_state = State.PLAY
	ball.input_enabled = true
	hud.banner("ROLL!", Color(1.0, 0.85, 0.3), 0.3)
	Sfx.play("go")


# ---------------------------------------------------------------- frame loop

func _process(delta: float) -> void:
	_update_camera(delta)
	if _state == State.PLAY:
		_time_left -= delta
		_elapsed += delta
		if Game.autotest and int(_elapsed / 20.0) != int((_elapsed - delta) / 20.0):
			print("AUTOTEST t=%.0f size_cm=%.1f pos=%s pickable=%d/%d" % [_elapsed, _size_cm(), ball.global_position, _next_pickable, _sorted.size()])
		if _size_cm() >= float(def.goal_d):
			_finish(true)
		elif _time_left <= 0.0:
			_time_left = 0.0
			_finish(false)
	_update_hud()


func _size_cm() -> float:
	return ball.diameter() / unit


func _update_hud() -> void:
	hud.update_status(_size_cm(), def.goal_d, def.start_d, _time_left, _state != State.FREE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		elif _state == State.PLAY or _state == State.FREE:
			_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * 0.0035 * _sens()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not Game.autotest and (_state == State.PLAY or _state == State.FREE) and not get_tree().paused:
		_pause()


func _sens() -> float:
	var s: Dictionary = Game.data.settings
	return float(s.sensitivity) * (-1.0 if s.invert else 1.0)


func _pause() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_pause()


func _resume() -> void:
	if _state == State.DONE:
		return
	hud.hide_overlay()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _keep_rolling() -> void:
	_state = State.FREE
	hud.hide_overlay()
	ball.input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _finish(won: bool) -> void:
	_state = State.DONE
	ball.input_enabled = false
	var size := _size_cm()
	var stars := Game.record_result(Game.current_level, won, _elapsed, size)
	if Game.autotest:
		print("AUTOTEST level=%s won=%s time=%.1f size_cm=%.1f stars=%d" % [def.id, won, _elapsed, size, stars])
		get_tree().quit(0 if won else 1)
		return
	Sfx.play("win" if won else "lose")
	hud.banner("GOAL!" if won else "TIME!", Color(1.0, 0.85, 0.3) if won else Color(1, 0.45, 0.45), 0.6)
	await get_tree().create_timer(1.3).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var has_next: bool = won and Game.current_level + 1 < Game.LEVELS.size()
	hud.show_results(won, stars, _elapsed, size, def.goal_d, has_next)


# ---------------------------------------------------------------- props & pickups

func _refresh_pickable() -> void:
	var limit := ball.pick_limit()
	while _next_pickable < _sorted.size():
		var item := _sorted[_next_pickable]
		if is_instance_valid(item):
			if float(item.get_meta("size")) > limit:
				break
			if item.get_meta("state") == "world":
				item.collision_layer = Props.LAYER_PICKABLE
			var kind: String = item.get_meta("kind")
			if not _announced.has(kind) and _state != State.INTRO:
				hud.add_feed("Now sticky enough for: %s!" % item.get_meta("label"), Color(0.55, 0.95, 1.0))
			_announced[kind] = true
		_next_pickable += 1


func _on_picked(item: StaticBody3D) -> void:
	var rel := float(item.get_meta("size")) / ball.pick_limit()
	Sfx.play("pop", lerpf(1.7, 0.8, rel), -4.0)
	hud.add_feed("+ %s" % item.get_meta("label"))
	_burst(ball.global_position + Vector3.UP * ball.radius * 0.5)
	_refresh_pickable()


func _on_bumped(strength: float) -> void:
	Sfx.play("bump", 1.0, linear_to_db(clampf(strength / 8.0, 0.3, 1.0)))
	_shake = minf(0.35, strength * 0.04)


func _on_dropped(item: StaticBody3D) -> void:
	Sfx.play("drop")
	hud.add_feed("Dropped %s!" % item.get_meta("label"), Color(1, 0.5, 0.5))


## Autopilot helper: nearest pickable prop, preferring bigger ones.
func _find_target(from: Vector3, limit: float, ignored: Dictionary, now: float) -> StaticBody3D:
	var best: StaticBody3D = null
	var best_score := INF
	for i in _next_pickable:
		var it := _sorted[i]
		if not is_instance_valid(it) or it.get_meta("state") != "world" or float(it.get_meta("size")) > limit:
			continue
		if float(ignored.get(it.get_instance_id(), -1.0)) > now:
			continue
		var d := Vector2(it.global_position.x - from.x, it.global_position.z - from.z).length()
		var score := d / sqrt(float(it.get_meta("size")))
		if score < best_score:
			best_score = score
			best = it
	return best


func _spawn_props() -> void:
	var all: Array[StaticBody3D] = []
	for spawn in def.spawns:
		for i in int(spawn[1]):
			all.append(Props.build(spawn[0], unit * _rng.randf_range(0.88, 1.12)))
	all.sort_custom(func(a: StaticBody3D, b: StaticBody3D) -> bool: return a.get_meta("size") > b.get_meta("size"))

	var start_r := float(def.start_d) * unit * 0.5
	var lo := log(float(def.start_d))
	var hi := log(float(def.goal_d) * 1.6)
	# Props too big to pick up at the start keep a gap wider than the starting ball between them,
	# so the player can never be wedged into a pocket of clutter.
	var start_limit := start_r * 2.0 * Ball.PICK_RATIO
	var gap := start_r * 2.0 * 1.6
	var solid: Array = []  # [Vector2 centre, float radius] of props solid at the start
	var by_kind := {}
	for p in all:
		var foot: float = p.get_meta("foot")
		var kind: String = p.get_meta("kind")
		var is_solid := float(p.get_meta("size")) > start_limit
		var frac := clampf((log(float(p.get_meta("size")) / unit) - lo) / (hi - lo), 0.0, 1.0)
		var reach := half * lerpf(0.22, 0.95, frac)
		var limit := half - foot - (gap if is_solid else start_r)
		var pos := Vector2.ZERO
		var ok := false
		for attempt in 24:
			var same: Array = by_kind.get(kind, [])
			if not same.is_empty() and _rng.randf() < 0.55:
				var a := _rng.randf() * TAU
				pos = same[_rng.randi() % same.size()] + Vector2(cos(a), sin(a)) * (foot * _rng.randf_range(2.2, 6.0) + (gap if is_solid else 0.0))
			else:
				var a := _rng.randf() * TAU
				pos = Vector2(cos(a), sin(a)) * sqrt(_rng.randf()) * reach
			if absf(pos.x) > limit or absf(pos.y) > limit or pos.length() < foot + start_r * 4.0:
				continue
			ok = true
			for s in solid:
				if pos.distance_to(s[0]) < s[1] + (foot + gap if is_solid else foot * 0.6):
					ok = false
					break
			if ok:
				break
		if not ok:
			p.free()
			continue
		if is_solid:
			solid.append([pos, foot])
		if not by_kind.has(kind):
			by_kind[kind] = []
		by_kind[kind].append(pos)
		p.position = Vector3(pos.x, 0.0, pos.y)
		p.rotation.y = _rng.randf() * TAU
		p.set_meta("state", "world")
		items_root.add_child(p)
		_sorted.append(p)
	_sorted.reverse()


# ---------------------------------------------------------------- world building

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = def.sky_top
	sm.sky_horizon_color = def.sky_horizon
	sm.ground_horizon_color = def.sky_horizon
	sm.ground_bottom_color = (def.sky_horizon as Color).darkened(0.4)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.4
	env.ssao_enabled = true
	env.ssao_radius = float(def.start_d) * unit * 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	if float(def.fog) > 0.0:
		env.fog_enabled = true
		env.fog_density = def.fog
		env.fog_light_color = def.sky_horizon
		env.fog_sky_affect = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-52, -38, 0)
	_sun.light_energy = 1.15
	_sun.light_color = Color(1.0, 0.96, 0.9)
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.shadow_blur = 1.5
	add_child(_sun)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var thick := half * 0.2
	box.size = Vector3(half * 2.6, thick, half * 2.6)
	cs.shape = box
	cs.position.y = -thick * 0.5
	body.add_child(cs)
	add_child(body)

	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(half * 2.6, half * 2.6)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	match def.ground:
		"tiles":
			mat.albedo_texture = _checker(Color("f3e9dc"), Color("d9a385"))
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			var tiles := (half * 2.6) / (30.0 * unit * 2.0)
			mat.uv1_scale = Vector3(tiles, tiles, 1)
			mat.roughness = 0.4
		"grass":
			var noise := FastNoiseLite.new()
			noise.frequency = 0.05
			var tex := NoiseTexture2D.new()
			tex.noise = noise
			tex.seamless = true
			tex.width = 256
			tex.height = 256
			var ramp := Gradient.new()
			ramp.set_color(0, Color("4f9a3a"))
			ramp.set_color(1, Color("7cc95a"))
			tex.color_ramp = ramp
			mat.albedo_texture = tex
			var reps := (half * 2.6) / (400.0 * unit)
			mat.uv1_scale = Vector3(reps, reps, 1)
		"city":
			mat.albedo_color = Color("3d405b")
			_city_blocks()
	mi.material_override = mat
	add_child(mi)


func _city_blocks() -> void:
	var block := 6000.0 * unit
	var road := 1400.0 * unit
	var mat := Props.material("c2c5cc")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(block - road, 0.1, block - road)
	mesh.material = mat
	var stripe := BoxMesh.new()
	stripe.size = Vector3(0.25, 0.06, block * 0.3)
	stripe.material = Props.material("f5f3ce")
	var n := int(ceil(half / block)) + 1
	for x in range(-n, n + 1):
		for z in range(-n, n + 1):
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.position = Vector3(x * block, 0.05, z * block)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			var s := MeshInstance3D.new()
			s.mesh = stripe
			s.position = Vector3(x * block + block * 0.5, 0.03, z * block)
			s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(s)


func _checker(a: Color, b: Color) -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, a)
	img.set_pixel(1, 1, a)
	img.set_pixel(1, 0, b)
	img.set_pixel(0, 1, b)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _build_walls() -> void:
	match def.walls:
		"kitchen":
			var depth := 60.0 * unit
			var h := 250.0 * unit
			for side in 4:
				var along := half * 2.0 + depth * 2.0
				var c := _side_centre(side, half + depth * 0.5)
				var size := _side_size(side, along, h, depth)
				_solid_box(c + Vector3(0, h * 0.5, 0), size, "ffd6a5")
				var cab := _side_size(side, along, 90.0 * unit, depth + 2.0 * unit)
				_visual_box(c + Vector3(0, 45.0 * unit, 0) - _side_normal(side) * unit, cab, "f6f1e9")
				var top := _side_size(side, along, 4.0 * unit, depth + 6.0 * unit)
				_visual_box(c + Vector3(0, 92.0 * unit, 0) - _side_normal(side) * 3.0 * unit, top, "495057")
				var kick := _side_size(side, along, 10.0 * unit, depth + 3.0 * unit)
				_visual_box(c + Vector3(0, 5.0 * unit, 0) - _side_normal(side) * 1.5 * unit, kick, "6c584c")
		"fence":
			var h := 180.0 * unit
			var t := 12.0 * unit
			for side in 4:
				var c := _side_centre(side, half + t * 0.5)
				_solid_box(c + Vector3(0, h * 0.5, 0), _side_size(side, half * 2.0 + t * 2.0, h, t), "c89f6d")
				_visual_box(c + Vector3(0, h * 0.75, 0) - _side_normal(side) * t * 0.6, _side_size(side, half * 2.0, 10.0 * unit, t * 0.4), "a47148")
				_visual_box(c + Vector3(0, h * 0.25, 0) - _side_normal(side) * t * 0.6, _side_size(side, half * 2.0, 10.0 * unit, t * 0.4), "a47148")
			# house wall behind the starting area for a sense of place
			_visual_box(Vector3(0, 400.0 * unit, half + 600.0 * unit), Vector3(1600.0 * unit, 800.0 * unit, 1000.0 * unit), "e5989b")
		"city":
			var h := 9000.0 * unit
			for side in 4:
				var c := _side_centre(side, half + 100.0 * unit)
				_solid_box(c + Vector3(0, h * 0.5, 0), _side_size(side, half * 2.4, h, 200.0 * unit), "000000", false)
				var count := 14
				for i in count:
					var along := (float(i) / (count - 1) - 0.5) * half * 2.2
					var bh := _rng.randf_range(3000.0, 9000.0) * unit
					var bw := _rng.randf_range(2500.0, 4000.0) * unit
					var pos := c + _side_tangent(side) * along + _side_normal(side) * (bw * 0.5 + 300.0 * unit)
					var hexes := ["8d99ae", "adb5bd", "6d6875", "b5838d", "577590"]
					_visual_box(pos + Vector3(0, bh * 0.5, 0), Vector3(bw, bh, bw), hexes[i % hexes.size()])


func _side_centre(side: int, dist: float) -> Vector3:
	return [Vector3(0, 0, -dist), Vector3(0, 0, dist), Vector3(-dist, 0, 0), Vector3(dist, 0, 0)][side]


func _side_normal(side: int) -> Vector3:
	## Outward-facing normal of the given side.
	return [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT][side]


func _side_tangent(side: int) -> Vector3:
	return Vector3.RIGHT if side < 2 else Vector3.BACK


func _side_size(side: int, along: float, height: float, depth: float) -> Vector3:
	return Vector3(along, height, depth) if side < 2 else Vector3(depth, height, along)


func _solid_box(centre: Vector3, size: Vector3, hex: String, show := true) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = centre
	add_child(body)
	if show:
		var mi := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = size
		m.material = Props.material(hex)
		mi.mesh = m
		body.add_child(mi)


func _visual_box(centre: Vector3, size: Vector3, hex: String) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	m.material = Props.material(hex)
	mi.mesh = m
	mi.position = centre
	add_child(mi)


func _build_ball() -> void:
	ball = Ball.new()
	ball.name = "Ball"
	var r := float(def.start_d) * unit * 0.5
	ball.setup(r, Game.tape_color(), float(def.growth))
	ball.position = Vector3(0, r * 1.05, 0)
	ball.items_root = items_root
	ball.target_finder = _find_target
	add_child(ball)
	ball.picked.connect(_on_picked)
	ball.bumped.connect(_on_bumped)
	ball.dropped.connect(_on_dropped)


func _build_camera() -> void:
	_cam_pivot = Node3D.new()
	add_child(_cam_pivot)
	_spring = SpringArm3D.new()
	_spring.collision_mask = 1
	_spring.rotation_degrees.x = -24.0
	_spring.spring_length = ball.radius * 7.0
	_cam_pivot.add_child(_spring)
	_camera = Camera3D.new()
	_camera.fov = 68.0
	_camera.current = true
	_spring.add_child(_camera)
	_cam_pivot.position = ball.position
	_cam_yaw = 0.0


func _update_camera(delta: float) -> void:
	if not get_tree().paused:
		var turn := Input.get_axis("cam_left", "cam_right")
		_cam_yaw -= turn * 2.4 * delta * _sens()
	var r := ball.radius
	var target := ball.global_position + Vector3.UP * r * 0.6
	_cam_pivot.position = _cam_pivot.position.lerp(target, 1.0 - exp(-12.0 * delta))
	_cam_pivot.rotation.y = _cam_yaw
	ball.cam_yaw = _cam_yaw
	_spring.spring_length = lerpf(_spring.spring_length, r * 7.0 + 3.0 * unit * 10.0, 1.0 - exp(-3.0 * delta))
	_spring.margin = r * 0.3
	_camera.near = maxf(r * 0.04, 0.01)
	_camera.far = half * 8.0
	_sun.directional_shadow_max_distance = r * 90.0
	_shake = maxf(0.0, _shake - delta)
	_camera.h_offset = randf_range(-1.0, 1.0) * _shake * r
	_camera.v_offset = randf_range(-1.0, 1.0) * _shake * r


func _build_bursts() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.95, 0.6)
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 0.8))
	ramp.set_color(1, Color(1, 0.6, 0.85, 0))
	for i in 4:
		var p := CPUParticles3D.new()
		p.emitting = false
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = 14
		p.lifetime = 0.5
		p.mesh = mesh
		p.direction = Vector3.UP
		p.spread = 180.0
		p.color_ramp = ramp
		add_child(p)
		_bursts.append(p)


func _burst(at: Vector3) -> void:
	var p := _bursts[_burst_index]
	_burst_index = (_burst_index + 1) % _bursts.size()
	var r := ball.radius
	p.global_position = at
	p.initial_velocity_min = r * 2.0
	p.initial_velocity_max = r * 4.0
	p.gravity = Vector3(0, -r * 9.0, 0)
	p.scale_amount_min = r * 0.08
	p.scale_amount_max = r * 0.16
	p.restart()
