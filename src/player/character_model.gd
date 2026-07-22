extends MeshInstance3D
## Loads a real 3D model (e.g. an imported .obj/.glb) for a character and applies
## a material. Used to replace the placeholder billboard/blockout with an actual
## mesh. Handles both Mesh resources (Godot's default .obj import) and PackedScenes
## (.glb/.gltf scenes).

@export var model_path := ""
@export var tint := Color(0.78, 0.78, 0.82)   # untextured models render in this colour
@export var yaw_offset_deg := 0.0             # flip to 180 if the model faces backwards


func _ready() -> void:
	if model_path != "":
		var res := load(model_path)
		if res is Mesh:
			mesh = res
			var mat := StandardMaterial3D.new()
			mat.albedo_color = tint
			mat.roughness = 0.65
			material_override = mat
		elif res is PackedScene:
			# glTF imports as a scene with its own materials/textures.
			add_child((res as PackedScene).instantiate())

	rotation.y = deg_to_rad(yaw_offset_deg)
