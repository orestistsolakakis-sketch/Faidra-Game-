extends Node3D
## Greybox of the Level 01 district (docs/levels/01_CINDER_HOLLOW.md), built to
## read as a real, lived-in town rather than a cluster of boxes: an actual road
## network with sidewalks, crosswalks and intersections; distinct neighbourhoods
## (a market high street, apartment blocks, quiet residential lanes, a park, empty
## lots and a station square); buildings of varied size and height spaced along the
## roads with grass, trees and yards between them; and a spread-out population of
## children, teenagers, adults and elders — many of them strolling the streets.
## Placeholder primitives carrying composition, palette and life until real assets
## exist (docs/ART_DIRECTION.md).

const Blockout := preload("res://src/player/character_blockout.gd")
const Wanderer := preload("res://src/world/npc_wanderer.gd")
const Spinner := preload("res://src/world/spinner.gd")

const WARM := Color(1.0, 0.72, 0.38)
const FORGE := Color(1.0, 0.5, 0.2)
const TEAL := Color(0.31, 0.84, 0.76)
const MAGENTA := Color(1.0, 0.36, 0.48)
const STONE := Color(0.14, 0.16, 0.20)
const BRICK := Color(0.22, 0.16, 0.13)
const COPPER := Color(0.45, 0.32, 0.22)
const GROUND := Color(0.06, 0.07, 0.06)
const ROAD := Color(0.07, 0.08, 0.10)
const WALK := Color(0.20, 0.21, 0.24)
const GRASS := Color(0.10, 0.16, 0.09)
const LINE := Color(0.55, 0.55, 0.45)

# The three neighbourhoods' coat palettes, so each area reads as its own people.
const COATS_MARKET := [Color(0.55, 0.4, 0.22), Color(0.4, 0.36, 0.3), Color(0.5, 0.34, 0.2)]
const COATS_RESID := [Color(0.45, 0.30, 0.35), Color(0.32, 0.28, 0.40), Color(0.30, 0.34, 0.30), Color(0.5, 0.42, 0.30)]
const COATS_DOWN := [Color(0.24, 0.26, 0.32), Color(0.30, 0.28, 0.26), Color(0.22, 0.24, 0.30)]

var _rng := RandomNumberGenerator.new()

# Road grid. Vertical roads run along Z; horizontal roads run along X.
const V_ROADS := [-20.0, 0.0, 20.0]
const H_ROADS := [8.0, -12.0, -26.0]
const Z_MIN := -34.0
const Z_MAX := 22.0
const X_MIN := -42.0
const X_MAX := 42.0
const ROAD_W := 6.0


func _ready() -> void:
	_rng.seed = 71
	_setup_environment()
	_build_town()


func _setup_environment() -> void:
	# Cinder Hollow at dusk: a cold, smog-choked industrial hollow (Zaun / Dishonored /
	# Lies of P). Deep blue-black base, cool moonlight ambient, thick haze, and strong
	# bloom so the warm lamps and the teal/magenta Lifeline glow read as pools of light.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.24, 0.34)   # cool moonlight fill
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.tonemap_exposure = 1.05

	# Layered haze: thick enough to fade distant buildings into smog.
	env.fog_enabled = true
	env.fog_light_color = Color(0.10, 0.14, 0.20)
	env.fog_light_energy = 0.6
	env.fog_density = 0.022
	env.fog_sky_affect = 0.0

	# Bloom only on the bright, self-lit sources.
	env.glow_enabled = true
	env.glow_intensity = 1.1
	env.glow_bloom = 0.25
	env.glow_strength = 1.2
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

	# Grade: crush blacks a touch, cool it down, drop saturation for that grimy film look.
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 0.88

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_town() -> void:
	_ground()
	_road_network()

	# --- The main street: Arlen's home high street, unchanged fixed beats ---
	_workshop(Vector3(0, 0, 18))                       # home (behind spawn)
	_lift(Vector3(0, 0, -24))                           # objective (ahead)
	_market_row()                                       # stalls, braziers, merchants
	# Lifelines glowing along the main street: healthy teal near home -> magenta ahead.
	for i in range(-18, 14):
		var z := i * 1.5
		_lifeline(Vector3(0, 0.05, z), TEAL if z > -12 else MAGENTA)

	# The named people who anchor the opening (positions match CinderHollow.tscn).
	_npc(Vector3(2.2, 0, 4.2), Color(0.5, 0.34, 0.2))   # Bram
	_npc(Vector3(-4.2, 0, 1.5), Color(0.55, 0.4, 0.22)) # Fen
	_npc(Vector3(4.2, 0, -3.5), Color(0.4, 0.36, 0.3))  # Rennick
	_sick_neighbor(Vector3(-6, 0, -6))                  # the coughing neighbour's door
	# Dara, on her stoop off the market street (matches CinderHollow.tscn).
	_small_home(Vector3(-13, 0, -2))
	_npc(Vector3(-13, 0, 0.2), Color(0.45, 0.30, 0.35))

	# --- Neighbourhoods filling the blocks between the roads ---
	# West residential lane (Dara lives here).
	_residential_block(Vector3(-11, 0, 15), true)
	_residential_block(Vector3(-31, 0, -2), false)
	# Apartment / downtown blocks.
	_downtown_block(Vector3(11, 0, -2))
	_downtown_block(Vector3(-31, 0, 15))
	_downtown_block(Vector3(10, 0, 15))
	# The neighbourhood park.
	_park(Vector3(-11, 0, -20))
	_park(Vector3(31, 0, 15))
	# Empty lots / yards.
	_empty_lot(Vector3(10, 0, -20))
	_empty_lot(Vector3(-31, 0, -20))
	# Station square (east) with its crowd and the underground rail entrance.
	_station_square(Vector3(31, 0, -8))

	# --- Ambient life across the town ---
	_street_crowd()
	_fan(Vector3(-6.7, 4.5, 6), Vector3(0, 0, 1))
	_fan(Vector3(6.7, 5.5, -8), Vector3(0, 0, 1))
	for z in [8.0, 0.0, -8.0, -16.0]:
		_steam(Vector3(_rng.randf_range(-3.0, 3.0), 0.2, z))
	_steam(Vector3(0, 0.5, -22))
	_atmosphere()


