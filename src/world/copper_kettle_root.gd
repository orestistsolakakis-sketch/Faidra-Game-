extends Node3D
## Controller for the Copper Kettle interior. Runs the interaction loop; the patrons
## trade rumours that change with the time of day (some true, some not); the counter
## serves food. Stepping inside lets an hour or so pass, so the room is different when
## you come back — the world keeps moving without the player.

var _hud: CanvasLayer
var _active_interactables: Array = []
var _part := "afternoon"

const RUMOURS := {
	"morning": [
		"\"Steam lift's dead again. Third time this month. My shift starts up top — now I climb.\"",
		"\"Heard the hospital's short on medicine. Old Marta's boy has that cough going round.\"",
		"\"Someone's been poking round the empty factory at night. Not scavengers. Careful sort.\"",
	],
	"afternoon": [
		"\"They say a healer came through the Hollow once. Mended a man the doctors gave up on. Ghost story, probably.\"",
		"\"Machine shipment never came through Cinder Gate. Manifest says it did. Somebody's lying on paper.\"",
		"\"Rennick'll buy any scrap, no questions. Some of it's got royal marks filed off, if you look.\"",
	],
	"evening": [
		"\"Keep your voice down about the palace in here. Walls listen. Especially the Bell's walls.\"",
		"\"The clock's been dead longer than I've been alive. My gran says the day it stops for good, the Hollow's finished.\"",
		"\"People go missing down the old rail line and nobody official ever asks after them. Think on that.\"",
	],
	"night": [
		"\"You shouldn't be out this late. Not the streets. Not tonight.\"",
		"\"Whatever hums under the district — you feel it in your teeth down here after dark? That's not the boilers.\"",
	],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud = get_node("%Hud")

	# Stepping in lets time move on a little.
	World.clock.advance(75)
	_part = World.clock.part_of_day()

	var party := get_node("PartyController")
	party.active_character_changed.connect(func(_id): _hud.set_solo_lead("Arlen"))
	_hud.set_solo_lead("Arlen")

	for node in get_tree().get_nodes_in_group("interactable"):
		node.entered.connect(_on_interactable_entered)
		node.exited.connect(_on_interactable_exited)

	_hud.set_objective("Warm up. Listen. The Kettle always knows something.")
	_hud.show_title("THE COPPER KETTLE", "%s — %s" % [World.clock.to_display_string(), _mood()])


func _mood() -> String:
	match _part:
		"morning": return "workers bolting breakfast before the whistle"
		"afternoon": return "packed, loud, every table taken"
		"evening": return "low talk, an argument by the fire"
		_: return "near empty, chairs up, one lamp burning"


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ESCAPE:
			GameManager.toggle_pause()
		KEY_E:
			_try_interact()


func _try_interact() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		return
	var which: Node = _active_interactables.back()
	match which.id:
		"kettle_exit":
			SceneLoader.transition_to("res://scenes/World/CinderHollow.tscn", GameState.PLAYING)
		"kettle_counter":
			_hud.push_toast("", "The cook slides you a bowl without being asked. Hot, cheap, more than you can finish.")
		"kettle_patron_1":
			_rumour(0)
		"kettle_patron_2":
			_rumour(1)
		"kettle_patron_3":
			_rumour(2)
		_:
			_hud.push_toast("", "Just steam and the smell of frying.")
	_update_prompt()


func _rumour(i: int) -> void:
	var pool: Array = RUMOURS.get(_part, RUMOURS["afternoon"])
	if pool.is_empty():
		_hud.push_toast("", "They just nod at you and go back to their bowl.")
		return
	_hud.push_toast("OVERHEARD", pool[i % pool.size()])


func _on_interactable_entered(which: Node) -> void:
	if not _active_interactables.has(which):
		_active_interactables.append(which)
	_update_prompt()


func _on_interactable_exited(which: Node) -> void:
	_active_interactables.erase(which)
	_update_prompt()


func _update_prompt() -> void:
	if _active_interactables.is_empty() or _hud.is_dialogue_active():
		_hud.hide_interaction()
		return
	var current: Node = _active_interactables.back()
	_hud.show_interaction(current.label, current.verb)
