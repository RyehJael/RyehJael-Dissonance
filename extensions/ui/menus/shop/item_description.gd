extends "res://ui/menus/shop/item_description.gd"


func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void:
	.set_item(item_data, _get_safe_description_player_index(player_index), item_count)


func _process(delta: float) -> void:
	if _player_index == RunData.DUMMY_PLAYER_INDEX:
		return
	._process(delta)


func _get_safe_description_player_index(player_index: int) -> int:
	if player_index >= 0 and player_index < RunData.players_data.size():
		return player_index
	if RunData.players_data.size() > 0:
		return 0
	return RunData.DUMMY_PLAYER_INDEX
