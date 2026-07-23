extends Node3D
## A small worker's home in the Residential District — the first house the player can
## simply walk into and find someone's ordinary life. One room: a cold stove, a
## table, a bed, a child's things, a wall of photographs. The heater is dead and the
## room is cold-lit blue; if Arlen mends it, warmth (and warm light) returns. Not a
## quest hub — just a life, with one small thing that can be made better.

const Blockout := preload("res://src/player/character_blockout.gd")

const WARM := Color(1.0, 0.72, 0.38)
const COLD := Color(0.45, 0.55, 0.75)
const WOOD := Color(0.24, 0.16, 0.10)
const PLASTER := Color(0.34, 0.30, 0.26)

const ROOM_W := 10.0
const ROOM_D := 11.0
const ROOM_H := 3.6

var _heater_core: MeshInstance3D
var _heater_light: OmniLight3D
var _warm_light: OmniLight3D
var _cold_light: OmniLight3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	var warm := World.state.get_flag(WorldFacts.Flags.CINDER_HOME_HEATER_FIXED)
	_setup_environment(warm)
	_shell()
	_kitchen()
	_sleeping()
	_belongings()
	_heater(Vector3(3.4, 0, -3.2))
	set_heater_running(warm)


func _setup_environment(warm: bool) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.28, 0.24) if warm else Color(0.22, 0.28, 0.38)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.10, 0.13)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _shell() -> void:
	_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), _mat(WOOD.darkened(0.3)))
	_box(Vector3(ROOM_W, ROOM_H, 0.4), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(PLASTER))
	_box(Vector3(0.4, ROOM_H, ROOM_D), Vector3(ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat(PLASTER))
	# Front wall + doorway to the lane (+Z).
	_box(Vector3(ROOM_W * 0.5 - 1.1, ROOM_H, 0.4), Vector3(-ROOM_W * 0.25 - 0.55, ROOM_H * 0.5, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(ROOM_W * 0.5 - 1.1, ROOM_H, 0.4), Vector3(ROOM_W * 0.25 + 0.55, ROOM_H * 0.5, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(2.2, 0.9, 0.4), Vector3(0, ROOM_H - 0.45, ROOM_D * 0.5), _mat(PLASTER))
	_box(Vector3(ROOM_W, 0.3, ROOM_D), Vector3(0, ROOM_H, 0), _mat(WOOD.darkened(0.4)))
	# One bare bulb hanging in the middle — the only working light before the heater.
	_warm_light = OmniLight3D.new()
	_warm_light.light_color = WARM
	_warm_light.light_energy = 1.3
	_warm_light.omni_range = 7.0
	_warm_light.position = Vector3(0, ROOM_H - 0.6, 0.5)
	add_child(_warm_light)
	var b := SphereMesh.new()
	b.radius = 0.12
	b.height = 0.24
	_add(b, Vector3(0, ROOM_H - 0.6, 0.5), _emissive(WARM, 2.2))


func _kitchen() -> void:
	# A cold stove, a small table set for a meal, a shelf of tins.
	_box(Vector3(1.6, 1.2, 1.2), Vector3(-3.6, 0.6, -3.6), _metal(Color(0.13, 0.12, 0.12)))     # stove
	_box(Vector3(0.6, 0.9, 0.6), Vector3(-3.6, 2.4, -4.4), _metal(Color(0.1, 0.1, 0.11)))       # flue
	_box(Vector3(1.8, 0.12, 1.2), Vector3(-3.2, 0.85, -1.0), _mat(WOOD))                        # table
	for cx in [-0.9, 0.9]:
		_box(Vector3(0.12, 0.85, 0.12), Vector3(-3.2 + cx, 0.42, -1.0), _mat(WOOD.darkened(0.3)))
	_box(Vector3(0.5, 0.5, 0.5), Vector3(-3.6, 0.25, 0.2), _mat(WOOD.darkened(0.2)))            # stool
	for sy in [1.4, 2.1]:
		_box(Vector3(0.4, 0.06, 2.4), Vector3(-ROOM_W * 0.5 + 0.4, sy, -2.0), _mat(WOOD.darkened(0.2)))
		for i in 4:
			_box(Vector3(0.2, 0.3, 0.2), Vector3(-ROOM_W * 0.5 + 0.4, sy + 0.2, -3.0 + i * 0.7), _metal(Color(0.3, 0.26, 0.18)))
	# The resident, at her table.
	_npc(Vector3(-2.4, 0, -1.0), Color(0.46, 0.30, 0.34))


func _sleeping() -> void:
	# A bed in the corner, a chest at its foot, a coat on a peg.
	_box(Vector3(2.4, 0.5, 3.4), Vector3(3.2, 0.35, 2.6), _mat(WOOD.darkened(0.2)))
	_box(Vector3(2.2, 0.3, 3.2), Vector3(3.2, 0.65, 2.6), _mat(Color(0.34, 0.26, 0.28)))       # blanket
	_box(Vector3(1.4, 0.24, 0.6), Vector3(3.2, 0.75, 4.0), _mat(Color(0.5, 0.46, 0.42)))       # pillow
	_box(Vector3(1.6, 0.7, 0.9), Vector3(3.2, 0.35, 0.6), _mat(WOOD.darkened(0.3)))            # chest
	_box(Vector3(0.5, 1.2, 0.15), Vector3(4.6, 1.6, 1.5), _mat(Color(0.30, 0.24, 0.30)))       # hung coat


func _belongings() -> void:
	# A wall of framed photographs (front wall), a letter on the table, a child's toy.
	for i in 5:
		var px := -3.5 + i * 1.4
		_box(Vector3(0.5, 0.6, 0.06), Vector3(px, 2.3, -ROOM_D * 0.5 + 0.3), _mat(Color(0.5, 0.45, 0.38)))
		_box(Vector3(0.38, 0.46, 0.08), Vector3(px, 2.3, -ROOM_D * 0.5 + 0.28), _emissive(Color(0.6, 0.58, 0.5), 0.3))
	_box(Vector3(0.4, 0.03, 0.3), Vector3(-3.2, 0.92, -0.7), _emissive(Color(0.85, 0.82, 0.7), 0.4))  # letter
	# A small wooden toy on the floor near the bed.
	_box(Vector3(0.3, 0.2, 0.5), Vector3(2.0, 0.1, 3.0), _mat(Color(0.5, 0.32, 0.18)))
	_box(Vector3(0.12, 0.12, 0.12), Vector3(1.7, 0.06, 3.2), _mat(Color(0.4, 0.28, 0.16)))


func _heater(pos: Vector3) -> void:
	# A cast-iron heater against the wall — dead cold, ribbed, a dark core.
	_box(Vector3(0.5, 1.6, 2.0), pos + Vector3(0, 0.8, 0), _metal(Color(0.12, 0.12, 0.13)))
	for i in 5:
		_box(Vector3(0.6, 0.1, 0.12), pos + Vector3(0, 0.4 + i * 0.28, 0.85), _metal(Color(0.10, 0.10, 0.11)))
	_heater_core = MeshInstance3D.new()
	var core := BoxMesh.new()
	core.size = Vector3(0.3, 0.9, 0.9)
	_heater_core.mesh = core
	_heater_core.material_override = _mat(Color(0.08, 0.07, 0.07))
	_heater_core.position = pos + Vector3(-0.15, 0.8, 0)
	add_child(_heater_core)
	_heater_light = OmniLight3D.new()
	_heater_light.light_color = WARM
	_heater_light.light_energy = 0.0
	_heater_light.omni_range = 7.0
	_heater_light.light_specular = 1.4
	_heater_light.position = pos + Vector3(0, 0.9, 0)
	add_child(_heater_light)
	# A cold draught light near the door before it's fixed, killed once warm.
	_cold_light = OmniLight3D.new()
	_cold_light.light_color = COLD
	_cold_light.light_energy = 0.9
	_cold_light.omni_range = 8.0
	_cold_light.position = Vector3(0, 1.6, ROOM_D * 0.5 - 1.0)
	add_child(_cold_light)


func set_heater_running(on: bool) -> void:
	if _heater_core == null:
		return
	_heater_core.material_override = _emissive(Color(1.0, 0.42, 0.16), 3.0) if on else _mat(Color(0.08, 0.07, 0.07))
	_heater_light.light_energy = 2.6 if on else 0.0
	_warm_light.light_energy = 1.9 if on else 1.3
	_cold_light.light_energy = 0.0 if on else 0.9
	if on and not has_node("HeaterSmoke"):
		_plume(_heater_core.position + Vector3(0, 0.8, 0), Color(1.0, 0.5, 0.2, 0.7), true, 8, 0.05)


# --- helpers ---------------------------------------------------------------

func _npc(pos: Vector3, coat: Color) -> void:
	var n := Blockout.new()
	n.body_color = coat
	n.accent_color = Color(0.14, 0.12, 0.12)
	n.skin_color = Color(0.72, 0.57, 0.47)
	n.position = pos
	n.rotation.y = 2.6
	add_child(n)


func _plume(pos: Vector3, col: Color, emissive: bool, amount: int, size: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 2.6
	p.position = pos
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 12.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 0.7
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
	p.name = "HeaterSmoke"
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
