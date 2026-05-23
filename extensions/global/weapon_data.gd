extends "res://items/global/weapon_data.gd"


func get_weapon_stats_text(player_index: int, hide_if_non_unlock_in_codex: bool = false) -> String:
	return .get_weapon_stats_text(_get_safe_weapon_text_player_index(player_index), hide_if_non_unlock_in_codex)


func get_effects_text(player_index: int, with_tracking_text: bool = true) -> String:
	return .get_effects_text(_get_safe_weapon_text_player_index(player_index), with_tracking_text)


func _get_safe_weapon_text_player_index(player_index: int) -> int:
	if player_index >= 0 and player_index < RunData.players_data.size():
		return player_index
	if RunData.players_data.size() > 0:
		return 0
	return RunData.DUMMY_PLAYER_INDEX
