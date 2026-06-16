extends "res://ui/menus/run/character_info_panel.gd"

const DissonanceDifficultyRecords = preload("res://mods-unpacked/RyehJael-Dissonance/extensions/dissonance_difficulty_records.gd")


func set_element(character_id: int) -> void:
	if Keys.hash_to_string.has(character_id):
		character_currently_displayed = Keys.hash_to_string[character_id]
	else:
		character_currently_displayed = ""

	var dissonance_character_id = DissonanceDifficultyRecords.get_character_id_from_hash(character_id)
	if not dissonance_character_id.empty():
		DissonanceDifficultyRecords.restore_records()

	reset_all()

	var character_diff_data = ProgressData.get_character_difficulty_info(character_id, RunData.current_zone)
	if character_diff_data == null:
		return

	if character_diff_data.max_difficulty_beaten.difficulty_value != -1:
		var scaling_text = Utils.get_enemy_scaling_text(
			character_diff_data.max_difficulty_beaten.enemy_health,
			character_diff_data.max_difficulty_beaten.enemy_damage,
			character_diff_data.max_difficulty_beaten.enemy_speed,
			character_diff_data.max_difficulty_beaten.retries,
			character_diff_data.max_difficulty_beaten.is_coop,
			character_diff_data.max_difficulty_beaten.used_ban_count
		)

		_max_diff_title.text = "MAX_DIFFICULTY_BEATEN"
		_max_diff_value.text = "%s%s" % [
			_get_dissonance_difficulty_label(character_diff_data.max_difficulty_beaten.difficulty_value),
			scaling_text
		]

	if character_diff_data.max_endless_wave_beaten.wave_number >= 0:
		var scaling_text = Utils.get_enemy_scaling_text(
			character_diff_data.max_endless_wave_beaten.enemy_health,
			character_diff_data.max_endless_wave_beaten.enemy_damage,
			character_diff_data.max_endless_wave_beaten.enemy_speed,
			character_diff_data.max_endless_wave_beaten.retries,
			character_diff_data.max_endless_wave_beaten.is_coop,
			character_diff_data.max_endless_wave_beaten.used_ban_count
		)
		_max_endless_title.text = "MAX_ENDLESS_WAVE_BEATEN"
		_max_endless_value.text = "%s - %s%s" % [
			Text.text("WAVE", [str(character_diff_data.max_endless_wave_beaten.wave_number)]),
			_get_dissonance_difficulty_label(character_diff_data.max_endless_wave_beaten.difficulty_value),
			scaling_text
		]
	else:
		_max_endless_title.text = ""


func _get_dissonance_difficulty_label(difficulty_value: int) -> String:
	var difficulty_data = ItemService.get_element(ItemService.difficulties, Keys.empty_hash, difficulty_value)
	if difficulty_data != null:
		return Text.text(difficulty_data.name, [str(difficulty_data.value)])

	return Text.text("DIFFICULTY_NB", [str(difficulty_value)])
