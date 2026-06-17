extends Reference

const DATA_KEY = "dissonance_character_difficulty_records"
const LOADED_SAVE_PATH_META_KEY = "dissonance_difficulty_records_loaded_save_path"
const CHARACTER_IDS = [
	"character_aeonian",
	"character_conductor",
	"character_influencer",
	"character_poet",
	"character_producer",
	"character_siren",
]


static func restore_records() -> void:
	_merge_saved_records_into_progress()
	_ensure_all_character_records()
	_store_progress_records()
	ProgressData.set_max_selectable_difficulty()


static func persist_records() -> void:
	_merge_saved_records_into_progress()
	_ensure_all_character_records()
	_store_progress_records()


static func write_records_to_current_save_file() -> void:
	var save_path = _get_current_profile_save_path()
	if save_path.empty():
		return
	var records = ProgressData.get(DATA_KEY)
	if not (records is Dictionary):
		return

	var save_file := File.new()
	if not save_file.file_exists(save_path):
		return
	if save_file.open(save_path, File.READ) != OK:
		return

	var content = save_file.get_as_text()
	save_file.close()
	var parse_result := JSON.parse(content)
	if parse_result.error != OK or typeof(parse_result.result) != TYPE_DICTIONARY:
		return

	var save_object = parse_result.result
	save_object[DATA_KEY] = records.duplicate(true)
	if save_object.has("data") and save_object.data is Dictionary:
		save_object.data.erase(DATA_KEY)

	if save_file.open(save_path, File.WRITE) != OK:
		return
	var sort_keys := true
	var indent = ""
	if OS.has_feature("editor"):
		indent = "  "
	save_file.store_string(JSON.print(save_object, indent, sort_keys))
	save_file.close()


static func ensure_character_zone_record(character_id: String, zone_id: int) -> void:
	if not is_dissonance_character_id(character_id):
		return
	_merge_saved_records_into_progress()
	var character_info = _get_or_create_character_info(character_id)
	_get_or_create_zone_info(character_info, zone_id)
	_store_progress_records()


static func is_dissonance_character_id(character_id: String) -> bool:
	return CHARACTER_IDS.has(character_id)


static func get_character_id_from_hash(character_hash: int) -> String:
	for character_id in CHARACTER_IDS:
		if Keys.generate_hash(character_id) == character_hash:
			return character_id
	return ""


static func _ensure_all_character_records() -> void:
	for character_id in CHARACTER_IDS:
		_ensure_character_record(character_id)


static func _ensure_character_record(character_id: String) -> void:
	var character_info = _get_or_create_character_info(character_id)
	var existing_zone_ids := []

	for zone_info in character_info.zones_difficulty_info:
		existing_zone_ids.push_back(zone_info.zone_id)

	for zone in ZoneService.zones:
		if zone.unlocked_by_default and not existing_zone_ids.has(zone.my_id):
			character_info.zones_difficulty_info.push_back(ZoneDifficultyInfo.new(zone.my_id))


static func _merge_saved_records_into_progress() -> void:
	var saved_records = _get_saved_records()

	for character_id in saved_records.keys():
		if not is_dissonance_character_id(character_id):
			continue
		var serialized_info = saved_records[character_id]
		if not (serialized_info is Dictionary):
			continue
		var character_info = _get_or_create_character_info(character_id)
		_merge_serialized_character_info(character_info, serialized_info)


static func _store_progress_records() -> void:
	var saved_records = _get_saved_records()

	for character_id in CHARACTER_IDS:
		var character_info = _get_or_create_character_info(character_id)
		saved_records[character_id] = character_info.serialize()


static func _get_saved_records() -> Dictionary:
	var records = ProgressData.get(DATA_KEY)
	if not (records is Dictionary):
		records = {}

	_merge_serialized_records(records, _load_records_from_current_save_file())

	if ProgressData.data.has(DATA_KEY):
		var legacy_records = ProgressData.data[DATA_KEY]
		if legacy_records is Dictionary:
			_merge_serialized_records(records, legacy_records)
		ProgressData.data.erase(DATA_KEY)

	ProgressData.set(DATA_KEY, records)
	return records


static func _load_records_from_current_save_file() -> Dictionary:
	var save_path = _get_current_profile_save_path()
	if save_path.empty():
		return {}
	if (
		ProgressData.has_meta(LOADED_SAVE_PATH_META_KEY)
		and ProgressData.get_meta(LOADED_SAVE_PATH_META_KEY) == save_path
	):
		return {}

	var save_file := File.new()
	if not save_file.file_exists(save_path):
		return {}
	if save_file.open(save_path, File.READ) != OK:
		return {}

	var content = save_file.get_as_text()
	save_file.close()
	var parse_result := JSON.parse(content)
	if parse_result.error != OK or typeof(parse_result.result) != TYPE_DICTIONARY:
		return {}

	var records = parse_result.result.get(DATA_KEY, {})
	ProgressData.set_meta(LOADED_SAVE_PATH_META_KEY, save_path)
	if records is Dictionary:
		return records
	return {}