func _atmosphere() -> void:
	# Overhead wire-tangle strung down the main street and across the avenues.
	for z in [12.0, 5.0, -2.0, -9.0, -16.0]:
		_cable(Vector3(-6.5, 6.2, z), Vector3(6.5, 5.6, z), 1.4)
	for z in [15.0, -5.0, -20.0]:
		_cable(Vector3(-6.5, 7.4, z + 1.0), Vector3(6.5, 6.8, z - 1.0), 1.2)
	_cable(Vector3(-13.5, 6.0, 4.0), Vector3(-7.0, 5.5, -2.0), 1.0)
	_cable(Vector3(13.5, 6.2, -2.0), Vector3(7.0, 5.6, 4.0), 1.0)

	# Warm string-lights across the market, and glowing shop signs over the street.
	_string_lights(Vector3(-4.6, 4.8, 2.0), Vector3(4.6, 4.8, -1.0), 9, WARM)
	_string_lights(Vector3(-4.6, 4.6, -8.0), Vector3(4.6, 4.6, -11.0), 8, WARM)
	_hanging_sign(Vector3(-6.6, 4.0, 1.0), WARM)
	_hanging_sign(Vector3(6.6, 3.6, -5.0), TEAL)
	_hanging_sign(Vector3(-6.6, 4.2, -9.0), MAGENTA)

	# Lifeline conduits climbing the buildings that flank the main street.
	_conduit(Vector3(-6.9, 0, 6.0), 6.5, TEAL)
	_conduit(Vector3(6.9, 0, -3.0), 5.5, TEAL)
	_conduit(Vector3(-6.9, 0, -12.0), 5.0, MAGENTA)
	_conduit(Vector3(6.9, 0, 10.0), 6.0, TEAL)

	# Rooftop chimneys venting smoke over the district.
	for cp in [Vector3(-10, 8, 14), Vector3(11, 9, 15), Vector3(-31, 10, 15), Vector3(9, 7, -2)]:
		_chimney(cp)

	# Puddles catching the lamplight down the wet street.
	for _i in 14:
		var px := _rng.randf_range(-5.0, 5.0)
		var pz := _rng.randf_range(Z_MIN + 4, Z_MAX - 4)
		_puddle(Vector3(px, 0, pz), _rng.randf_range(0.7, 1.6))

	# Clutter: barrels and crates piled in the market and alleys.
	for bp in [Vector3(-5.4, 0, -2), Vector3(5.4, 0, 3), Vector3(-5.6, 0, -12), Vector3(9.4, 0, -2)]:
		_barrel(bp)
		_barrel(bp + Vector3(0.7, 0, 0.2))
		_crate(bp + Vector3(-0.1, 0, 0.9), _rng.randf_range(0.6, 0.9))
	_crate(Vector3(4.8, 0, 5), 0.8)
	_crate(Vector3(4.8, 0, 5.9), 0.6)
	_crate(Vector3(-4.9, 0, -6), 0.7)


# --------------------------------------------------------------------------
# Ground + roads
# --------------------------------------------------------------------------

func _ground() -> void:
	# One large wet earthen plane under the whole town so gaps aren't void.
	_box(Vector3(X_MAX - X_MIN + 20, 0.2, Z_MAX - Z_MIN + 20), Vector3(0, -0.1, (Z_MAX + Z_MIN) * 0.5), _wet(GROUND))


