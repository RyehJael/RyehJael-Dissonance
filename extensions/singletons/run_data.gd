extends "res://singletons/run_data.gd"

const DISSONANCE_LOG = "RyehJael-Dissonance"
var conductor_level_shift_hash = Keys.generate_hash("effect_conductor_level_shift")

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
	if apply_primary_stat_shift(player_index, 5, 2):
		ModLoaderLog.info("Conductor level-up shift applied", DISSONANCE_LOG)


func apply_primary_stat_shift(player_index: int, highest_delta: int, lowest_delta: int) -> bool:
	var highest_stats = []
	var highest_value = -INF

	for stat_hash in RunData.primary_stats_list:
		if stat_hash == Keys.stat_max_hp_hash:
			continue
		var stat_value = RunData.get_stat(stat_hash, player_index)
		if stat_value > highest_value:
			highest_value = stat_value
			highest_stats = [ stat_hash ]
		elif stat_value == highest_value:
			highest_stats.push_back(stat_hash)

	if highest_stats.empty():
		return false

	var reduced_stat_hash = Utils.get_rand_element(highest_stats)
	RunData.remove_stat(reduced_stat_hash, highest_delta, player_index)

	var lowest_stats = []
	var lowest_value = INF

	for stat_hash in RunData.primary_stats_list:
		if stat_hash == Keys.stat_max_hp_hash:
			continue
		if stat_hash == reduced_stat_hash:
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
	RunData.add_stat(increased_stat_hash, lowest_delta, player_index)

	return true
