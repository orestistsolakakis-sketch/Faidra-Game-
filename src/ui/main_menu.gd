extends Control
## The title screen. Thin: wires its buttons to the core services, owns no game
## logic. "Play" boots a fresh simulation and enters the world; "Quit" exits.


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%PlayButton.grab_focus()


func _on_play_pressed() -> void:
	# Boot the narrative simulation for a fresh run, then enter the world.
	World.new_game()
	SceneLoader.transition_to("res://scenes/World/PlayerSandbox.tscn", GameState.PLAYING)


func _on_quit_pressed() -> void:
	get_tree().quit()