func _road_network() -> void:
	for x in V_ROADS:
		_road_v(x)
	for z in H_ROADS:
		_road_h(z)
	# Crosswalks + a lamp at every intersection.
	for x in V_ROADS:
		for z in H_ROADS:
			_crosswalks(Vector3(x, 0, z))
			_lamp(Vector3(x + ROAD_W * 0.5 + 0.9, 0, z + ROAD_W * 0.5 + 0.9))
			_lamp(Vector3(x - ROAD_W * 0.5 - 0.9, 0, z - ROAD_W * 0.5 - 0.9))


func _road_v(x: float) -> void:
	var length := Z_MAX - Z_MIN
	var mid := (Z_MAX + Z_MIN) * 0.5
	_box(Vector3(ROAD_W, 0.06, length), Vector3(x, 0.02, mid), _wet(ROAD))
	# Dashed centre line.
	for zi in range(int(Z_MIN) + 2, int(Z_MAX) - 1, 4):
		_box(Vector3(0.18, 0.02, 1.6), Vector3(x, 0.06, float(zi)), _mat(LINE))
	# Raised sidewalks either side.
	_box(Vector3(1.6, 0.16, length), Vector3(x - ROAD_W * 0.5 - 0.8, 0.08, mid), _mat(WALK))
	_box(Vector3(1.6, 0.16, length), Vector3(x + ROAD_W * 0.5 + 0.8, 0.08, mid), _mat(WALK))


func _road_h(z: float) -> void:
	var length := X_MAX - X_MIN
	_box(Vector3(length, 0.06, ROAD_W), Vector3(0, 0.02, z), _wet(ROAD))
	for xi in range(int(X_MIN) + 2, int(X_MAX) - 1, 4):
		_box(Vector3(1.6, 0.02, 0.18), Vector3(float(xi), 0.06, z), _mat(LINE))
	_box(Vector3(length, 0.16, 1.6), Vector3(0, 0.08, z - ROAD_W * 0.5 - 0.8), _mat(WALK))
	_box(Vector3(length, 0.16, 1.6), Vector3(0, 0.08, z + ROAD_W * 0.5 + 0.8), _mat(WALK))


func _crosswalks(c: Vector3) -> void:
	# Zebra stripes on each of the four approaches to an intersection.
	for s in range(-2, 3):
		_box(Vector3(0.5, 0.03, 2.4), c + Vector3(s * 1.0, 0.07, ROAD_W * 0.5 + 1.6), _mat(LINE))
		_box(Vector3(0.5, 0.03, 2.4), c + Vector3(s * 1.0, 0.07, -ROAD_W * 0.5 - 1.6), _mat(LINE))
		_box(Vector3(2.4, 0.03, 0.5), c + Vector3(ROAD_W * 0.5 + 1.6, 0.07, s * 1.0), _mat(LINE))
		_box(Vector3(2.4, 0.03, 0.5), c + Vector3(-ROAD_W * 0.5 - 1.6, 0.07, s * 1.0), _mat(LINE))


# --------------------------------------------------------------------------
# Neighbourhood blocks
# --------------------------------------------------------------------------

func _downtown_block(c: Vector3) -> void:
	# Wider, taller, varied shopfronts and apartments spaced along a frontage,
	# with a couple of gaps (an alley, a side yard) so it isn't a solid wall.
	var xs := [-6.0, -1.5, 3.5, 7.5]
	for i in xs.size():
		if _rng.randf() < 0.18:
			continue  # a gap in the row
		var w := _rng.randf_range(4.0, 6.5)
		var h := _rng.randf_range(6.0, 13.0)
		var d := _rng.randf_range(5.0, 7.0)
		_shop(c + Vector3(xs[i], 0, _rng.randf_range(-1.0, 1.0)), Vector2(w, d), h)
	# A back alley behind the frontage.
	_box(Vector3(0.2, 3, 8), c + Vector3(9.5, 1.5, 0), _mat(STONE))
	_tree(c + Vector3(-8.5, 0, 2))
	# A few residents standing at shopfronts, plus passers-by strolling the block.
	_person(c + Vector3(-3, 0, 3.5), _pick(COATS_DOWN), "adult")
	_person(c + Vector3(5, 0, 3.5), _pick(COATS_DOWN), "elder")
	for _i in 3:
		_wanderer(c + Vector3(_rng.randf_range(-7, 7), 0, _rng.randf_range(2, 5)), _pick(COATS_DOWN), 5.0, "adult")


