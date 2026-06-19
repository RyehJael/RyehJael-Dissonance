extends "res://items/global/effect.gd"

export(float) var bonus_xp_per_curse := 0.02


static func get_id() -> String:
	return "black_notebook_xp_from_cursed_enemy_effect"


func apply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()

	var effects = RunData.get_player_effects(player_index)
	effects[key_hash] = {
		"bonus_xp_per_curse": bonus_xp_per_curse
	}
	Utils.reset_stat_cache(player_index)


func unapply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()

	var effects = RunData.get_player_effects(player_index)
	effects.erase(key_hash)
	Utils.reset_stat_cache(player_index)


func get_args(player_index: int) -> Array:
	return [
		_format_number(_get_bonus_xp_value(player_index)),
		_format_bonus_xp_formula()
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.bonus_xp_per_curse = bonus_xp_per_curse
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("bonus_xp_per_curse"):
		bonus_xp_per_curse = float(serialized.bonus_xp_per_curse)


func _format_bonus_xp_formula() -> String:
	return Utils.get_scaling_stat_icon_text(Keys.stat_curse_hash, bonus_xp_per_curse, false)


func _get_bonus_xp_value(player_index: int) -> float:
	if not _can_use_player_effects(player_index):
		return 0.0
	var curse = max(0.0, Utils.get_stat(Keys.stat_curse_hash, player_index))
	return max(0.0, curse * bonus_xp_per_curse)


func _format_number(value: float) -> String:
	var rounded_value = stepify(value, 0.01)
	if rounded_value == int(rounded_value):
		return str(int(rounded_value))
	return str(rounded_value)


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
