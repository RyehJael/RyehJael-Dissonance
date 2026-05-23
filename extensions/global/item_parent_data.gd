extends "res://items/global/item_parent_data.gd"


func get_effects_text(player_index: int) -> String:
	return .get_effects_text(_get_safe_effects_text_player_index(player_index))


func _get_safe_effects_text_player_index(player_index: int) -> int:
	if player_index == RunData.DUMMY_PLAYER_INDEX:
		return player_index
	if player_index < 0 or player_index >= RunData.players_data.size():
		return RunData.DUMMY_PLAYER_INDEX
	return player_index
