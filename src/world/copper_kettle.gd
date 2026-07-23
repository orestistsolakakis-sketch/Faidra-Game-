extends Node3D
## The Copper Kettle — a warm, crowded eating-house in the Central Market. The one
## place in Cinder Hollow that feels warm. Bar, kitchen pass, tables, a fireplace,
## stairs to the rooms above — and a crowd whose size and mood shift with the hour
## (quiet workers at breakfast; a packed room at midday; low talk and arguments at
## night). Greybox, dressed to feel lived-in.

const Blockout := preload("res://src/player/character_blockout.gd")

const WARM := Color(1.0, 0.72, 0.38)
const FIRE := Color(1.0, 0.45, 0.18)
const WOOD := Color(0.24, 0.16, 0.10)
const PLASTER := Color(0.30, 0.24, 0.19)
const BRASS := Color(0.55, 0.42, 0.20)

const ROOM_W := 16.0
const ROOM_D := 18.0
const ROOM_H := 4.6

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4
	_setup_environment()
	_shell()
	_fireplace(Vector3(-ROOM_W * 0.5 + 0.6, 0, -4))
	_bar()
	_kitchen()
	_tables()
	_stairs()
	_populate(World.clock.part_of_day())


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.04, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40, 0.28, 0.20)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.14, 0.08)
	env.fog_density = 0.01
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _shell() -> void:
	_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), _mat(WOOD.darkened(0.3)))       # plank floor
	_box(Vector3(ROOM_W, ROOM_H, 0.4), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(PLASTER))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(PLASTER))
	# Front wall with the doorway to the market (+Z).
	_box(Vector3(ROOM_W * 0.5 - 1.2, ROOM_H, 0.4), Vector3(-ROOM_W * 0.25 - 0.6, ROOM_H * 0.5, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(ROOM_W * 0.5 - 1.2, ROOM_H, 0.4), Vector3(ROOM_W * 0.25 + 0.6, ROOM_H * 0.5, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(2.6, 1.0, 0.4), Vector3(0, ROOM_H - 0.5, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(ROOM_W, 0.3, ROOM_D), Vector3(0, ROOM_H, 0), _mat(WOOD.darkened(0.4)))       # ceiling
	for bx in [-4.5, 0.0, 4.5]:
		_box(Vector3(0.35, 0.35, ROOM_D), Vector3(bx, ROOM_H - 0.3, 0), _mat(WOOD.darkened(0.15)))
	# Warm hanging lamps over the room.
	for lp in [Vector3(-3, 0, 2), Vector3(3, 0, 2), Vector3(-3, 0, -4), Vector3(3, 0, -4), Vector3(0, 0, -1)]:
		_hang_lamp(lp)


func _fireplace(pos: Vector3) -> void:
	_box(Vector3(0.6, 2.6, 3.0), pos + Vector3(0, 1.3, 0), _mat(Color(0.16, 0.13, 0.11)))
	_box(Vector3(0.4, 1.2, 1.6), pos + Vector3(0.35, 0.7, 0), _emissive(FIRE, 3.0))
	_plume(pos + Vector3(0.35, 1.6, 0), Color(1.0, 0.5, 0.2, 0.8), true, 8, 0.06)
	var l := OmniLight3D.new()
	l.light_color = FIRE
	l.light_energy = 2.6
	l.omni_range = 8.0
	l.position = pos + Vector3(0.6, 1.0, 0)
	add_child(l)


func _bar() -> void:
	# An L of counter along the right wall with stools, a back-shelf of bottles.
	var bx := ROOM_W * 0.5 - 2.2
	_box(Vector3(1.2, 1.1, 10.0), Vector3(bx, 0.55, -1), _mat(WOOD))
	_box(Vector3(1.4, 0.12, 10.2), Vector3(bx, 1.15, -1), _mat(WOOD.darkened(0.2)))
	_box(Vector3(0.5, 2.4, 10.0), Vector3(bx + 1.4, 1.2, -1), _mat(WOOD.darkened(0.35)))   # back shelf
	for i in 8:
		var bz := 3.0 - i * 1.1
		_box(Vector3(0.2, 0.6, 0.2), Vector3(bx + 1.3, 1.9, bz), _emissive(Color(0.4, 0.6, 0.35), 1.2))  # bottles glinting
	for i in 5:
		var sz := 2.5 - i * 1.2
		_box(Vector3(0.4, 0.7, 0.4), Vector3(bx - 1.2, 0.35, sz), _metal(Color(0.16, 0.12, 0.08)))  # stools
	# The barkeep behind the counter.
	_npc(Vector3(bx + 0.7, 0, 1.0), Color(0.5, 0.36, 0.22), 1.0)


func _kitchen() -> void:
	# A hot kitchen pass at the back with a stove, steam, and hanging pots.
	var kz := -ROOM_D * 0.5 + 1.6
	_box(Vector3(8, 1.2, 0.4), Vector3(2, 0.6, kz + 1.2), _mat(WOOD.darkened(0.2)))          # pass counter
	_box(Vector3(2.4, 1.4, 1.6), Vector3(3.5, 0.7, kz), _metal(Color(0.14, 0.12, 0.11)))     # stove
	_box(Vector3(1.4, 0.4, 1.0), Vector3(3.5, 1.4, kz), _emissive(FIRE, 2.2))                # hot plate
	_plume(Vector3(3.5, 1.8, kz), Color(0.85, 0.85, 0.8, 0.16), false, 12, 0.5)
	for i in 4:
		_box(Vector3(0.35, 0.4, 0.35), Vector3(1.0 + i * 0.7, 3.4, kz + 0.2), _metal(BRASS.darkened(0.2)))  # hanging pots
	_npc(Vector3(2.5, 0, kz - 0.3), Color(0.42, 0.30, 0.24), 1.0)  # the cook


func _tables() -> void:
	for tp in [Vector3(-3, 0, 3), Vector3(-3, 0, -1), Vector3(-4, 0, -5), Vector3(1, 0, 4), Vector3(0, 0, -6)]:
		_box(Vector3(1.8, 0.12, 1.8), tp + Vector3(0, 0.85, 0), _mat(WOOD))
		_box(Vector3(0.25, 0.85, 0.25), tp + Vector3(0, 0.42, 0), _mat(WOOD.darkened(0.3)))
		for cx in [-1.1, 1.1]:
			_box(Vector3(0.5, 0.5, 0.5), tp + Vector3(cx, 0.25, 0), _mat(WOOD.darkened(0.2)))  # stools
		# A small candle on each table.
		_box(Vector3(0.1, 0.2, 0.1), tp + Vector3(0, 1.0, 0), _emissive(WARM, 2.2))


func _stairs() -> void:
	# Stairs up to the rooms above (visual — the upstairs is Phase-later).
	var sx := -ROOM_W * 0.5 + 1.4
	for i in 7:
		_box(Vector3(2.4, 0.25, 1.0), Vector3(sx, 0.15 + i * 0.35, ROOM_D * 0.5 - 1.5 - i * 0.9), _mat(WOOD.darkened(0.25)))
	_box(Vector3(0.15, 2.2, 6.0), Vector3(sx + 1.3, 1.4, ROOM_D * 0.5 - 4), _mat(WOOD.darkened(0.4)))


func _populate(part: String) -> void:
	# Crowd size and mood by time of day. The named seats used for rumours live in the
	# scene (CopperKettle.tscn); these are the ambient regulars filling the room.
	var count := 3
	match part:
		"morning": count = 4
		"afternoon": count = 9
		"evening": count = 7
		_: count = 3   # night — near empty
	var spots := [
		Vector3(-3, 0, 3.9), Vector3(-3, 0, 2.1), Vector3(-3, 0, -0.1), Vector3(-4, 0, -4.1),
		Vector3(1, 0, 4.9), Vector3(1, 0, 3.1), Vector3(0, 0, -5.1), Vector3(2.8, 0, 1.6),
		Vector3(2.8, 0, 0.4), Vector3(2.8, 0, -0.8)]
	for i in mini(count, spots.size()):
		_npc(spots[i], _coat(), 1.0)
	# At night a pair stand near the fire, mid-argument.
	if part == "evening" or part == "night":
		_npc(Vector3(-3.5, 0, -6.2), Color(0.42, 0.24, 0.22), 1.0)
		_npc(Vector3(-2.4, 0, -6.4), Color(0.24, 0.26, 0.34), 1.0)


func _coat() -> Color:
	var c := [Color(0.5, 0.36, 0.22), Color(0.34, 0.30, 0.26), Color(0.28, 0.30, 0.36), Color(0.46, 0.32, 0.30)]
	return c[_rng.randi() % c.size()]


# --- helpers ---------------------------------------------------------------

func _npc(pos: Vector3, coat: Color, s: float) -> void:
	var n := Blockout.new()
	n.body_color = coat
	n.accent_color = Color(0.14, 0.12, 0.12)
	n.skin_color = Color(0.72, 0.57, 0.47)
	n.position = pos
	n.rotation.y = _rng.randf_range(-PI, PI)
	n.scale = Vector3.ONE * s
	add_child(n)


func _hang_lamp(pos: Vector3) -> void:
	_box(Vector3(0.05, 0.7, 0.05), pos + Vector3(0, ROOM_H - 0.35, 0), _metal(Color(0.12, 0.10, 0.08)))
	var b := SphereMesh.new()
	b.radius = 0.16
	b.height = 0.32
	_add(b, pos + Vector3(0, ROOM_H - 0.7, 0), _emissive(WARM, 3.0))
	var l := OmniLight3D.new()
	l.light_color = WARM
	l.light_energy = 2.2
	l.omni_range = 6.5
	l.position = pos + Vector3(0, ROOM_H - 0.7, 0)
	add_child(l)


func _plume(pos: Vector3, col: Color, emissive: bool, amount: int, size: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 2.8
	p.position = pos
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 14.0
	mat.initial_velocity_min = 0.4
	mat.initial_velocity_max = 0.8
	mat.gravity = Vector3(0, 0.2, 0)
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
	m.roughness = 0.5
	m.metallic = 0.8
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