func _residential_block(c: Vector3, is_dara: bool) -> void:
	# A quiet lane of small, mostly single-storey homes with yards, fences,
	# trees and washing lines — where the families and children live.
	var offsets := [-7.0, -1.0, 5.0]
	for i in offsets.size():
		var pos := c + Vector3(offsets[i], 0, _rng.randf_range(-1.0, 1.0))
		_small_home(pos)
		_fence(pos + Vector3(0, 0, 3.2), 3.6)
		_tree(pos + Vector3(_rng.randf_range(-2.5, 2.5), 0, 4.5))
	# A washing line strung across the lane.
	_box(Vector3(8, 0.04, 0.04), c + Vector3(0, 3.0, 3.5), _mat(Color(0.1, 0.08, 0.06)))
	var cloth := [Color(0.6, 0.55, 0.5), Color(0.4, 0.45, 0.5), Color(0.55, 0.4, 0.35)]
	for j in range(-3, 4):
		_box(Vector3(0.5, 0.7, 0.04), c + Vector3(j * 1.1, 2.55, 3.5), _mat(cloth[(j + 3) % 3]))
	_brazier(c + Vector3(0, 0, 5.5))

	# Families: adults near the braziers, kids and teens playing in the lane.
	_person(c + Vector3(0, 0, 6.0), _pick(COATS_RESID), "adult")
	_wanderer(c + Vector3(-3, 0, 6.5), _pick(COATS_RESID), 4.0, "child")
	_wanderer(c + Vector3(3, 0, 6.5), _pick(COATS_RESID), 4.0, "child")
	_wanderer(c + Vector3(1, 0, 8.0), _pick(COATS_RESID), 5.0, "teen")
	_person(c + Vector3(-4, 0, 7.0), Color(0.4, 0.4, 0.42), "elder")


func _park(c: Vector3) -> void:
	# A green square: grass, a ring of trees, benches, a path, and people at rest.
	_box(Vector3(15, 0.05, 15), c + Vector3(0, 0.03, 0), _mat(GRASS))
	# A crossing gravel path.
	_box(Vector3(2.2, 0.06, 15), c + Vector3(0, 0.05, 0), _mat(Color(0.16, 0.15, 0.13)))
	_box(Vector3(15, 0.06, 2.2), c + Vector3(0, 0.05, 0), _mat(Color(0.16, 0.15, 0.13)))
	for a in range(8):
		var ang := a * TAU / 8.0
		_tree(c + Vector3(cos(ang) * 6.0, 0, sin(ang) * 6.0))
	_bench(c + Vector3(-3.5, 0, 2.0), true)
	_bench(c + Vector3(3.5, 0, -2.0), true)
	_lamp(c + Vector3(0, 0, 0))
	# People at rest and children at play.
	_person(c + Vector3(-3.5, 0, 1.5), _pick(COATS_RESID), "adult")  # sitting-ish
	_person(c + Vector3(3.5, 0, -2.5), Color(0.42, 0.42, 0.44), "elder")
	for _i in 3:
		_wanderer(c + Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-5, 5)), _pick(COATS_RESID), 5.0, "child")
	_wanderer(c + Vector3(2, 0, 4), _pick(COATS_RESID), 5.0, "teen")


func _empty_lot(c: Vector3) -> void:
	# A vacant gravel lot: fence, a couple of stacked crates, one figure passing.
	_box(Vector3(14, 0.05, 12), c + Vector3(0, 0.03, 0), _mat(Color(0.11, 0.11, 0.10)))
	_fence(c + Vector3(0, 0, 6), 12)
	_fence(c + Vector3(-7, 0, 0), 12, true)
	for _i in 4:
		var p := c + Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-4, 4))
		_box(Vector3(1.0, 1.0, 1.0), p + Vector3(0, 0.5, 0), _mat(COPPER))
	_tree(c + Vector3(5, 0, -4))
	_wanderer(c + Vector3(0, 0, 0), _pick(COATS_DOWN), 5.0, "adult")


func _station_square(c: Vector3) -> void:
	# The town's transit square: a big civic hall + the underground rail entrance,
	# ringed by benches, a market cluster and a milling crowd.
	_box(Vector3(24, 0.05, 22), c + Vector3(0, 0.03, 0), _mat(Color(0.13, 0.13, 0.15)))
	_rail_station(c + Vector3(-7, 0, 4))
	# A large public hall behind the square.
	_box(Vector3(14, 12, 8), c + Vector3(2, 6, -7), _mat(Color(0.18, 0.18, 0.21)))
	for wx in range(-2, 3):
		_box(Vector3(1.0, 6, 0.3), c + Vector3(2 + wx * 2.4, 6, -3.1), _emissive(WARM, 1.6))
	_bench(c + Vector3(-6, 0, -2), false)
	_bench(c + Vector3(6, 0, -2), false)
	_stall(c + Vector3(-8, 0, -4))
	_stall(c + Vector3(8, 0, 2))
	_brazier(c + Vector3(0, 0, -1))
	_lamp(c + Vector3(-9, 0, 6))
	_lamp(c + Vector3(9, 0, 6))
	# A crowd: mixed ages moving through the square.
	for _i in 8:
		var kinds := ["adult", "adult", "teen", "elder", "child"]
		var k: String = kinds[_rng.randi() % kinds.size()]
		_wanderer(c + Vector3(_rng.randf_range(-9, 9), 0, _rng.randf_range(-2, 6)), _pick(COATS_DOWN), 6.0, k)


# --------------------------------------------------------------------------
# The market high street (fixed opening beats)
# --------------------------------------------------------------------------

