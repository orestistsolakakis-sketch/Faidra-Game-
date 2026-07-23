extends Node3D
## A stylized humanoid BLOCKOUT — a placeholder character built from primitives so
## the leads read as people (head/torso/arms/legs) in their signature colour,
## instead of a bare capsule. Purely visual (no collision; the CharacterBody3D owns
## that). Replaced by real modelled/concept-driven meshes later; see
## docs/ART_DIRECTION.md. Faces -Z (forward) so it matches the controller's facing.

@export var body_color := Color(0.85, 0.5, 0.32)   # coat / main identity colour
@export var accent_color := Color(0.16, 0.18, 0.22) # boots, gloves, hair
@export var skin_color := Color(0.86, 0.66, 0.52)


func _ready() -> void:
	var body := _mat(body_color)
	var accent := _mat(accent_color)
	var skin := _mat(skin_color)

	# Legs
	_limb(CapsuleMesh.new(), 0.13, 0.9, Vector3(-0.15, 0.45, 0), accent)
	_limb(CapsuleMesh.new(), 0.13, 0.9, Vector3(0.15, 0.45, 0), accent)
	# Torso (coat)
	_limb(CapsuleMesh.new(), 0.27, 1.0, Vector3(0, 1.15, 0), body)
	# Arms
	_limb(CapsuleMesh.new(), 0.09, 0.8, Vector3(-0.34, 1.15, 0), body)
	_limb(CapsuleMesh.new(), 0.09, 0.8, Vector3(0.34, 1.15, 0), body)
	# Head
	var head := SphereMesh.new()
	head.radius = 0.16
	head.height = 0.32
	_add(head, Vector3(0, 1.74, 0), skin)
	# Simple face indicator so facing is readable (front = -Z)
	var brow := BoxMesh.new()
	brow.size = Vector3(0.22, 0.05, 0.05)
	_add(brow, Vector3(0, 1.78, -0.15), accent)


func _limb(mesh: CapsuleMesh, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> void:
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
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
	m.roughness = 0.75
	m.metallic = 0.0
	return m
