class_name Ball
extends RigidBody3D
## The player's sticky tape ball. Physics rotation is locked; rolling is shown by spinning `clump`,
## which also carries every stuck-on prop.

signal picked(item: StaticBody3D)
signal bumped(strength: float)
signal dropped(item: StaticBody3D)

const LAYER_BALL := 8
const MAX_ATTACHED := 260
const PICK_RATIO := 0.7  ## props up to this fraction of the ball's diameter can be picked up
const SPEED_RADII := 5.5  ## top speed in ball radii per second

var radius := 1.0
var min_radius := 1.0
var growth := 0.34
var cam_yaw := 0.0
var input_enabled := false
var autopilot := false
var items_root: Node3D  ## where dropped props are returned to
var target_finder: Callable  ## (from, limit, ignored: Dictionary, now: float) -> StaticBody3D, used by autopilot

var clump: Node3D
var _core: MeshInstance3D
var _shape: SphereShape3D
var _pickup_query: PhysicsShapeQueryParameters3D
var _pickup_shape: SphereShape3D
var _attached: Array[StaticBody3D] = []
var _prev_speed := 0.0
var _bump_cooldown := 0.0

var _ap_target: StaticBody3D
var _ap_retarget := 0.0
var _ap_clock := 0.0
var _ap_best_dist := INF
var _ap_progress := 0.0
var _ap_ignored := {}  ## instance id -> clock time until which the target is skipped
var _ap_escape := 0.0
var _ap_escape_dir := Vector3.ZERO


func setup(start_radius: float, color: Color, growth_rate: float) -> void:
	radius = start_radius
	min_radius = start_radius
	growth = growth_rate
	lock_rotation = true
	mass = 1.0
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	collision_layer = LAYER_BALL
	collision_mask = 1 | Props.LAYER_SOLID
	var pm := PhysicsMaterial.new()
	pm.friction = 0.0  # rotation is locked, so the ball slides; the controller provides all traction
	pm.bounce = 0.2
	physics_material_override = pm

	_shape = SphereShape3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = _shape
	add_child(cs)

	clump = Node3D.new()
	clump.name = "Clump"
	add_child(clump)
	_core = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 32
	sm.rings = 16
	_core.mesh = sm
	_core.material_override = _tape_material(color)
	clump.add_child(_core)

	_pickup_shape = SphereShape3D.new()
	_pickup_query = PhysicsShapeQueryParameters3D.new()
	_pickup_query.shape = _pickup_shape
	_pickup_query.collision_mask = Props.LAYER_PICKABLE
	_pickup_query.collide_with_areas = false

	body_entered.connect(_on_body_entered)
	_apply_radius(0.0)


func diameter() -> float:
	return radius * 2.0


func pick_limit() -> float:
	return diameter() * PICK_RATIO


func _physics_process(delta: float) -> void:
	_bump_cooldown -= delta
	var input := Vector2.ZERO
	if input_enabled:
		input = _autopilot_input(delta) if autopilot else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Basis(Vector3.UP, cam_yaw) * Vector3(input.x, 0.0, input.y)
	var vel_h := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var desired := dir * radius * SPEED_RADII
	var response := 3.2 if dir.length_squared() > 0.01 else 1.6
	apply_central_force((desired - vel_h) * mass * response)

	var speed := vel_h.length()
	if speed > 0.0001:
		var axis := Vector3.UP.cross(vel_h / speed)
		clump.basis = (Basis(axis, speed * delta / radius) * clump.basis).orthonormalized()
	_prev_speed = speed

	if input_enabled:
		_pickup_query.transform = Transform3D(Basis.IDENTITY, global_position)
		for hit in get_world_3d().direct_space_state.intersect_shape(_pickup_query, 48):
			var body = hit.collider
			if body is StaticBody3D and _can_pick(body):
				_attach(body)


func _can_pick(body: StaticBody3D) -> bool:
	return body.get_meta("state", "") == "world" and body.collision_layer == Props.LAYER_PICKABLE \
		and float(body.get_meta("size", INF)) <= pick_limit()


func _attach(item: StaticBody3D) -> void:
	item.set_meta("state", "attached")
	item.collision_layer = 0
	(item.get_node("Shape") as CollisionShape3D).set_deferred("disabled", true)
	var centre := item.global_position + Vector3.UP * float(item.get_meta("height")) * 0.5
	var local := clump.to_local(centre)
	if local.length_squared() < 0.0001:
		local = Vector3.UP
	item.reparent.call_deferred(clump, true)
	# Centre the prop just under the surface so it pokes out and the ball looks lumpy.
	var depth := radius * 0.95
	item.set_meta("stick_depth", depth)
	var target := local.normalized() * depth
	_settle.call_deferred(item, target)
	_attached.append(item)
	var old := radius
	radius = pow(pow(radius, 3.0) + _volume_gain(item), 1.0 / 3.0)
	_apply_radius(radius - old)
	picked.emit(item)


## Ball volume (as r³) gained by sticking on this prop: a fraction of the prop's bounding sphere.
func _volume_gain(item: StaticBody3D) -> float:
	return growth * pow(float(item.get_meta("size")) * 0.5, 3.0)


