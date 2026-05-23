extends "res://effects/items/stat_gains_modification_effect.gd"


static func get_id() -> String:
	return "siren_safe_stat_gains_modifications"


func apply(player_index: int) -> void:
	if not _can_apply_to_player(player_index):
		return
	_ensure_stat_gain_entries(player_index)
	.apply(player_index)


func unapply(player_index: int) -> void:
	if not _can_apply_to_player(player_index):
		return
	_ensure_stat_gain_entries(player_index)
	.unapply(player_index)


func _can_apply_to_player(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()


func _ensure_stat_gain_entries(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	for stat in stats_modified:
		var stat_gain_hash = Keys.generate_hash("gain_" + stat)
		if not effects.has(stat_gain_hash):
			effects[stat_gain_hash] = 0