func _market_row() -> void:
	_stall(Vector3(-4.5, 0, 2))
	_stall(Vector3(4.5, 0, -4))
	_stall(Vector3(-4.5, 0, -10))
	_stall(Vector3(4.5, 0, 1))
	_brazier(Vector3(-2.6, 0, -1))
	_brazier(Vector3(2.6, 0, -5))


func _sick_neighbor(pos: Vector3) -> void:
	_small_home(pos)
	# A dim, sickly window — the coughing behind the door.
	_box(Vector3(0.1, 0.7, 0.7), pos + Vector3(1.55, 1.4, 0), _emissive(MAGENTA, 0.8))


# --------------------------------------------------------------------------
# Building + prop primitives
# --------------------------------------------------------------------------

func _shop(base: Vector3, footprint: Vector2, height: float) -> void:
	var w := footprint.x
	var d := footprint.y
	var wall := BRICK.lerp(STONE, _rng.randf())
	var front := -d * 0.5
	# Main mass + a darker stone plinth and a capping cornice so it reads as built.
	_box(Vector3(w, height, d), base + Vector3(0, height * 0.5, 0), _mat(wall))
	_box(Vector3(w + 0.3, 0.7, d + 0.3), base + Vector3(0, 0.35, 0), _mat(wall.darkened(0.45)))       # plinth
	_box(Vector3(w + 0.4, 0.35, d + 0.4), base + Vector3(0, height + 0.1, 0), _mat(wall.darkened(0.3)))  # cornice
	# A warm, lit shopfront with a frame and an awning over the door.
	_box(Vector3(w * 0.75, 1.7, 0.12), base + Vector3(0, 1.15, front - 0.06), _emissive(WARM, 1.9))
	_box(Vector3(w * 0.8, 0.2, 0.2), base + Vector3(0, 2.1, front - 0.1), _mat(wall.darkened(0.4)))     # frame head
	_box(Vector3(w * 0.55, 0.14, 1.0), base + Vector3(0, 2.0, front - 0.55), _mat(Color(0.32, 0.14, 0.14)))  # awning
	# Upper floors: a divider ledge and framed, lit windows.
	var floors := int((height - 2.0) / 3.0)
	for f in range(floors):
		var fy := 3.0 + f * 3.0
		_box(Vector3(w + 0.15, 0.18, d + 0.15), base + Vector3(0, fy - 0.9, 0), _mat(wall.darkened(0.25)))
		for wx in [-1.0, 1.0]:
			var lit := _rng.randf() > 0.35
			var wpos := base + Vector3(wx * w * 0.26, fy, front - 0.04)
			_box(Vector3(0.72, 0.82, 0.1), wpos, _mat(wall.darkened(0.5)))                    # frame
			_box(Vector3(0.52, 0.62, 0.12), wpos + Vector3(0, 0, -0.03), _emissive(WARM, 1.6) if lit else _mat(Color(0.05, 0.06, 0.08)))


func _small_home(pos: Vector3) -> void:
	# A single-storey home with a pitched roof, framed window, doorstep and a stovepipe.
	var w := _rng.randf_range(3.5, 5.0)
	var d := _rng.randf_range(3.5, 4.5)
	var wall := BRICK.lerp(COPPER, _rng.randf() * 0.5)
	var front := -d * 0.5
	_box(Vector3(w, 3.0, d), pos + Vector3(0, 1.5, 0), _mat(wall))
	# A simple gabled roof from two slanted slabs.
	for side in [-1.0, 1.0]:
		var slab := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w + 0.5, 0.18, d * 0.62)
		slab.mesh = bm
		slab.material_override = _mat(Color(0.10, 0.09, 0.08))
		slab.position = pos + Vector3(0, 3.35, side * d * 0.25)
		slab.rotation.x = side * 0.5
		add_child(slab)
	_box(Vector3(0.85, 1.65, 0.12), pos + Vector3(0, 1.02, front - 0.06), _mat(Color(0.07, 0.05, 0.04)))   # door
	_box(Vector3(1.1, 0.12, 0.6), pos + Vector3(0, 0.2, front - 0.35), _mat(STONE.darkened(0.2)))          # step
	var wpos := pos + Vector3(w * 0.28, 1.6, front - 0.04)
	_box(Vector3(0.7, 0.7, 0.1), wpos, _mat(wall.darkened(0.5)))                                            # frame
	_box(Vector3(0.5, 0.5, 0.12), wpos + Vector3(0, 0, -0.03), _emissive(WARM, 1.6))                        # lit pane
	if _rng.randf() > 0.4:
		_box(Vector3(0.3, 1.0, 0.3), pos + Vector3(w * 0.3, 3.4, d * 0.2), _metal(Color(0.07, 0.07, 0.08)))
		_smoke(pos + Vector3(w * 0.3, 4.0, d * 0.2))


