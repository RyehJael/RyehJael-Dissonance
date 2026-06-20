extends "res://singletons/player_run_data.gd"

const COW_HEAD_ITEM_ID := "item_cow_head"

var dissonance_influencer_purchase_count := 0


static func init_effects() -> Dictionary:
	return Utils.merge_dictionaries(.init_effects(), {
		Keys.generate_hash("effect_conductor_level_shift"): 0,
		Keys.generate_hash("effect_siren_spawn_cursed_enemy"): 0,
		Keys.generate_hash("effect_siren_bonus_materials_from_cursed_enemies"): 0,
		Keys.generate_hash("effect_aeonian_round_duration_per_max_hp"): 0,
		Keys.generate_hash("effect_round_duration_bonus"): 0,
		Keys.generate_hash("effect_poet_curse_shop_reroll"): 0,
		Keys.generate_hash("effect_poet_enemy_scaling_per_curse"): 0,
		Keys.generate_hash("effect_influencer_harvesting_on_ban"): 0,
		Keys.generate_hash("effect_influencer_bonus_ban_on_purchase"): 0,
		Keys.generate_hash("effect_black_notebook_xp_from_cursed_enemy"): 0,
		Keys.generate_hash("effect_disturbing_photo_ban_next_bought_item"): 0
	})


func duplicate() -> PlayerRunData:
	var copy = .duplicate()
	copy.dissonance_influencer_purchase_count = dissonance_influencer_purchase_count
	return copy


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.items = _serialize_dissonance_items()
	serialized.dissonance_influencer_purchase_count = dissonance_influencer_purchase_count
	return serialized


func deserialize(data: Dictionary) -> PlayerRunData:
	.deserialize(data)
	dissonance_influencer_purchase_count = int(data.dissonance_influencer_purchase_count) if data.has("dissonance_influencer_purchase_count") else 0
	return self


func _serialize_dissonance_items() -> Array:
	var serialized_items := []
	var serialize_cache := {}
	for item in items:
		if item.is_cursed or item.my_id == COW_HEAD_ITEM_ID:
			serialized_items.push_back(item.serialize())
		else:
			var serialized_item = serialize_cache.get(item.my_id)
			if not serialized_item:
				serialized_item = item.serialize()
				serialize_cache[item.my_id] = serialized_item
			serialized_items.push_back(serialized_item)

	return serialized_items
