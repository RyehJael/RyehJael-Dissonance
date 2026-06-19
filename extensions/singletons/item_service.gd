extends "res://singletons/item_service.gd"


func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
	if item != null and DebugService.force_item_in_shop == "" and _dissonance_is_player_banned_item(item, player_index):
		var fallback_item = _dissonance_get_unbanned_replacement(item, player_index)
		if fallback_item != null:
			item = fallback_item

	return .apply_item_effect_modifications(item, player_index)


func _dissonance_get_unbanned_replacement(item: ItemParentData, player_index: int) -> ItemParentData:
	var type = TierData.WEAPONS if item is WeaponData else TierData.ITEMS
	var fallback_pool = _dissonance_get_unbanned_pool(item.tier, type, player_index)
	if fallback_pool.empty():
		for tier in _tiers_data.size():
			if tier == item.tier:
				continue
			fallback_pool.append_array(_dissonance_get_unbanned_pool(tier, type, player_index))

	if fallback_pool.empty():
		return null

	return Utils.get_rand_element(fallback_pool)


func _dissonance_get_unbanned_pool(item_tier: int, type: int, player_index: int) -> Array:
	var pool = get_pool(item_tier, type)
	pool = _dissonance_remove_player_banned_items(pool, player_index)
	pool = _dissonance_remove_limited_items(pool, player_index)
	return pool


func _dissonance_remove_limited_items(pool: Array, player_index: int) -> Array:
	if player_index < 0 or player_index >= RunData.players_data.size():
		return pool

	var owned_and_locked_items = RunData.get_player_items(player_index)
	for locked_item in RunData.get_player_locked_shop_items(player_index):
		if locked_item[0] is ItemData:
			owned_and_locked_items.push_back(locked_item[0])

	var filtered_pool = pool
	var limited_items = get_limited_items(owned_and_locked_items)
	for key in limited_items:
		if limited_items[key][1] >= limited_items[key][0].max_nb:
			filtered_pool = remove_element_by_id_with_item(filtered_pool, limited_items[key][0])

	return filtered_pool


func _dissonance_remove_player_banned_items(pool: Array, player_index: int) -> Array:
	if player_index < 0 or player_index >= RunData.players_data.size():
		return pool

	var filtered_pool = pool
	for item_id in RunData.players_data[player_index].banned_items:
		filtered_pool = remove_element_by_id(filtered_pool, _dissonance_get_banned_item_hash(item_id))

	return filtered_pool


func _dissonance_is_player_banned_item(item: ItemParentData, player_index: int) -> bool:
	if player_index < 0 or player_index >= RunData.players_data.size():
		return false

	for item_id in RunData.players_data[player_index].banned_items:
		if item.my_id_hash == _dissonance_get_banned_item_hash(item_id):
			return true

	return false


func _dissonance_get_banned_item_hash(item_id) -> int:
	if item_id is String:
		return Keys.generate_hash(item_id)
	return int(item_id)
