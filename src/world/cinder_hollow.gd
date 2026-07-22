extends Node3D
## Greybox of the Level 01 opening district (docs/levels/01_CINDER_HOLLOW.md):
## a lamplit street running from Arlen's workshop (behind spawn) down to the dead
## freight lift (ahead), lined with buildings, market stalls, Lifeline glow and
## static NPC blockouts for life. Placeholder geometry carrying the composition,
## palette and lighting until real assets exist (docs/ART_DIRECTION.md).

const Blockout := preload("res://src/player/character_blockout.gd")
const Spinner := preload("res://src/world/spinner.gd")

const WARM := Color(1.0, 0.72, 0.38)
const FORGE := Color(1.0, 0.5, 0.2)
const TEAL := Color(0.31, 0.84, 0.76)
const MAGENTA := Color(1.0, 0.36, 0.48)
const STONE := Color(0.14, 0.16, 0.20)
const BRICK := Color(0.22, 0.16, 0.13)
const COPPER := Color(0.45, 0.32, 0.22)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 71
	_setup_environment()
	_build_district()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.19, 0.25)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.15, 0.20)
	env.fog_density = 0.02
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_strength = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_district() -> void:
	# Ground street (dark wet stone).
	_box(Vector3(16, 0.4, 60), Vector3(0, -0.2, -3), _mat(Color(0.09, 0.10, 0.13)))

	# Buildings down both sides.
	for i in range(-4, 5):
		var z := i * 6.0
		_building(Vector3(-9.5, 0, z))
		_building(Vector3(9.5, 0, z))

	# Arlen's workshop (behind spawn, +Z) — a warm forge glow marks home.
	_workshop(Vector3(0, 0, 16))

	# The dead freight lift (ahead, -Z) — the objective, lit cold and failing.
	_lift(Vector3(0, 0, -24))

	# Warm lamp posts down the street.
	for i in range(-3, 4):
		_lamp(Vector3(-3.6, 0, i * 6.0))
		_lamp(Vector3(3.6, 0, i * 6.0))

	# Lifelines: healthy teal near home, turning unstable magenta toward the lift.
	for i in range(-16, 12):
		var z := i * 1.5
		var color := TEAL if z > -12 else MAGENTA
		_lifeline(Vector3(0, 0.03, z), color)

	# Market stalls mid-street.
	_stall(Vector3(-4.5, 0, 2))
	_stall(Vector3(4.5, 0, -4))
	_stall(Vector3(-4.5, 0, -10))

	# Static NPCs — the district's people.
	var npc_colors := [Color(0.3, 0.26, 0.22), Color(0.26, 0.28, 0.3), Color(0.34, 0.3, 0.26), Color(0.24, 0.24, 0.28)]
	var npc_spots := [
		Vector3(-3, 0, 3), Vector3(3.2, 0, -3), Vector3(-2.5, 0, -9),
		Vector3(2.8, 0, 6), Vector3(-3.4, 0, -14), Vector3(1.5, 0, 12),
	]
	for i in npc_spots.size():
		_npc(npc_spots[i], npc_colors[i % npc_colors.size()])

	# Bram — Arlen's friend — stands near his interaction spot, in a warmer coat.
	_npc(Vector3(2.2, 0, 4.2), Color(0.5, 0.34, 0.2))

	# --- Market: extra stalls, braziers, and the two merchants you can talk to ---
	_stall(Vector3(-4.5, 0, -1))
	_stall(Vector3(4.5, 0, 1))
	_brazier(Vector3(-2.6, 0, -1))
	_brazier(Vector3(2.6, 0, -5))
	_npc(Vector3(-4.2, 0, 1.5), Color(0.55, 0.4, 0.22))   # Fen, the steam-bread seller
	_npc(Vector3(4.2, 0, -3.5), Color(0.4, 0.36, 0.3))    # Old Rennick, the scrap dealer

	# --- Residential quarter (a courtyard off the main street) ---
	_residential(Vector3(-13, 0, -2))

	# --- Expand into a city grid: avenues, cross-streets, blocks, crowds ---
	_expand_city()
	_rail_station(Vector3(24, 0, -8))

	# --- Ambient life: spinning fans and drifting steam ---
	_fan(Vector3(-6.7, 4.5, 6), Vector3(0, 0, 1))
	_fan(Vector3(6.7, 5.5, -8), Vector3(0, 0, 1))
	_fan(Vector3(-6.7, 3.5, -14), Vector3(0, 0, 1))
	for z in [8.0, 0.0, -8.0, -16.0]:
		_steam(Vector3(_rng.randf_range(-3.0, 3.0), 0.2, z))
	_steam(Vector3(0, 0.5, -22))  # steam bleeding from the dead lift


