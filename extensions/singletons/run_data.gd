extends "res://singletons/run_data.gd"

const DISSONANCE_LOG = "RyehJael-Dissonance"
var conductor_level_shift_hash = Keys.generate_hash("effect_conductor_level_shift")
var siren_character_hash = Keys.generate_hash("character_siren")
var influencer_character_hash = Keys.generate_hash("character_influencer")
var producer_character_hash = Keys.generate_hash("character_producer")
var cash_cow_item_hash = Keys.generate_hash("item_cash_cow")
var chal_unlock_conductor_hash = Keys.generate_hash("chal_unlock_conductor")
var chal_unlock_poet_hash = Keys.generate_hash("chal_unlock_poet")
var chal_unlock_producer_hash = Keys.generate_hash("chal_unlock_producer")


func init_tracked_effects() -> Dictionary:
	var tracked_effects = .init_tracked_effects()
	if not tracked_effects.has(siren_character_hash):
		tracked_effects[siren_character_hash] = 0
	if not tracked_effects.has(influencer_character_hash):
		tracked_effects[influencer_character_hash] = 0
	if not tracked_effects.has(producer_character_hash):
		tracked_effects[producer_character_hash] = 0
	if not tracked_effects.has(cash_cow_item_hash):
		tracked_effects[cash_cow_item_hash] = 0
	return tracked_effects


func get_player_effects(player_index: int) -> Dictionary:
	if player_index == DUMMY_PLAYER_INDEX:
		return _get_dissonance_dummy_player_effects()
	if player_index < 0 or player_index >= players_data.size():
		return _get_dissonance_dummy_player_effects()
	return .get_player_effects(player_index)


func get_player_character(player_index: int) -> CharacterData:
	if not _is_dissonance_valid_player_index(player_index):
		if players_data.size() > 0:
			return players_data[0].current_character
		return null
	return .get_player_character(player_index)


func get_player_effect(key: int, player_index: int):
	var effects = get_player_effects(player_index)
	if not effects.has(key):
		return 0
	return effects[key]


func add_stat(stat_hsh: int, value: int, player_index: int) -> void:
	if not _is_dissonance_valid_player_index(player_index):
		return
	.add_stat(stat_hsh, value, player_index)
	_try_complete_dissonance_stat_challenges(player_index)


func add_character(character: CharacterData, player_index: int) -> void:
	if not _is_dissonance_valid_player_index(player_index):
		return
	.add_character(character, player_index)
	_try_complete_dissonance_stat_challenges(player_index)


func add_item(item: ItemData, player_index: int, is_selection: bool = false) -> void:
	if not _is_dissonance_valid_player_index(player_index):
		return
	.add_item(item, player_index, is_selection)
	_try_complete_dissonance_stat_challenges(player_index)


func add_weapon(weapon: WeaponData, player_index: int, is_starting_weapon: bool = false):
	if not _is_dissonance_valid_player_index(player_index):
		return null
	var added_weapon = .add_weapon(weapon, player_index, is_starting_weapon)
	_try_complete_dissonance_stat_challenges(player_index)
	return added_weapon


func apply_item_effects(item_data: ItemParentData, player_index: int) -> void:
	if not _is_dissonance_valid_player_index(player_index):
		return
	.apply_item_effects(item_data, player_index)
	_try_complete_dissonance_stat_challenges(player_index)


func unapply_item_effects(item_data: ItemParentData, player_index: int) -> void:
	if not _is_dissonance_valid_player_index(player_index):
		return
	.unapply_item_effects(item_data, player_index)


func _get_dissonance_dummy_player_effects() -> Dictionary:
	if dummy_player_effects == null:
		dummy_player_effects = PlayerRunData.init_effects()
	return dummy_player_effects


func _is_dissonance_valid_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < players_data.size()


func _try_complete_dissonance_stat_challenges(player_index: int) -> void:
	_try_complete_conductor_unlock_challenge(player_index)
	_try_complete_poet_unlock_challenge(player_index)
	_try_complete_producer_unlock_challenge(player_index)


