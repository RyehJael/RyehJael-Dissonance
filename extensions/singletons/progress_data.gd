extends "res://singletons/progress_data.gd"

const DISSONANCE_CHARACTER_IDS = [
	"character_aeonian",
	"character_conductor",
	"character_influencer",
	"character_poet",
	"character_producer",
	"character_siren",
]


func get_character_difficulty_info(character_id: int, zone_id: int) -> ZoneDifficultyInfo:
	var dissonance_character_id = _get_dissonance_character_id_from_hash(character_id)
	if not dissonance_character_id.empty():
		_ensure_dissonance_character_zone_difficulty_info(dissonance_character_id, zone_id)

	return .get_character_difficulty_info(character_id, zone_id)


func save() -> void:
	_ensure_dissonance_character_difficulty_states()
	.save()


func get_current_save_object() -> Dictionary:
	_ensure_dissonance_character_difficulty_states()
	return .get_current_save_object()


func load_with_generic_loader(loader, path: = "") -> void:
	.load_with_generic_loader(loader, path)
	_ensure_dissonance_character_difficulty_states()


func _ensure_dissonance_character_difficulty_states() -> void:
	for character_id in DISSONANCE_CHARACTER_IDS:
		_ensure_dissonance_character_difficulty_info_for_id(character_id)


func _ensure_dissonance_character_difficulty_info_for_id(character_id: String) -> void:
	var character_diff_info = _get_or_create_dissonance_character_difficulty_info(character_id)
	var existing_zone_ids := []

	for zone_diff_info in character_diff_info.zones_difficulty_info:
		existing_zone_ids.push_back(zone_diff_info.zone_id)

	for zone in ZoneService.zones:
		if zone.unlocked_by_default and not existing_zone_ids.has(zone.my_id):
			character_diff_info.zones_difficulty_info.push_back(ZoneDifficultyInfo.new(zone.my_id))


func _ensure_dissonance_character_zone_difficulty_info(character_id: String, zone_id: int) -> void:
	var character_diff_info = _get_or_create_dissonance_character_difficulty_info(character_id)

	for zone_diff_info in character_diff_info.zones_difficulty_info:
		if zone_diff_info.zone_id == zone_id:
			return

	character_diff_info.zones_difficulty_info.push_back(ZoneDifficultyInfo.new(zone_id))


func _get_or_create_dissonance_character_difficulty_info(character_id: String):
	var character_hash = Keys.generate_hash(character_id)
	var character_diff_info = null
	var duplicate_infos := []

	for difficulty_info in difficulties_unlocked:
		if difficulty_info == null:
			continue
		if difficulty_info.character_id != character_id and difficulty_info.character_id_hash != character_hash:
			continue
		if character_diff_info == null:
			character_diff_info = difficulty_info
		else:
			duplicate_infos.push_back(difficulty_info)

	if character_diff_info == null:
		character_diff_info = CharacterDifficultyInfo.new(character_id)
		difficulties_unlocked.push_back(character_diff_info)
	else:
		character_diff_info.character_id = character_id
		character_diff_info.character_id_hash = character_hash

	for duplicate_info in duplicate_infos:
		_merge_dissonance_character_difficulty_info(character_diff_info, duplicate_info)
		difficulties_unlocked.erase(duplicate_info)

	return character_diff_info


func _merge_dissonance_character_difficulty_info(target_info, source_info) -> void:
	for source_zone_info in source_info.zones_difficulty_info:
		var target_zone_info = _get_dissonance_zone_difficulty_info(target_info, source_zone_info.zone_id)
		if target_zone_info == null:
			target_info.zones_difficulty_info.push_back(source_zone_info)
		else:
			target_zone_info.deserialize_and_merge_take_max(source_zone_info.serialize())


func _get_dissonance_zone_difficulty_info(character_diff_info, zone_id: int):
	for zone_diff_info in character_diff_info.zones_difficulty_info:
		if zone_diff_info.zone_id == zone_id:
			return zone_diff_info
	return null


func _get_dissonance_character_id_from_hash(character_id_hash: int) -> String:
	for character_id in DISSONANCE_CHARACTER_IDS:
		if Keys.generate_hash(character_id) == character_id_hash:
			return character_id
	return ""