func _fan(pos: Vector3, axis: Vector3) -> void:
	var spinner := Spinner.new()
	spinner.spin_axis = axis
	spinner.speed = _rng.randf_range(2.0, 4.0)
	spinner.position = pos
	# Housing ring + four blades.
	var housing := CylinderMesh.new()
	housing.top_radius = 1.3
	housing.bottom_radius = 1.3
	housing.height = 0.15
	var ring := MeshInstance3D.new()
	ring.mesh = housing
	ring.material_override = _mat(STONE)
	ring.rotation.x = PI * 0.5
	spinner.add_child(ring)
	for i in 4:
		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 1.1, 0.05)
		blade.mesh = bm
		blade.material_override = _mat(COPPER)
		blade.rotation.z = i * PI * 0.5
		spinner.add_child(blade)
	add_child(spinner)


func _steam(pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 18
	p.lifetime = 2.6
	p.position = pos
	p.local_coords = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 12.0
	mat.initial_velocity_min = 0.8
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, 0.3, 0)
	mat.scale_min = 0.6
	mat.scale_max = 1.6
	p.process_material = mat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.7, 0.7)
	var qmat := StandardMaterial3D.new()
	qmat.albedo_color = Color(0.8, 0.85, 0.9, 0.12)
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = qmat
	p.draw_pass_1 = quad

	add_child(p)
	p.emitting = true


func _expand_city() -> void:
	# Cross-streets (roads running along X) at a few Z lines, lined with buildings.
	for z in [8.0, -16.0, 24.0]:
		_cross_street(z)
	# Avenues (roads running along Z) to the east and west, lined with buildings.
	for x in [-22.0, 22.0]:
		_avenue(x)
	# Fill the outer blocks with clustered buildings (keep the main street clear).
	_fill_blocks()
	# A city crowd — pedestrians scattered through the wider district.
	for _i in 12:
		var px := _rng.randf_range(-34.0, 34.0)
		var pz := _rng.randf_range(-34.0, 30.0)
		if absf(px) < 7.0:
			continue
		_npc(Vector3(px, 0, pz), Color(_rng.randf_range(0.22, 0.42), _rng.randf_range(0.2, 0.36), _rng.randf_range(0.22, 0.42)))


func _cross_street(z: float) -> void:
	_box(Vector3(78, 0.06, 7), Vector3(0, 0.02, z), _mat(Color(0.08, 0.09, 0.11)))  # road surface
	for xi in range(-34, 35, 8):
		if absi(xi) < 6:
			continue
		_building(Vector3(xi, 0, z + 6.5))
		_building(Vector3(xi, 0, z - 6.5))
	_lamp(Vector3(-11, 0, z + 3.4))
	_lamp(Vector3(11, 0, z - 3.4))


func _avenue(x: float) -> void:
	_box(Vector3(7, 0.06, 78), Vector3(x, 0.02, 0), _mat(Color(0.08, 0.09, 0.11)))
	for zi in range(-34, 35, 8):
		_building(Vector3(x + 6.5, 0, zi))
		_building(Vector3(x - 6.5, 0, zi))
	_lamp(Vector3(x + 3.4, 0, -12))
	_lamp(Vector3(x - 3.4, 0, 12))