func _try_complete_conductor_unlock_challenge(player_index: int) -> void:
	if ChallengeService.is_challenge_completed(chal_unlock_conductor_hash):
		return

	var challenge = ChallengeService.get_chal(chal_unlock_conductor_hash)
	if challenge == null:
		return
	var required_value = challenge.value
	for stat_hash in RunData.primary_stats_list:
		if RunData.get_stat(stat_hash, player_index) < required_value:
			return

	ChallengeService.complete_challenge(chal_unlock_conductor_hash)


func _try_complete_poet_unlock_challenge(player_index: int) -> void:
	if ChallengeService.is_challenge_completed(chal_unlock_poet_hash):
		return

	var challenge = ChallengeService.get_chal(chal_unlock_poet_hash)
	if challenge == null:
		return
	var required_value = challenge.value
	if RunData.get_stat(Keys.stat_curse_hash, player_index) >= required_value:
		ChallengeService.complete_challenge(chal_unlock_poet_hash)


func _try_complete_producer_unlock_challenge(player_index: int) -> void:
	if ChallengeService.is_challenge_completed(chal_unlock_producer_hash):
		return

	var challenge = ChallengeService.get_chal(chal_unlock_producer_hash)
	if challenge == null:
		return
	if RunData.get_nb_pets(player_index) >= challenge.value:
		ChallengeService.complete_challenge(chal_unlock_producer_hash)


func level_up(player_index: int) -> void:
	.level_up(player_index)

	if not _conductor_has_level_shift_effect(player_index):
		return

	_apply_conductor_level_shift(player_index)


func _conductor_has_level_shift_effect(player_index: int) -> bool:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(conductor_level_shift_hash):
		effects[conductor_level_shift_hash] = 0
	return effects[conductor_level_shift_hash] > 0


func _apply_conductor_level_shift(player_index: int) -> void:
	var level_shift_effect = _get_conductor_level_shift_effect(player_index)
	var highest_delta = 5 if level_shift_effect == null else int(level_shift_effect.highest_delta)
	var lowest_delta = 3 if level_shift_effect == null else int(level_shift_effect.lowest_delta)
	if apply_primary_stat_shift(player_index, highest_delta, lowest_delta):
		ModLoaderLog.info("Conductor level-up shift applied", DISSONANCE_LOG)


func _get_conductor_level_shift_effect(player_index: int):
	var character = get_player_character(player_index)
	if character == null:
		return null

	for effect in character.effects:
		if effect != null and effect.key == "effect_conductor_level_shift":
			return effect

	return null


func apply_primary_stat_shift(player_index: int, highest_delta: int, lowest_delta: int, skip_disabled_stat_gain_targets: bool = false) -> bool:
	var highest_stats = []
	var highest_value = -INF

	for stat_hash in RunData.primary_stats_list:
		var stat_value = RunData.get_stat(stat_hash, player_index)
		if stat_value > highest_value:
			highest_value = stat_value
			highest_stats = [ stat_hash ]
		elif stat_value == highest_value:
			highest_stats.push_back(stat_hash)

	if highest_stats.empty():
		return false

	var reduced_stat_hash = Utils.get_rand_element(highest_stats)

	var lowest_stats = []
	var lowest_value = INF

	for stat_hash in RunData.primary_stats_list:
		if stat_hash == reduced_stat_hash:
			continue
		if skip_disabled_stat_gain_targets and is_stat_gain_disabled(player_index, stat_hash):
			continue
		var stat_value = RunData.get_stat(stat_hash, player_index)
		if stat_value < lowest_value:
			lowest_value = stat_value
			lowest_stats = [ stat_hash ]
		elif stat_value == lowest_value:
			lowest_stats.push_back(stat_hash)

	if lowest_stats.empty():
		return false

	var increased_stat_hash = Utils.get_rand_element(lowest_stats)
	RunData.remove_stat(reduced_stat_hash, highest_delta, player_index)
	RunData.add_stat(increased_stat_hash, lowest_delta, player_index)

	return true


func is_stat_gain_disabled(player_index: int, stat_hash: int) -> bool:
	return RunData.get_stat_gain(stat_hash, player_index) <= 0.0