func _tree(pos: Vector3) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16
	trunk.bottom_radius = 0.22
	trunk.height = 2.0
	_add(trunk, pos + Vector3(0, 1.0, 0), _mat(Color(0.14, 0.10, 0.07)))
	var crown := SphereMesh.new()
	crown.radius = _rng.randf_range(1.1, 1.6)
	crown.height = crown.radius * 2.0
	_add(crown, pos + Vector3(0, 2.6, 0), _mat(Color(0.09, 0.15, 0.08).lerp(Color(0.12, 0.18, 0.10), _rng.randf())))


func _bench(pos: Vector3, along_x: bool) -> void:
	var seat_size := Vector3(1.8, 0.12, 0.5) if along_x else Vector3(0.5, 0.12, 1.8)
	_box(seat_size, pos + Vector3(0, 0.5, 0), _mat(Color(0.20, 0.15, 0.11)))
	_box(seat_size * Vector3(1, 3, 1) * 0.6 + Vector3(0, 0, 0), pos + Vector3(0, 0.25, 0), _mat(STONE))


func _fence(pos: Vector3, length: float, along_z := false) -> void:
	var n := int(length / 1.2)
	for i in range(n + 1):
		var off := (i - n * 0.5) * 1.2
		var p := pos + (Vector3(0, 0, off) if along_z else Vector3(off, 0, 0))
		_box(Vector3(0.1, 1.0, 0.1), p + Vector3(0, 0.5, 0), _mat(Color(0.16, 0.13, 0.10)))
	var rail := Vector3(0.06, 0.08, length) if along_z else Vector3(length, 0.08, 0.06)
	_box(rail, pos + Vector3(0, 0.75, 0), _mat(Color(0.16, 0.13, 0.10)))


# --------------------------------------------------------------------------
# People
# --------------------------------------------------------------------------

func _person(pos: Vector3, coat: Color, kind := "adult") -> void:
	var n := Blockout.new()
	_dress(n, coat, kind)
	n.position = pos
	n.rotation.y = _rng.randf_range(-PI, PI)
	n.scale = Vector3.ONE * _scale_for(kind)
	add_child(n)


func _wanderer(pos: Vector3, coat: Color, radius: float, kind := "adult") -> void:
	var n := Wanderer.new()
	_dress(n, coat, kind)
	n.position = pos
	n.roam_radius = radius
	n.scale = Vector3.ONE * _scale_for(kind)
	n.speed = 0.7 if kind == "elder" else (1.4 if kind == "child" else 1.1)
	add_child(n)


func _dress(n, coat: Color, kind: String) -> void:
	n.body_color = coat
	n.accent_color = Color(0.12, 0.12, 0.14)
	n.skin_color = Color(0.72, 0.57, 0.47)
	if kind == "elder":
		n.accent_color = Color(0.55, 0.55, 0.57)  # grey hair


func _scale_for(kind: String) -> float:
	match kind:
		"child": return 0.6
		"teen": return 0.82
		"elder": return 0.94
		_: return 1.0


func _pick(palette: Array) -> Color:
	return palette[_rng.randi() % palette.size()]


func _street_crowd() -> void:
	# Pedestrians strolling the main roads and sidewalks, spread across town.
	for _i in 14:
		var on_v := _rng.randf() < 0.5
		var p: Vector3
		if on_v:
			var x: float = V_ROADS[_rng.randi() % V_ROADS.size()] + (ROAD_W * 0.5 + 0.8) * (1.0 if _rng.randf() < 0.5 else -1.0)
			p = Vector3(x, 0, _rng.randf_range(Z_MIN + 4, Z_MAX - 4))
		else:
			var z: float = H_ROADS[_rng.randi() % H_ROADS.size()] + (ROAD_W * 0.5 + 0.8) * (1.0 if _rng.randf() < 0.5 else -1.0)
			p = Vector3(_rng.randf_range(X_MIN + 4, X_MAX - 4), 0, z)
		if absf(p.x) < 5.0 and p.z < 6.0 and p.z > -22.0:
			continue  # keep the central market spine readable
		var kinds := ["adult", "adult", "teen", "elder"]
		_wanderer(p, _pick(COATS_DOWN), 4.0, kinds[_rng.randi() % kinds.size()])


# --------------------------------------------------------------------------
# Fixed set-pieces (workshop, lift, station) + ambient
# --------------------------------------------------------------------------

func _workshop(pos: Vector3) -> void:
	_box(Vector3(7, 6, 5), pos + Vector3(0, 3, 0), _mat(Color(0.24, 0.18, 0.15)))
	_box(Vector3(2.4, 3, 0.3), pos + Vector3(0, 1.5, -2.6), _mat(Color(0.05, 0.05, 0.06)))
	_box(Vector3(1.2, 1.0, 1.0), pos + Vector3(0, 0.6, -3.4), _emissive(FORGE, 2.6))
	var glow := OmniLight3D.new()
	glow.light_color = FORGE
	glow.light_energy = 2.6
	glow.omni_range = 8.0
	glow.position = pos + Vector3(0, 1.4, -3.2)
	add_child(glow)


