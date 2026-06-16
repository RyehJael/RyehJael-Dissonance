extends "res://singletons/progress_data_loader_v3.gd"

const DISSONANCE_DIFFICULTY_RECORDS_KEY = "dissonance_character_difficulty_records"

var dissonance_character_difficulty_records := {}


func load_progress_save_file(path: = "") -> void:
	.load_progress_save_file(path)
	_load_dissonance_difficulty_records(path)


func get_save_object() -> Dictionary:
	var save_object = .get_save_object()
	save_object[DISSONANCE_DIFFICULTY_RECORDS_KEY] = dissonance_character_difficulty_records.duplicate(true)
	return save_object


func _load_dissonance_difficulty_records(path: String = "") -> void:
	dissonance_character_difficulty_records.clear()

	if load_status != LoadStatus.SAVE_OK and load_status != LoadStatus.CORRUPTED_SAVE:
		return
	if path.empty():
		path = save_path
	if path.empty():
		return

	var save_file := File.new()
	if not save_file.file_exists(path):
		return
	if save_file.open(path, File.READ) != OK:
		return

	var content = save_file.get_as_text()
	save_file.close()
	var parse_result := JSON.parse(content)
	if parse_result.error != OK or typeof(parse_result.result) != TYPE_DICTIONARY:
		return

	var save_object = parse_result.result
	var records = save_object.get(DISSONANCE_DIFFICULTY_RECORDS_KEY, {})
	if records is Dictionary:
		dissonance_character_difficulty_records = records.duplicate(true)
