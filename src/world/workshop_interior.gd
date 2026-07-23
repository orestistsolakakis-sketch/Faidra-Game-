extends Node3D
## Arlen's workshop — the first fully enterable interior in Cinder Hollow. A single
## warm, cluttered room: a forge, workbenches, racks of parts, hanging tools, steam
## pipes overhead, and the broken machine at its heart that Arlen can repair. Built
## from primitives (greybox) but dressed to read as a lived-in, working space.

const WARM := Color(1.0, 0.72, 0.38)
const FORGE := Color(1.0, 0.5, 0.2)
const TEAL := Color(0.31, 0.84, 0.76)
const WOOD := Color(0.22, 0.15, 0.09)
const IRON := Color(0.12, 0.12, 0.14)
const BRICK := Color(0.24, 0.17, 0.14)

const ROOM_W := 14.0
const ROOM_D := 16.0
const ROOM_H := 5.0

var _machine_core: MeshInstance3D
var _machine_light: OmniLight3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 12
	_setup_environment()
	_shell()
	_forge(Vector3(-5.5, 0, -6.5))
	_benches()
	_racks()
	_pipes()
	_machine(Vector3(3.5, 0, -4.0))
	# Reflect saved progress: if the machine was already fixed, show it running.
	if World.state.get_flag(WorldFacts.Flags.CINDER_WORKSHOP_MACHINE_FIXED):
		set_machine_running(true)


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.26, 0.20)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.18, 0.12, 0.08)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _shell() -> void:
	# Floor, four walls, a beamed ceiling, and the way back out to the street (+Z wall).
	_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), _mat(Color(0.10, 0.09, 0.08)))
	_box(Vector3(ROOM_W, ROOM_H, 0.4), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5), _mat(BRICK))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(BRICK))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(BRICK))
	# Front wall with a doorway gap in the middle.
	_box(Vector3(ROOM_W * 0.5 - 1.2, ROOM_H, 0.4), Vector3(-ROOM_W * 0.25 - 0.6, ROOM_H * 0.5, ROOM_D * 0.5), _mat(BRICK))
	_box(Vector3(ROOM_W * 0.5 - 1.2, ROOM_H, 0.4), Vector3(ROOM_W * 0.25 + 0.6, ROOM_H * 0.5, ROOM_D * 0.5), _mat(BRICK))
	_box(Vector3(2.6, 1.2, 0.4), Vector3(0, ROOM_H - 0.6, ROOM_D * 0.5), _mat(BRICK))  # lintel above door
	_box(Vector3(ROOM_W, 0.3, ROOM_D), Vector3(0, ROOM_H, 0), _mat(Color(0.08, 0.07, 0.06)))  # ceiling
	for bx in [-4.0, 0.0, 4.0]:
		_box(Vector3(0.4, 0.4, ROOM_D), Vector3(bx, ROOM_H - 0.35, 0), _mat(WOOD.darkened(0.2)))  # beams
	# A couple of warm hanging work-lamps.
	_hang_lamp(Vector3(-3, 0, 2))
	_hang_lamp(Vector3(4, 0, 4))


func _forge(pos: Vector3) -> void:
	_box(Vector3(2.4, 1.4, 2.0), pos + Vector3(0, 0.7, 0), _mat(Color(0.14, 0.12, 0.11)))
	_box(Vector3(1.4, 0.8, 1.2), pos + Vector3(0, 1.0, 0.2), _emissive(FORGE, 3.0))          # coals
	_box(Vector3(1.0, 3.2, 1.0), pos + Vector3(0, 3.0, -0.6), _metal(Color(0.10, 0.10, 0.11)))  # flue
	_plume(pos + Vector3(0, 1.6, 0.2), Color(1.0, 0.5, 0.2, 0.8), true, 10, 0.06)
	var l := OmniLight3D.new()
	l.light_color = FORGE
	l.light_energy = 3.0
	l.omni_range = 7.0
	l.position = pos + Vector3(0, 1.2, 0.2)
	add_child(l)


func _benches() -> void:
	for bp in [Vector3(-5.5, 0, 3.5), Vector3(-5.5, 0, 6.0), Vector3(5.5, 0, 5.5)]:
		_box(Vector3(2.6, 0.15, 1.1), bp + Vector3(0, 0.95, 0), _mat(WOOD))
		for lx in [-1.1, 1.1]:
			for lz in [-0.45, 0.45]:
				_box(Vector3(0.12, 0.95, 0.12), bp + Vector3(lx, 0.47, lz), _mat(WOOD.darkened(0.3)))
		# Scattered parts + a clamped vice.
		_box(Vector3(0.3, 0.3, 0.3), bp + Vector3(_rng.randf_range(-0.8, 0.8), 1.2, 0), _metal(Color(0.3, 0.24, 0.16)))
		_box(Vector3(0.25, 0.4, 0.25), bp + Vector3(0.9, 1.25, 0.3), _metal(Color(0.2, 0.2, 0.22)))