func _fill_blocks() -> void:
	for bx in [-32.0, -12.0, 12.0, 32.0]:
		for bz in [-30.0, -8.0, 16.0, 30.0]:
			if absf(bx) < 10.0 and absf(bz) < 20.0:
				continue  # leave the central playable corridor alone
			for _k in 2:
				var p := Vector3(bx + _rng.randf_range(-5.0, 5.0), 0, bz + _rng.randf_range(-5.0, 5.0))
				if absf(p.x) < 7.0:
					continue
				_building(p)


func _rail_station(pos: Vector3) -> void:
	_box(Vector3(10, 7, 8), pos + Vector3(0, 3.5, 0), _mat(Color(0.16, 0.15, 0.17)))
	_box(Vector3(3, 4, 0.5), pos + Vector3(0, 2, -4.1), _mat(Color(0.03, 0.03, 0.05)))   # dark entrance mouth
	_box(Vector3(6.5, 1, 0.3), pos + Vector3(0, 5.6, -4.1), _emissive(TEAL, 1.6))         # glowing sign
	var glow := OmniLight3D.new()
	glow.light_color = TEAL
	glow.light_energy = 2.0
	glow.omni_range = 7.5
	glow.position = pos + Vector3(0, 1.6, -3.0)
	add_child(glow)


func _building(base: Vector3) -> void:
	var height := _rng.randf_range(5.0, 10.0)
	var depth := _rng.randf_range(4.0, 6.0)
	_box(Vector3(5.5, height, depth), base + Vector3(0, height * 0.5, 0), _mat(BRICK.lerp(STONE, _rng.randf())))
	for _w in _rng.randi_range(2, 5):
		var side := 1.0 if _rng.randf() > 0.5 else -1.0
		var wy := _rng.randf_range(1.5, height - 1.0)
		var wz := _rng.randf_range(-depth * 0.4, depth * 0.4)
		_box(Vector3(0.1, 0.5, 0.5), base + Vector3(side * 2.76, wy, wz), _emissive(WARM, 2.2))


func _workshop(pos: Vector3) -> void:
	_box(Vector3(7, 6, 5), pos + Vector3(0, 3, 0), _mat(Color(0.24, 0.18, 0.15)))
	# Open doorway framing a forge.
	_box(Vector3(2.4, 3, 0.3), pos + Vector3(0, 1.5, -2.6), _mat(Color(0.05, 0.05, 0.06)))
	_box(Vector3(1.2, 1.0, 1.0), pos + Vector3(0, 0.6, -3.4), _emissive(FORGE, 2.6))
	var glow := OmniLight3D.new()
	glow.light_color = FORGE
	glow.light_energy = 2.6
	glow.omni_range = 8.0
	glow.position = pos + Vector3(0, 1.4, -3.2)
	add_child(glow)


func _lift(pos: Vector3) -> void:
	# A tall frame + platform, dark and dead, with a failing cold panel.
	for x in [-2.2, 2.2]:
		_box(Vector3(0.4, 7, 0.4), pos + Vector3(x, 3.5, -2.2), _mat(STONE))
		_box(Vector3(0.4, 7, 0.4), pos + Vector3(x, 3.5, 2.2), _mat(STONE))
	_box(Vector3(5, 0.4, 5), pos + Vector3(0, 0.2, 0), _mat(Color(0.1, 0.11, 0.13)))
	_box(Vector3(4, 3, 0.3), pos + Vector3(0, 2, -2.4), _mat(Color(0.12, 0.12, 0.14)))
	_box(Vector3(1.2, 0.5, 0.2), pos + Vector3(0, 2, -2.55), _emissive(MAGENTA, 2.0))
	var light := OmniLight3D.new()
	light.light_color = MAGENTA
	light.light_energy = 1.6
	light.omni_range = 9.0
	light.position = pos + Vector3(0, 2.5, 0)
	add_child(light)


