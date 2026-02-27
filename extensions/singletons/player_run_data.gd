extends "res://singletons/player_run_data.gd"


static func init_effects() -> Dictionary:
	return Utils.merge_dictionaries(.init_effects(), {
		Keys.generate_hash("effect_composer_level_shift"): 0
	})
