extends "res://singletons/progress_data.gd"

const DissonanceDifficultyRecords = preload("res://mods-unpacked/RyehJael-Dissonance/extensions/dissonance_difficulty_records.gd")


func get_character_difficulty_info(character_id: int, zone_id: int) -> ZoneDifficultyInfo:
	var dissonance_character_id = DissonanceDifficultyRecords.get_character_id_from_hash(character_id)
	if not dissonance_character_id.empty():
		DissonanceDifficultyRecords.ensure_character_zone_record(dissonance_character_id, zone_id)

	return .get_character_difficulty_info(character_id, zone_id)


func save() -> void:
	DissonanceDifficultyRecords.persist_records()
	.save()


func get_current_save_object() -> Dictionary:
	DissonanceDifficultyRecords.persist_records()
	return .get_current_save_object()


func load_with_generic_loader(loader, path: = "") -> void:
	.load_with_generic_loader(loader, path)
	DissonanceDifficultyRecords.restore_records()
