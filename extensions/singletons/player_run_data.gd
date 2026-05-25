extends "res://singletons/player_run_data.gd"

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
		Keys.generate_hash("effect_influencer_bonus_ban_on_purchase"): 0
	})


func duplicate() -> PlayerRunData:
	var copy = .duplicate()
	copy.dissonance_influencer_purchase_count = dissonance_influencer_purchase_count
	return copy


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.dissonance_influencer_purchase_count = dissonance_influencer_purchase_count
	return serialized


func deserialize(data: Dictionary) -> PlayerRunData:
	.deserialize(data)
	dissonance_influencer_purchase_count = int(data.dissonance_influencer_purchase_count) if data.has("dissonance_influencer_purchase_count") else 0
	return self