func _stall(pos: Vector3) -> void:
	for x in [-0.9, 0.9]:
		_box(Vector3(0.1, 2, 0.1), pos + Vector3(x, 1, 0), _mat(COPPER))
	_box(Vector3(2.2, 0.1, 1.4), pos + Vector3(0, 2, 0), _mat(Color(0.35, 0.15, 0.15)))  # awning
	_box(Vector3(2.0, 0.8, 1.0), pos + Vector3(0, 0.9, 0), _mat(Color(0.2, 0.16, 0.12)))  # counter


func _brazier(pos: Vector3) -> void:
	_box(Vector3(0.5, 0.5, 0.5), pos + Vector3(0, 0.25, 0), _mat(STONE))
	var fire := SphereMesh.new()
	fire.radius = 0.22
	fire.height = 0.44
	_add(fire, pos + Vector3(0, 0.6, 0), _emissive(FORGE, 3.2))
	var light := OmniLight3D.new()
	light.light_color = FORGE
	light.light_energy = 2.6
	light.omni_range = 6.5
	light.position = pos + Vector3(0, 0.7, 0)
	add_child(light)


func _lamp(pos: Vector3) -> void:
	_box(Vector3(0.12, 3.0, 0.12), pos + Vector3(0, 1.5, 0), _mat(STONE))
	var bulb := SphereMesh.new()
	bulb.radius = 0.15
	bulb.height = 0.3
	_add(bulb, pos + Vector3(0, 3.0, 0), _emissive(WARM, 3.0))
	var light := OmniLight3D.new()
	light.light_color = WARM
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.position = pos + Vector3(0, 3.0, 0)
	add_child(light)


func _lifeline(pos: Vector3, color: Color) -> void:
	_box(Vector3(0.26, 0.05, 1.2), pos, _emissive(color, 2.0))


func _npc(pos: Vector3, coat: Color) -> void:
	var n := Blockout.new()
	n.body_color = coat
	n.accent_color = Color(0.12, 0.12, 0.14)
	n.skin_color = Color(0.7, 0.55, 0.45)
	n.position = pos
	n.rotation.y = _rng.randf_range(-PI, PI)
	add_child(n)


func _kid(pos: Vector3, coat: Color) -> void:
	var n := Blockout.new()
	n.body_color = coat
	n.accent_color = Color(0.14, 0.14, 0.16)
	n.skin_color = Color(0.72, 0.57, 0.47)
	n.position = pos
	n.rotation.y = _rng.randf_range(-PI, PI)
	n.scale = Vector3(0.62, 0.62, 0.62)  # child-sized
	add_child(n)


func _residential(o: Vector3) -> void:
	# Homes stacked around a small courtyard.
	_building(o + Vector3(-5, 0, 0))
	_building(o + Vector3(5, 0, -2))
	_building(o + Vector3(0, 0, -6))

	# A laundry line strung across the courtyard (rope + hanging cloth).
	_box(Vector3(9, 0.04, 0.04), o + Vector3(0, 3.2, 0), _mat(Color(0.1, 0.08, 0.06)))
	var cloth := [Color(0.6, 0.55, 0.5), Color(0.4, 0.45, 0.5), Color(0.55, 0.4, 0.35)]
	for i in range(-3, 4):
		_box(Vector3(0.5, 0.7, 0.04), o + Vector3(i * 1.2, 2.75, 0), _mat(cloth[(i + 3) % 3]))

	# A warm brazier the families gather at.
	_brazier(o + Vector3(0, 0, 1.5))

	# Dara (mother you can talk to) and neighbours; two kids playing.
	_npc(o + Vector3(0, 0, 2.2), Color(0.45, 0.30, 0.35))   # Dara
	_npc(o + Vector3(-2.4, 0, 1.2), Color(0.32, 0.28, 0.40))
	_npc(o + Vector3(2.6, 0, -0.8), Color(0.30, 0.34, 0.30))
	_kid(o + Vector3(-1.1, 0, 2.6), Color(0.55, 0.30, 0.30))
	_kid(o + Vector3(1.3, 0, 2.3), Color(0.30, 0.42, 0.55))


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


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
