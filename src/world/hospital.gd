extends Node3D
## The Cinder Hollow hospital interior — once a royal medical hall, now old and
## underfunded. A cold clinical space warmed only in patches: a reception with waiting
## patients, a ward of iron beds, a half-empty pharmacy, and an archive of old records
## that hints at the healer bloodline. Here Arlen's power turns from mending machines
## to mending people — and learns it has a cost.

const Blockout := preload("res://src/player/character_blockout.gd")

const CLINIC := Color(0.30, 0.34, 0.33)
const PALE := Color(0.40, 0.44, 0.42)
const WARM := Color(1.0, 0.74, 0.42)
const COLD := Color(0.55, 0.70, 0.85)
const HEAL := Color(0.45, 0.9, 0.7)
const COPPER := Color(0.45, 0.32, 0.22)

const ROOM_W := 20.0
const ROOM_D := 24.0
const ROOM_H := 4.6

var _worker_wound: MeshInstance3D
var _worker_light: OmniLight3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 21
	_setup_environment()
	_shell()
	_reception()
	_ward()
	_pharmacy()
	_archive()
	set_worker_healed(World.state.get_flag(WorldFacts.Flags.CINDER_HEALED_WORKER))


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.34, 0.40)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.14, 0.18)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _shell() -> void:
	_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), _mat(Color(0.20, 0.22, 0.22)))
	_box(Vector3(ROOM_W, ROOM_H, 0.4), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5), _mat(CLINIC))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(CLINIC))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(CLINIC))
	# Front wall + entrance (+Z).
	_box(Vector3(ROOM_W * 0.5 - 1.3, ROOM_H, 0.4), Vector3(-ROOM_W * 0.25 - 0.65, ROOM_H * 0.5, ROOM_D * 0.5), _mat(CLINIC))
	_box(Vector3(ROOM_W * 0.5 - 1.3, ROOM_H, 0.4), Vector3(ROOM_W * 0.25 + 0.65, ROOM_H * 0.5, ROOM_D * 0.5), _mat(CLINIC))
	_box(Vector3(2.8, 1.0, 0.4), Vector3(0, ROOM_H - 0.5, ROOM_D * 0.5), _mat(CLINIC))
	_box(Vector3(ROOM_W, 0.3, ROOM_D), Vector3(0, ROOM_H, 0), _mat(Color(0.14, 0.16, 0.16)))
	# A partition splitting reception (front) from the ward (back).
	_box(Vector3(ROOM_W - 6, 0.3, 0.3), Vector3(0, ROOM_H - 0.4, 2), _mat(CLINIC.darkened(0.2)))
	# Faded medical symbol on the back wall (a dim cross).
	_box(Vector3(0.4, 2.0, 0.15), Vector3(0, 3.0, -ROOM_D * 0.5 + 0.3), _emissive(Color(0.5, 0.6, 0.55), 0.6))
	_box(Vector3(1.4, 0.5, 0.15), Vector3(0, 3.0, -ROOM_D * 0.5 + 0.3), _emissive(Color(0.5, 0.6, 0.55), 0.6))
	# Cold overhead strips + a couple of failing warm lamps.
	for lp in [Vector3(-4, 0, 6), Vector3(4, 0, 6), Vector3(-4, 0, -3), Vector3(4, 0, -3), Vector3(0, 0, -8)]:
		_strip_light(lp)
	# Copper steam-heating pipes along the walls.
	_pipe(Vector3(-ROOM_W * 0.5 + 0.5, 3.8, -10), Vector3(-ROOM_W * 0.5 + 0.5, 3.8, 10))
	_pipe(Vector3(ROOM_W * 0.5 - 0.5, 3.8, 10), Vector3(ROOM_W * 0.5 - 0.5, 3.8, -10))


func _reception() -> void:
	# A desk with a clerk, and rows of waiting patients on benches.
	_box(Vector3(4.0, 1.1, 1.4), Vector3(4.5, 0.55, 8.5), _mat(Color(0.24, 0.20, 0.16)))
	_box(Vector3(4.2, 0.12, 1.5), Vector3(4.5, 1.15, 8.5), _mat(Color(0.30, 0.24, 0.18)))
	_npc(Vector3(4.5, 0, 9.4), Color(0.30, 0.36, 0.40))  # the clerk
	for i in 4:
		_box(Vector3(3.2, 0.12, 0.6), Vector3(-4.5, 0.5, 9.5 - i * 1.6), _mat(Color(0.22, 0.24, 0.24)))  # bench
		if i < 3:
			_npc(Vector3(-5.2 + i * 0.9, 0, 9.5 - i * 1.6), _coat())  # waiting patient
	_lamp_warm(Vector3(4.5, 0, 7.6))


