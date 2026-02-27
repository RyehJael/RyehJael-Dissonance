extends "res://singletons/run_data.gd"

const DISSONANCE_LOG = "RyehJael-Dissonance"
var composer_level_shift_hash = Keys.generate_hash("effect_composer_level_shift")

func init_effects()->Dictionary:
	return Utils.merge_dictionaries(.init_effects(), {
		composer_level_shift_hash: 0
	})


func level_up(player_index: int) -> void:
	.level_up(player_index)

	if not _composer_has_level_shift_effect(player_index):
		return

	_apply_composer_level_shift(player_index)


func _composer_has_level_shift_effect(player_index: int) -> bool:
	return RunData.get_player_effect(composer_level_shift_hash, player_index) > 0


func _apply_composer_level_shift(player_index: int) -> void:
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
		return

	var reduced_stat_hash = Utils.get_rand_element(highest_stats)
	RunData.remove_stat(reduced_stat_hash, 1, player_index)

	var increase_pool = []
	for stat_hash in RunData.primary_stats_list:
		if stat_hash != reduced_stat_hash:
			increase_pool.push_back(stat_hash)
	increase_pool.shuffle()

	var increase_count = min(2, increase_pool.size())
	for i in range(increase_count):
		RunData.add_stat(increase_pool[i], 1, player_index)

	ModLoaderLog.info("Composer level-up shift applied", DISSONANCE_LOG)
