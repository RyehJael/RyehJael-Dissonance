extends "res://singletons/progress_data.gd"

const DissonanceDifficultyRecords = preload("res://mods-unpacked/RyehJael-Dissonance/extensions/dissonance_difficulty_records.gd")

var dissonance_character_difficulty_records := {}


func reset() -> void:
	dissonance_character_difficulty_records.clear()
	set_meta(DissonanceDifficultyRecords.LOADED_SAVE_PATH_META_KEY, "")
	.reset()


func get_character_difficulty_info(character_id: int, zone_id: int) -> ZoneDifficultyInfo:
	var dissonance_character_id = DissonanceDifficultyRecords.get_character_id_from_hash(character_id)
	if not dissonance_character_id.empty():
		DissonanceDifficultyRecords.ensure_character_zone_record(dissonance_character_id, zone_id)

	return .get_character_difficulty_info(character_id, zone_id)


func save() -> void:
	DissonanceDifficultyRecords.persist_records()
	if DebugService.disable_saving:
		return
	if (
		load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_STEAM
		or load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_EPIC
	):
		.save()
		return
	.save()
	DissonanceDifficultyRecords.write_records_to_current_save_file()


func get_current_save_object() -> Dictionary:
	DissonanceDifficultyRecords.persist_records()
	var save_object = .get_current_save_object()
	save_object[DissonanceDifficultyRecords.DATA_KEY] = dissonance_character_difficulty_records.duplicate(true)
	if save_object.has("data") and save_object.data is Dictionary:
		save_object.data.erase(DissonanceDifficultyRecords.DATA_KEY)
	return save_object


func load_with_generic_loader(loader, path: = "") -> void:
	dissonance_character_difficulty_records.clear()
	set_meta(DissonanceDifficultyRecords.LOADED_SAVE_PATH_META_KEY, "")
	.load_with_generic_loader(loader, path)
	var loader_records = loader.get("dissonance_character_difficulty_records")
	if loader_records is Dictionary:
		dissonance_character_difficulty_records = loader_records.duplicate(true)
	DissonanceDifficultyRecords.restore_records()


func _set_loader_properties(loader_v3: ProgressDataLoaderV3, run_state: Dictionary) -> void:
	._set_loader_properties(loader_v3, run_state)
	loader_v3.set("dissonance_character_difficulty_records", dissonance_character_difficulty_records.duplicate(true))


func _set_loader_properties_beta(loader_v3: ProgressDataLoaderBeta, run_state: Dictionary) -> void:
	._set_loader_properties_beta(loader_v3, run_state)
	loader_v3.set("dissonance_character_difficulty_records", dissonance_character_difficulty_records.duplicate(true))