func _lift(pos: Vector3) -> void:
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


func _rail_station(pos: Vector3) -> void:
	_box(Vector3(10, 7, 8), pos + Vector3(0, 3.5, 0), _mat(Color(0.16, 0.15, 0.17)))
	_box(Vector3(3, 4, 0.5), pos + Vector3(0, 2, -4.1), _mat(Color(0.03, 0.03, 0.05)))
	_box(Vector3(6.5, 1, 0.3), pos + Vector3(0, 5.6, -4.1), _emissive(TEAL, 1.6))
	var glow := OmniLight3D.new()
	glow.light_color = TEAL
	glow.light_energy = 2.0
	glow.omni_range = 7.5
	glow.position = pos + Vector3(0, 1.6, -3.0)
	add_child(glow)


func _stall(pos: Vector3) -> void:
	for x in [-0.9, 0.9]:
		_box(Vector3(0.1, 2, 0.1), pos + Vector3(x, 1, 0), _mat(COPPER))
	_box(Vector3(2.2, 0.1, 1.4), pos + Vector3(0, 2, 0), _mat(Color(0.35, 0.15, 0.15)))
	_box(Vector3(2.0, 0.8, 1.0), pos + Vector3(0, 0.9, 0), _mat(Color(0.2, 0.16, 0.12)))


func _brazier(pos: Vector3) -> void:
	# An iron fire-basket on legs with a hot coal glow and drifting embers.
	_box(Vector3(0.5, 0.4, 0.5), pos + Vector3(0, 0.55, 0), _metal(Color(0.10, 0.09, 0.09)))
	for lx in [-0.18, 0.18]:
		for lz in [-0.18, 0.18]:
			_box(Vector3(0.05, 0.55, 0.05), pos + Vector3(lx, 0.28, lz), _metal(Color(0.08, 0.07, 0.07)))
	var fire := SphereMesh.new()
	fire.radius = 0.24
	fire.height = 0.4
	_add(fire, pos + Vector3(0, 0.7, 0), _emissive(FORGE, 3.6))
	_embers(pos + Vector3(0, 0.75, 0))
	var light := OmniLight3D.new()
	light.light_color = FORGE
	light.light_energy = 2.8
	light.omni_range = 7.0
	light.light_specular = 1.4
	light.position = pos + Vector3(0, 0.8, 0)
	add_child(light)


func _lamp(pos: Vector3) -> void:
	# A wrought-iron gas lamp: fluted post, cross-arm and a glass lantern head that
	# throws a warm pool onto the wet street.
	_box(Vector3(0.28, 0.28, 0.28), pos + Vector3(0, 0.14, 0), _metal(Color(0.09, 0.09, 0.10)))  # base
	_box(Vector3(0.13, 3.4, 0.13), pos + Vector3(0, 1.7, 0), _metal(Color(0.11, 0.11, 0.12)))     # post
	_box(Vector3(0.5, 0.08, 0.08), pos + Vector3(0, 3.35, 0), _metal(Color(0.11, 0.11, 0.12)))    # cross-arm
	# Lantern housing (dark frame) + glowing glass core.
	_box(Vector3(0.34, 0.5, 0.34), pos + Vector3(0, 3.1, 0), _metal(Color(0.08, 0.08, 0.09)))
	var glass := BoxMesh.new()
	glass.size = Vector3(0.22, 0.38, 0.22)
	_add(glass, pos + Vector3(0, 3.1, 0), _emissive(WARM, 3.2))
	var light := OmniLight3D.new()
	light.light_color = WARM
	light.light_energy = 2.2
	light.omni_range = 8.5
	light.light_specular = 1.6   # streaks across wet ground
	light.position = pos + Vector3(0, 3.1, 0)
	add_child(light)


func _lifeline(pos: Vector3, color: Color) -> void:
	_box(Vector3(0.26, 0.05, 1.2), pos, _emissive(color, 2.0))


func _fan(pos: Vector3, axis: Vector3) -> void:
	var spinner := Spinner.new()
	spinner.spin_axis = axis
	spinner.speed = _rng.randf_range(2.0, 4.0)
	spinner.position = pos
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


# --- Atmosphere props ------------------------------------------------------

