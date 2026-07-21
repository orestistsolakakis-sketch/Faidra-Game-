extends Node3D
## Builds a stylized greybox of a Cinder Hollow street: a WorldEnvironment carrying
## the art-direction lighting identity (dark cool base, glow/bloom, haze, filmic
## tone) plus procedural props — buildings, pipes, warm lamp posts, a central
## machine, and cold Lifeline glow running through the ground. Placeholder geometry;
## the LIGHTING identity is the real deliverable here (see docs/ART_DIRECTION.md).

const WARM := Color(1.0, 0.72, 0.38)
const TEAL := Color(0.31, 0.84, 0.76)
const VIOLET := Color(0.66, 0.55, 1.0)
const STONE := Color(0.14, 0.16, 0.20)
const BRICK := Color(0.20, 0.16, 0.14)
const COPPER := Color(0.45, 0.32, 0.22)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1337
	_setup_environment()
	_build_street()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.20, 0.26)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	# Cold haze for depth and mood.
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.16, 0.22)
	env.fog_density = 0.015
	env.fog_sky_affect = 0.0
	# Bloom so Lifelines and lamps radiate.
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_strength = 1.1

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_street() -> void:
	# Buildings down both sides of the street (street runs along Z, at x=0).
	for i in range(-3, 5):
		var z := i * 8.0
		_building(Vector3(-9.0, 0, z))
		_building(Vector3(9.0, 0, z))

	# Warm lamp posts at intervals.
	for i in range(-2, 4):
		var z := i * 9.0
		_lamp(Vector3(-3.5, 0, z))
		_lamp(Vector3(3.5, 0, z))

	# Cold Lifeline glow running down the centre of the street (teal), with a
	# violet branch — the magic threading through the ground.
	for i in range(-20, 20):
		var z := i * 1.5
		_lifeline(Vector3(0, 0.02, z), TEAL)
	for i in range(-6, 6):
		_lifeline(Vector3(i * 1.2, 0.02, i * 1.2 * 0.4), VIOLET)

	# Copper pipes along the building bases.
	for i in range(-3, 4):
		_pipe(Vector3(-6.6, 0.6, i * 8.0))
		_pipe(Vector3(6.6, 0.6, i * 8.0))

	# A central machine (echoes the Overfed Core) with cold emission + its own light.
	_machine(Vector3(0, 0, -10))


func _building(base: Vector3) -> void:
	var height := _rng.randf_range(4.0, 9.0)
	var depth := _rng.randf_range(4.0, 6.0)
	_box(Vector3(5.0, height, depth), base + Vector3(0, height * 0.5, 0), _mat(BRICK.lerp(STONE, _rng.randf())))
	# A few warm lit windows.
	var windows := _rng.randi_range(2, 5)
	for _w in windows:
		var wx := (5.0 * 0.5 - 0.4) * (1.0 if _rng.randf() > 0.5 else -1.0)
		var wy := _rng.randf_range(1.5, height - 1.0)
		var wz := _rng.randf_range(-depth * 0.4, depth * 0.4)
		_box(Vector3(0.1, 0.5, 0.5), base + Vector3(wx * 1.001, wy, wz), _emissive(WARM, 2.5))


func _lamp(pos: Vector3) -> void:
	_box(Vector3(0.12, 3.0, 0.12), pos + Vector3(0, 1.5, 0), _mat(STONE))  # post
	var bulb := SphereMesh.new()
	bulb.radius = 0.16
	bulb.height = 0.32
	_add(bulb, pos + Vector3(0, 3.0, 0), _emissive(WARM, 3.0))
	var light := OmniLight3D.new()
	light.light_color = WARM
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position = pos + Vector3(0, 3.0, 0)
	add_child(light)


func _lifeline(pos: Vector3, color: Color) -> void:
	_box(Vector3(0.28, 0.05, 1.2), pos, _emissive(color, 2.2))


func _pipe(pos: Vector3) -> void:
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.16
	pipe.bottom_radius = 0.16
	pipe.height = 8.0
	var mi := MeshInstance3D.new()
	mi.mesh = pipe
	mi.material_override = _mat(COPPER)
	mi.position = pos
	mi.rotation = Vector3(PI * 0.5, 0, 0)  # lay it along Z
	add_child(mi)


func _machine(pos: Vector3) -> void:
	_box(Vector3(3.0, 3.5, 3.0), pos + Vector3(0, 1.75, 0), _mat(STONE))
	_box(Vector3(3.05, 1.2, 0.2), pos + Vector3(0, 2.0, 1.5), _emissive(TEAL, 2.8))  # glowing panel
	var light := OmniLight3D.new()
	light.light_color = TEAL
	light.light_energy = 3.0
	light.omni_range = 12.0
	light.position = pos + Vector3(0, 2.6, 2.0)
	add_child(light)


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
	m.roughness = 0.85
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
