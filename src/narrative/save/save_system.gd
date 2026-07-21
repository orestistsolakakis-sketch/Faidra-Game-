class_name SaveSystem
## Reads/writes the whole simulation to disk as JSON under user://saves/. Stateless:
## captures from / applies to the live World. Small because every system is plain,
## serializable data — saving is a shallow copy, not a bespoke traversal.

const SAVE_DIR := "user://saves"


static func slot_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]


static func has_save(slot: String = "quicksave") -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Capture the world (`world` is the World autoload) and write it to `slot`.
static func save_game(world, slot: String = "quicksave") -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Could not open slot '%s': %d" % [slot, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(world.capture_save(), "\t"))
	file.close()
	print("[SaveSystem] Saved slot '%s'." % slot)
	return true


## Load `slot` into the world. Returns false if missing or corrupt (world untouched).
static func load_game(world, slot: String = "quicksave") -> bool:
	if not has_save(slot):
		return false
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[SaveSystem] Corrupt save '%s'." % slot)
		return false

	world.load_game(data)
	print("[SaveSystem] Loaded slot '%s'." % slot)
	return true
