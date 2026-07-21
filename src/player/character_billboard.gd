extends Sprite3D
## Displays a character's 2D concept art as an upright billboard that always faces
## the camera — a "standee" stand-in until a real 3D model exists. A free way to
## put actual character art into the world (docs/UI_UX_BIBLE.md art track).

@export var texture_path := ""
@export var target_height := 2.3  # world-space height of the standee, in metres


func _ready() -> void:
	if texture_path != "":
		var tex := load(texture_path) as Texture2D
		if tex != null:
			texture = tex

	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y   # face camera, stay upright
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD      # crisp cutout edges, sorts cleanly
	shaded = false                                  # show the art at full brightness

	if texture != null and texture.get_height() > 0:
		pixel_size = target_height / float(texture.get_height())
	# Stand her feet on the parent's origin (feet on the ground).
	position.y = target_height * 0.5