func _settle(item: StaticBody3D, target: Vector3) -> void:
	if not is_instance_valid(item) or item.get_parent() != clump:
		return
	# Tween so the prop's centre sits on the target point.
	var offset := item.basis * Vector3.UP * float(item.get_meta("height")) * 0.5
	var tw := item.create_tween()
	tw.tween_property(item, "position", target - offset, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_radius(grow_by: float) -> void:
	_shape.radius = radius
	_pickup_shape.radius = radius * 1.12 + 0.02
	_core.scale = Vector3.ONE * radius
	if grow_by > 0.0:
		global_position += Vector3.UP * grow_by
	_prune_buried()


## Frees props that are now completely inside the core, and the oldest ones beyond the cap.
func _prune_buried() -> void:
	var keep: Array[StaticBody3D] = []
	for item in _attached:
		if not is_instance_valid(item):
			continue
		var half := float(item.get_meta("size")) * 0.5
		if item.get_parent() == clump and float(item.get_meta("stick_depth", 0.0)) + half < radius * 0.97:
			item.queue_free()
		else:
			keep.append(item)
	while keep.size() > MAX_ATTACHED:
		keep.pop_front().queue_free()
	_attached = keep


func _on_body_entered(body: Node) -> void:
	if _bump_cooldown > 0.0 or not (body is StaticBody3D):
		return
	# Low clutter is just rolled over; only walls and tall props knock things loose.
	if body.has_meta("height") and float(body.get_meta("height")) < radius:
		return
	var strength := _prev_speed / radius
	if strength < 4.5:
		return
	_bump_cooldown = 0.7
	bumped.emit(strength)
	if not _attached.is_empty():
		_drop_last.call_deferred()


func _drop_last() -> void:
	while not _attached.is_empty():
		var item: StaticBody3D = _attached.pop_back()
		if is_instance_valid(item) and item.get_parent() == clump:
			_detach(item)
			return


func _detach(item: StaticBody3D) -> void:
	var size: float = item.get_meta("size")
	radius = maxf(min_radius, pow(maxf(pow(radius, 3.0) - _volume_gain(item), 0.0), 1.0 / 3.0))
	_apply_radius(0.0)
	item.set_meta("state", "flying")
	item.reparent(items_root, true)
	var away := -Vector3(linear_velocity.x, 0, linear_velocity.z)
	if away.length_squared() < 0.0001:
		away = Vector3.FORWARD
	var land := global_position + away.normalized() * (radius * 2.5 + size)
	land.y = 0.0
	item.rotation = Vector3(0, randf() * TAU, 0)
	var start := item.global_position
	var peak := (start + land) * 0.5 + Vector3.UP * (radius * 2.0)
	var tw := item.create_tween()
	tw.tween_method(func(t: float) -> void:
		item.global_position = start.lerp(peak, t).lerp(peak.lerp(land, t), t), 0.0, 1.0, 0.45)
	tw.tween_callback(func() -> void:
		(item.get_node("Shape") as CollisionShape3D).disabled = false
		item.collision_layer = Props.LAYER_PICKABLE
		item.set_meta("state", "world"))
	dropped.emit(item)


func _tape_material(color: Color) -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		var band := 0.82 + 0.18 * (0.5 + 0.5 * sin(y * 0.6))
		var stripe := (y / 8) % 2 == 0
		for x in 64:
			var c := color * (band * (1.0 if stripe else 0.9))
			c.a = 1.0
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(4, 4, 1)
	m.roughness = 0.35
	m.metallic = 0.15
	m.rim_enabled = true
	m.rim = 0.4
	return m


# ---------------------------------------------------------------- autopilot (automated playtests)

func _autopilot_input(delta: float) -> Vector2:
	_ap_clock += delta
	if _ap_escape > 0.0:
		_ap_escape -= delta
		return _world_to_input(_ap_escape_dir)
	_ap_retarget -= delta
	if _ap_retarget <= 0.0 or not is_instance_valid(_ap_target) or not _can_pick(_ap_target):
		_ap_retarget = 0.4
		var previous := _ap_target
		_ap_target = target_finder.call(global_position, pick_limit(), _ap_ignored, _ap_clock) if target_finder.is_valid() else null
		if _ap_target != previous:
			_ap_best_dist = INF
			_ap_progress = 0.0
	if _ap_target == null:
		return _world_to_input(-global_position.normalized())
	var to := _ap_target.global_position - global_position
	to.y = 0.0
	# Give up on targets we stop closing in on (blocked by solid props), then wiggle free.
	var dist := to.length()
	if dist < _ap_best_dist - radius * 0.5:
		_ap_best_dist = dist
		_ap_progress = 0.0
	else:
		_ap_progress += delta
	if _ap_progress > 2.0:
		_ap_ignored[_ap_target.get_instance_id()] = _ap_clock + 10.0
		_ap_target = null
		_ap_progress = 0.0
		_ap_escape = 0.9
		_ap_escape_dir = (-to.normalized()).rotated(Vector3.UP, randf_range(-1.2, 1.2))
	return _world_to_input(to.normalized())


func _world_to_input(dir: Vector3) -> Vector2:
	var local := Basis(Vector3.UP, cam_yaw).inverse() * dir
	return Vector2(local.x, local.z).limit_length(1.0)