func _ward() -> void:
	# Two rows of iron beds; most empty, some occupied. One holds an injured worker.
	var zs := [-1.0, -4.0, -7.0, -10.0]
	for i in zs.size():
		_bed(Vector3(-6.5, 0, zs[i]), i == 1)   # left row — [1] is the injured worker
		_bed(Vector3(6.5, 0, zs[i]), false)
		if i == 3:
			_npc(Vector3(6.5, 0, zs[i] + 0.2), _coat())  # a sleeping patient (right row)
	# The injured worker (occupies the flagged left bed).
	var w := Blockout.new()
	w.body_color = Color(0.34, 0.30, 0.30)
	w.accent_color = Color(0.5, 0.2, 0.18)
	w.skin_color = Color(0.7, 0.55, 0.46)
	w.position = Vector3(-6.5, 0.35, -4.0)
	w.rotation.x = -1.4   # lying down
	w.scale = Vector3.ONE * 0.95
	add_child(w)
	# His wound — a dim, angry glow that turns calm and green once Arlen heals him.
	_worker_wound = MeshInstance3D.new()
	var g := SphereMesh.new()
	g.radius = 0.25
	g.height = 0.5
	_worker_wound.mesh = g
	_worker_wound.material_override = _emissive(Color(0.9, 0.25, 0.2), 1.6)
	_worker_wound.position = Vector3(-6.5, 0.8, -4.0)
	add_child(_worker_wound)
	_worker_light = OmniLight3D.new()
	_worker_light.light_color = Color(0.9, 0.3, 0.2)
	_worker_light.light_energy = 0.8
	_worker_light.omni_range = 4.0
	_worker_light.position = Vector3(-6.5, 1.0, -4.0)
	add_child(_worker_light)
	# A broken monitor machine beside him.
	_box(Vector3(0.8, 1.2, 0.6), Vector3(-8.4, 0.6, -4.0), _metal(Color(0.14, 0.14, 0.16)))
	_box(Vector3(0.5, 0.4, 0.1), Vector3(-8.4, 1.1, -3.7), _mat(Color(0.05, 0.06, 0.07)))


func set_worker_healed(on: bool) -> void:
	if _worker_wound == null:
		return
	_worker_wound.material_override = _emissive(HEAL, 2.4) if on else _emissive(Color(0.9, 0.25, 0.2), 1.6)
	_worker_light.light_color = HEAL if on else Color(0.9, 0.3, 0.2)
	_worker_light.light_energy = 1.4 if on else 0.8


func _pharmacy() -> void:
	# A dispensary at the back-left, shelves half bare — the district is short on medicine.
	_box(Vector3(0.6, 3.0, 6.0), Vector3(-ROOM_W * 0.5 + 0.6, 1.5, -8), _mat(CLINIC.darkened(0.2)))
	for sy in [1.0, 1.8, 2.6]:
		_box(Vector3(0.8, 0.08, 6.0), Vector3(-ROOM_W * 0.5 + 0.9, sy, -8), _mat(Color(0.22, 0.24, 0.24)))
		for i in 8:
			if _rng.randf() > 0.55:
				continue  # a gap on the shelf
			_box(Vector3(0.2, 0.4, 0.2), Vector3(-ROOM_W * 0.5 + 0.9, sy + 0.24, -10.5 + i * 0.7), _emissive(Color(0.4, 0.7, 0.6), 0.7))
	_box(Vector3(2.4, 1.0, 1.0), Vector3(-7.5, 0.5, -8), _mat(Color(0.24, 0.20, 0.16)))  # counter
	_npc(Vector3(-7.5, 0, -7.0), Color(0.28, 0.34, 0.38))  # the apothecary


