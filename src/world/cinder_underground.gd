extends Node3D
## The underground rail level beneath Cinder Hollow — the Drain Sector platform:
## a long station with a track pit, rails and sleepers, tunnel mouths at both
## ends, pillars, a parked rail car, warm platform lamps and cold Lifeline glow
## bleeding from the tracks. Greybox; carries the mood and layout.

const WARM := Color(1.0, 0.7, 0.36)
const TEAL := Color(0.31, 0.84, 0.76)
const MAGENTA := Color(1.0, 0.36, 0.48)
const STONE := Color(0.13, 0.14, 0.17)
const BRICK := Color(0.18, 0.15, 0.14)
const METAL := Color(0.3, 0.3, 0.34)


func _ready() -> void:
	_setup_environment()
	_build()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.13, 0.16)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.10, 0.13)
	env.fog_density = 0.035
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build() -> void:
	# Enclosing shell: ceiling and side walls.
	_box(Vector3(30, 0.6, 74), Vector3(0, 6.2, 0), _mat(STONE))
	_box(Vector3(0.6, 7, 74), Vector3(-13, 3, 0), _mat(BRICK))
	_box(Vector3(0.6, 7, 74), Vector3(13, 3, 0), _mat(BRICK))

	# Tunnel mouths at both ends — where the rails vanish into the dark.
	_box(Vector3(8, 5.5, 1), Vector3(-6.5, 2.75, -36), _mat(Color(0.02, 0.02, 0.03)))
	_box(Vector3(8, 5.5, 1), Vector3(-6.5, 2.75, 36), _mat(Color(0.02, 0.02, 0.03)))

	# Platform edge separating the walkway from the track pit.
	_box(Vector3(0.5, 0.9, 68), Vector3(-2.4, 0.45, 0), _mat(STONE))

	# Rails + sleepers + cold Lifeline glow leaking from the track.
	_box(Vector3(0.16, 0.16, 68), Vector3(-5, 0.15, 0), _mat(METAL))
	_box(Vector3(0.16, 0.16, 68), Vector3(-8, 0.15, 0), _mat(METAL))
	for zi in range(-32, 33, 2):
		_box(Vector3(5, 0.12, 0.4), Vector3(-6.5, 0.06, zi), _mat(Color(0.16, 0.12, 0.09)))
	for zi in range(-32, 33, 3):
		var col := TEAL if zi > -18 else MAGENTA
		_box(Vector3(3.2, 0.05, 1.0), Vector3(-6.5, 0.2, zi), _emissive(col, 2.0))

	# Pillars down the platform.
	for zi in range(-30, 31, 9):
		_box(Vector3(0.8, 5, 0.8), Vector3(5, 2.5, zi), _mat(STONE))
		_box(Vector3(0.8, 5, 0.8), Vector3(11, 2.5, zi), _mat(STONE))

	# Warm platform lamps.
	for zi in range(-28, 29, 12):
		_lamp(Vector3(3, 0, zi))

	# A parked, dead rail car.
	_box(Vector3(4, 3, 12), Vector3(-6.5, 1.7, 22), _mat(Color(0.19, 0.17, 0.2)))
	_box(Vector3(3.2, 0.8, 3), Vector3(-6.5, 1.7, 15), _emissive(WARM, 1.2))  # its dim interior light


func _lamp(pos: Vector3) -> void:
	_box(Vector3(0.12, 3, 0.12), pos + Vector3(0, 1.5, 0), _mat(STONE))
	var bulb := SphereMesh.new()
	bulb.radius = 0.14
	bulb.height = 0.28
	_add(bulb, pos + Vector3(0, 3, 0), _emissive(WARM, 2.8))
	var light := OmniLight3D.new()
	light.light_color = WARM
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.position = pos + Vector3(0, 3, 0)
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


const LIT_MAT := preload("res://assets/materials/town_lit.tres")
const EMIS_MAT := preload("res://assets/materials/town_emissive.tres")


func _mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = LIT_MAT.duplicate()
	m.albedo_color = c
	return m


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = EMIS_MAT.duplicate()
	m.albedo_color = c
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
