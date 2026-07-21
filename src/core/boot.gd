extends Node
## The main scene's script — one clean entry point. Once autoloads exist, hand
## off to the main menu. Future startup work (settings, save load, splash) goes here.


func _ready() -> void:
	SceneLoader.transition_to("res://scenes/UI/MainMenu.tscn", GameState.MAIN_MENU)