static func _get_current_profile_save_path() -> String:
	if ProgressData.BETA:
		return ProgressDataLoaderBeta.new(ProgressData.SAVE_DIR, ProgressData.current_profile_id).save_path
	return ProgressDataLoaderV3.new(ProgressData.SAVE_DIR, ProgressData.current_profile_id).save_path


static func _merge_serialized_records(target_records: Dictionary, source_records: Dictionary) -> void:
	for character_id in source_records.keys():
		if not is_dissonance_character_id(character_id):
			continue
		var source_info = source_records[character_id]
		if not (source_info is Dictionary):
			continue
		if not target_records.has(character_id) or not (target_records[character_id] is Dictionary):
			target_records[character_id] = source_info.duplicate(true)
			continue

		var merged_info = CharacterDifficultyInfo.new(character_id)
		_merge_serialized_character_info(merged_info, target_records[character_id])
		_merge_serialized_character_info(merged_info, source_info)
		target_records[character_id] = merged_info.serialize()


static func _get_or_create_character_info(character_id: String):
	var character_hash = Keys.generate_hash(character_id)
	var character_info = null
	var duplicate_infos := []

	for difficulty_info in ProgressData.difficulties_unlocked:
		if difficulty_info == null:
			continue
		if difficulty_info.character_id != character_id and difficulty_info.character_id_hash != character_hash:
			continue
		if character_info == null:
			character_info = difficulty_info
		else:
			duplicate_infos.push_back(difficulty_info)

	if character_info == null:
		character_info = CharacterDifficultyInfo.new(character_id)
		ProgressData.difficulties_unlocked.push_back(character_info)
	else:
		character_info.character_id = character_id
		character_info.character_id_hash = character_hash

	for duplicate_info in duplicate_infos:
		_merge_character_info(character_info, duplicate_info)
		ProgressData.difficulties_unlocked.erase(duplicate_info)

	return character_info


static func _merge_character_info(target_info, source_info) -> void:
	for source_zone_info in source_info.zones_difficulty_info:
		var target_zone_info = _get_or_create_zone_info(target_info, source_zone_info.zone_id)
		_merge_serialized_zone_info(target_zone_info, source_zone_info.serialize())


static func _merge_serialized_character_info(target_info, serialized_info: Dictionary) -> void:
	if not serialized_info.has("zones_difficulty_info") or not (serialized_info.zones_difficulty_info is Array):
		return

	for serialized_zone_info in serialized_info.zones_difficulty_info:
		if not (serialized_zone_info is Dictionary) or not serialized_zone_info.has("zone_id"):
			continue
		var target_zone_info = _get_or_create_zone_info(target_info, int(serialized_zone_info.zone_id))
		_merge_serialized_zone_info(target_zone_info, serialized_zone_info)


static func _get_or_create_zone_info(character_info, zone_id: int):
	for zone_info in character_info.zones_difficulty_info:
		if zone_info.zone_id == zone_id:
			return zone_info

	var zone_info = ZoneDifficultyInfo.new(zone_id)
	character_info.zones_difficulty_info.push_back(zone_info)
	return zone_info


static func _merge_serialized_zone_info(target_zone_info, serialized_zone_info: Dictionary) -> void:
	target_zone_info.difficulty_selected_value = int(max(
		target_zone_info.difficulty_selected_value,
		int(serialized_zone_info.get("difficulty_selected_value", 0))
	))
	target_zone_info.max_selectable_difficulty = int(max(
		target_zone_info.max_selectable_difficulty,
		int(serialized_zone_info.get("max_selectable_difficulty", 0))
	))

	if serialized_zone_info.has("max_difficulty_beaten"):
		_merge_difficulty_score(target_zone_info.max_difficulty_beaten, serialized_zone_info.max_difficulty_beaten, false)
	if serialized_zone_info.has("max_endless_wave_beaten"):
		_merge_difficulty_score(target_zone_info.max_endless_wave_beaten, serialized_zone_info.max_endless_wave_beaten, true)


static func _merge_difficulty_score(target_score, serialized_score, is_endless: bool) -> void:
	if not (serialized_score is Dictionary):
		return

	var difficulty_value = int(serialized_score.get("difficulty_value", -1))
	if difficulty_value < 0:
		return

	target_score.set_info(
		difficulty_value,
		int(serialized_score.get("wave_number", -1)),
		float(serialized_score.get("enemy_health", 1.0)),
		float(serialized_score.get("enemy_damage", 1.0)),
		float(serialized_score.get("enemy_speed", 1.0)),
		int(serialized_score.get("retries", 0)),
		int(serialized_score.get("used_ban_count", 0)),
		bool(serialized_score.get("is_coop", false)),
		is_endless
	)
