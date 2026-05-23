extends "res://singletons/player_run_data.gd"


static func init_effects() -> Dictionary:
	return Utils.merge_dictionaries(.init_effects(), {
		Keys.generate_hash("effect_conductor_level_shift"): 0,
		Keys.generate_hash("effect_siren_spawn_cursed_enemy"): 0,
		Keys.generate_hash("effect_siren_bonus_materials_from_cursed_enemies"): 0,
		Keys.generate_hash("effect_aeonian_round_duration_per_max_hp"): 0,
		Keys.generate_hash("effect_round_duration_bonus"): 0
	})