func _archive() -> void:
	# A records nook at the back-right: filing cabinets, ledgers, a sealed stair down.
	for i in 4:
		_box(Vector3(1.0, 2.0, 0.7), Vector3(6.0 + i * 1.2, 1.0, -ROOM_D * 0.5 + 1.0), _metal(Color(0.20, 0.20, 0.22)))
	_box(Vector3(1.4, 0.9, 1.0), Vector3(8.5, 0.7, -8.5), _mat(Color(0.24, 0.20, 0.16)))       # a desk with a ledger
	_box(Vector3(0.7, 0.05, 0.5), Vector3(8.5, 1.16, -8.5), _emissive(Color(0.8, 0.78, 0.66), 0.4))  # open record
	# The sealed stair down to the basement (locked for now).
	_box(Vector3(2.4, 0.2, 3.0), Vector3(8.5, 0.1, -6), _mat(Color(0.16, 0.16, 0.18)))
	_box(Vector3(2.6, 2.2, 0.3), Vector3(8.5, 1.1, -4.6), _metal(Color(0.12, 0.12, 0.14)))     # barred door
	_conduit(Vector3(8.5, 0, -11), 4.0, Color(0.5, 0.6, 0.55))


# --- helpers ---------------------------------------------------------------

func _bed(pos: Vector3, occupied_marker: bool) -> void:
	_box(Vector3(1.6, 0.5, 3.0), pos + Vector3(0, 0.3, 0), _metal(Color(0.20, 0.20, 0.22)))
	_box(Vector3(1.5, 0.2, 2.8), pos + Vector3(0, 0.6, 0), _mat(Color(0.5, 0.52, 0.5) if not occupied_marker else Color(0.34, 0.30, 0.30)))
	_box(Vector3(1.2, 0.2, 0.5), pos + Vector3(0, 0.72, 1.2), _mat(Color(0.6, 0.62, 0.6)))     # pillow
	# A drip stand.
	_box(Vector3(0.06, 1.8, 0.06), pos + Vector3(0.9, 0.9, 1.0), _metal(Color(0.3, 0.3, 0.32)))


func _coat() -> Color:
	var c := [Color(0.30, 0.30, 0.34), Color(0.36, 0.30, 0.26), Color(0.28, 0.32, 0.36), Color(0.34, 0.28, 0.30)]
	return c[_rng.randi() % c.size()]


func _npc(pos: Vector3, coat: Color) -> void:
	var n := Blockout.new()
	n.body_color = coat
	n.accent_color = Color(0.16, 0.16, 0.18)
	n.skin_color = Color(0.72, 0.57, 0.47)
	n.position = pos
	n.rotation.y = _rng.randf_range(-PI, PI)
	add_child(n)


func _strip_light(pos: Vector3) -> void:
	_box(Vector3(1.6, 0.1, 0.4), pos + Vector3(0, ROOM_H - 0.2, 0), _emissive(COLD, 1.4))
	var l := OmniLight3D.new()
	l.light_color = COLD
	l.light_energy = 1.1
	l.omni_range = 8.0
	l.position = pos + Vector3(0, ROOM_H - 0.3, 0)
	add_child(l)


func _lamp_warm(pos: Vector3) -> void:
	var b := SphereMesh.new()
	b.radius = 0.14
	b.height = 0.28
	_add(b, pos + Vector3(0, ROOM_H - 0.7, 0), _emissive(WARM, 2.6))
	var l := OmniLight3D.new()
	l.light_color = WARM
	l.light_energy = 1.8
	l.omni_range = 6.0
	l.position = pos + Vector3(0, ROOM_H - 0.7, 0)
	add_child(l)


func _pipe(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var span := (b - a).length()
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.12
	pipe.bottom_radius = 0.12
	pipe.height = span
	var mi := MeshInstance3D.new()
	mi.mesh = pipe
	mi.material_override = _metal(COPPER.darkened(0.2))
	add_child(mi)
	var up := Vector3.UP if absf((b - a).normalized().dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	mi.look_at_from_position(mid, b, up)
	mi.rotate_object_local(Vector3(1, 0, 0), PI * 0.5)


func _conduit(pos: Vector3, height: float, color: Color) -> void:
	_box(Vector3(0.18, height, 0.18), pos + Vector3(0, height * 0.5, 0), _metal(Color(0.16, 0.16, 0.18)))
	_box(Vector3(0.07, height, 0.07), pos + Vector3(0.07, height * 0.5, -0.09), _emissive(color, 1.6))


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