func _plume(pos: Vector3, col: Color, emissive: bool, amount: int, size: float, rise: float, life: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.position = pos
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 18.0
	mat.initial_velocity_min = rise * 0.6
	mat.initial_velocity_max = rise
	mat.gravity = Vector3(0.2, rise * 0.3, 0.0)
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


func _embers(pos: Vector3) -> void:
	_plume(pos, Color(1.0, 0.55, 0.2, 0.9), true, 14, 0.09, 1.4, 2.0)


func _smoke(pos: Vector3) -> void:
	_plume(pos, Color(0.10, 0.10, 0.12, 0.16), false, 16, 2.2, 1.1, 4.0)


func _chimney(pos: Vector3) -> void:
	_box(Vector3(0.45, 1.3, 0.45), pos + Vector3(0, 0.65, 0), _metal(Color(0.06, 0.06, 0.07)))
	_box(Vector3(0.55, 0.15, 0.55), pos + Vector3(0, 1.35, 0), _metal(Color(0.05, 0.05, 0.06)))
	_smoke(pos + Vector3(0, 1.5, 0))


func _cable(a: Vector3, b: Vector3, sag: float) -> void:
	# A drooping catenary between two anchor points — the Zaun wire-tangle look.
	var segs := 7
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var p := a.lerp(b, t)
		p.y -= sag * sin(t * PI)
		_cable_seg(prev, p)
		prev = p


func _cable_seg(p0: Vector3, p1: Vector3) -> void:
	var d := p1 - p0
	var seg_len := d.length()
	if seg_len < 0.01:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.05, seg_len)
	mi.mesh = bm
	mi.material_override = _metal(Color(0.04, 0.04, 0.05))
	add_child(mi)
	# Pick an up vector that isn't parallel to the segment (avoids a look_at error).
	var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	mi.look_at_from_position((p0 + p1) * 0.5, p1, up)


func _conduit(pos: Vector3, height: float, color: Color) -> void:
	# A Lifeline pipe climbing a wall, its seam glowing teal/magenta.
	_box(Vector3(0.18, height, 0.18), pos + Vector3(0, height * 0.5, 0), _metal(Color(0.08, 0.08, 0.09)))
	_box(Vector3(0.07, height, 0.07), pos + Vector3(0.07, height * 0.5, -0.09), _emissive(color, 2.4))
	for hy in [height * 0.25, height * 0.6, height * 0.9]:
		_box(Vector3(0.28, 0.07, 0.12), pos + Vector3(0, hy, -0.04), _metal(Color(0.07, 0.07, 0.08)))


func _hanging_sign(pos: Vector3, color: Color) -> void:
	_box(Vector3(0.5, 0.05, 0.05), pos + Vector3(0.25, 0, 0), _metal(Color(0.08, 0.08, 0.09)))
	_box(Vector3(0.03, 0.32, 0.03), pos + Vector3(0.5, -0.16, 0), _metal(Color(0.08, 0.08, 0.09)))
	_box(Vector3(0.75, 0.42, 0.08), pos + Vector3(0.5, -0.52, 0), _emissive(color, 1.7))


func _string_lights(a: Vector3, b: Vector3, bulbs: int, color: Color) -> void:
	_cable(a, b, 0.5)
	for i in range(1, bulbs + 1):
		var t := float(i) / (bulbs + 1)
		var p := a.lerp(b, t)
		p.y -= 0.5 * sin(t * PI) + 0.15
		var s := SphereMesh.new()
		s.radius = 0.07
		s.height = 0.14
		_add(s, p, _emissive(color, 2.6))


func _puddle(pos: Vector3, radius: float) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	_add(cyl, pos + Vector3(0, 0.05, 0), _wet(Color(0.02, 0.03, 0.05)))


func _barrel(pos: Vector3) -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.34
	cyl.bottom_radius = 0.34
	cyl.height = 0.9
	_add(cyl, pos + Vector3(0, 0.45, 0), _metal(Color(0.17, 0.13, 0.09)))
	_box(Vector3(0.72, 0.06, 0.72), pos + Vector3(0, 0.25, 0), _metal(Color(0.10, 0.08, 0.06)))
	_box(Vector3(0.72, 0.06, 0.72), pos + Vector3(0, 0.65, 0), _metal(Color(0.10, 0.08, 0.06)))


func _crate(pos: Vector3, s: float) -> void:
	_box(Vector3(s, s, s), pos + Vector3(0, s * 0.5, 0), _mat(Color(0.20, 0.14, 0.09)))
	_box(Vector3(s * 1.02, 0.05, s * 1.02), pos + Vector3(0, s * 0.5, 0), _mat(Color(0.12, 0.09, 0.06)))


# --------------------------------------------------------------------------
# Low-level helpers
# --------------------------------------------------------------------------

func _npc(pos: Vector3, coat: Color) -> void:
	_person(pos, coat, "adult")


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
	# Rough, grimy stone/plaster with a little per-surface variation so flat walls
	# don't read as uniform. A faint cool rim from ambient does the rest.
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = _rng.randf_range(0.82, 0.98)
	m.metallic_specular = 0.35
	return m


func _wet(c: Color) -> StandardMaterial3D:
	# Wet cobbles / puddled ground: dark and glossy so lamps streak across it.
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.18
	m.metallic = 0.0
	m.metallic_specular = 0.9
	return m


func _metal(c: Color) -> StandardMaterial3D:
	# Rusted iron / copper: lamp posts, pipes, rails, brackets.
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