func _racks() -> void:
	# Shelving of parts along the left wall.
	for sy in [1.0, 2.0, 3.0]:
		_box(Vector3(0.6, 0.08, 6.0), Vector3(-ROOM_W * 0.5 + 0.6, sy, 2.5), _mat(WOOD.darkened(0.2)))
		for i in 6:
			var pz := 0.2 + i * 1.0
			_box(Vector3(0.35, 0.35, 0.35), Vector3(-ROOM_W * 0.5 + 0.6, sy + 0.25, pz), _metal(Color(0.28, 0.22, 0.15).lerp(IRON, _rng.randf())))
	# Hanging tools on the back wall.
	for i in 8:
		var tx := -5.0 + i * 1.3
		_box(Vector3(0.12, _rng.randf_range(0.5, 1.0), 0.06), Vector3(tx, 3.4, -ROOM_D * 0.5 + 0.35), _metal(Color(0.22, 0.22, 0.24)))


func _pipes() -> void:
	# Steam pipes running along the ceiling with a slow leak.
	_pipe(Vector3(-ROOM_W * 0.5 + 1, 4.4, -6), Vector3(-ROOM_W * 0.5 + 1, 4.4, 6))
	_pipe(Vector3(-5, 4.6, 6), Vector3(5, 4.6, 6))
	_pipe(Vector3(5, 4.6, 6), Vector3(5, 1.2, 6))
	_plume(Vector3(0, 4.4, 6), Color(0.85, 0.88, 0.92, 0.12), false, 10, 0.5)


func _machine(pos: Vector3) -> void:
	# The broken machine at the heart of the workshop — Arlen's first repair.
	_box(Vector3(3.0, 1.0, 2.4), pos + Vector3(0, 0.5, 0), _metal(Color(0.13, 0.13, 0.15)))     # base
	_box(Vector3(2.2, 2.6, 1.8), pos + Vector3(0, 2.2, 0), _metal(Color(0.16, 0.15, 0.17)))     # body
	for gx in [-0.7, 0.7]:
		var gear := CylinderMesh.new()
		gear.top_radius = 0.6
		gear.bottom_radius = 0.6
		gear.height = 0.2
		var mi := MeshInstance3D.new()
		mi.mesh = gear
		mi.material_override = _metal(Color(0.25, 0.2, 0.14))
		mi.position = pos + Vector3(gx, 2.4, 0.95)
		mi.rotation.x = PI * 0.5
		add_child(mi)
	# The core: dark and dead until Arlen repairs it.
	var core := SphereMesh.new()
	core.radius = 0.5
	core.height = 1.0
	_machine_core = MeshInstance3D.new()
	_machine_core.mesh = core
	_machine_core.material_override = _mat(Color(0.06, 0.08, 0.09))
	_machine_core.position = pos + Vector3(0, 2.4, 0)
	add_child(_machine_core)
	_machine_light = OmniLight3D.new()
	_machine_light.light_color = TEAL
	_machine_light.light_energy = 0.0
	_machine_light.omni_range = 8.0
	_machine_light.position = pos + Vector3(0, 2.4, 0)
	add_child(_machine_light)


func set_machine_running(on: bool) -> void:
	if _machine_core == null:
		return
	_machine_core.material_override = _emissive(TEAL, 3.0) if on else _mat(Color(0.06, 0.08, 0.09))
	_machine_light.light_energy = 3.2 if on else 0.0


# --- small helpers ---------------------------------------------------------

func _hang_lamp(pos: Vector3) -> void:
	_box(Vector3(0.05, 0.9, 0.05), pos + Vector3(0, ROOM_H - 0.45, 0), _metal(IRON))
	var b := SphereMesh.new()
	b.radius = 0.16
	b.height = 0.32
	_add(b, pos + Vector3(0, ROOM_H - 0.9, 0), _emissive(WARM, 3.0))
	var l := OmniLight3D.new()
	l.light_color = WARM
	l.light_energy = 2.4
	l.omni_range = 7.0
	l.position = pos + Vector3(0, ROOM_H - 0.9, 0)
	add_child(l)


func _pipe(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var span := (b - a).length()
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.14
	pipe.bottom_radius = 0.14
	pipe.height = span
	var mi := MeshInstance3D.new()
	mi.mesh = pipe
	mi.material_override = _metal(Color(0.30, 0.22, 0.15))
	add_child(mi)
	var up := Vector3.UP if absf((b - a).normalized().dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	mi.look_at_from_position(mid, b, up)
	mi.rotate_object_local(Vector3(1, 0, 0), PI * 0.5)


func _plume(pos: Vector3, col: Color, emissive: bool, amount: int, size: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 2.8
	p.position = pos
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 0.9
	mat.gravity = Vector3(0, 0.25, 0)
	mat.scale_min = size * 0.5
	mat.scale_max = size
	p.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = col
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	if emissive:
		qmat.emission_enabled = true
		qmat.emission = col
		qmat.emission_energy_multiplier = 3.0
	quad.material = qmat
	p.draw_pass_1 = quad
	add_child(p)
	p.emitting = true


func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_add(mesh, pos, mat)


func _add(mesh: Mesh, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.metallic = 0.8
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
