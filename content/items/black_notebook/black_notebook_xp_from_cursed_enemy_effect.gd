extends "res://items/global/effect.gd"

export(int) var xp_gain := 1
export(float) var curse_chance_scaling := 0.15


static func get_id() -> String:
	return "black_notebook_xp_from_cursed_enemy_effect"


func apply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()

	var effects = RunData.get_player_effects(player_index)
	effects[key_hash] = {
		"base_chance": value,
		"xp_gain": xp_gain,
		"curse_chance_scaling": curse_chance_scaling
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
		_format_chance(_get_xp_chance(player_index)),
		_format_xp_gain(xp_gain),
		Utils.get_scaling_stat_icon_text(Keys.stat_curse_hash, curse_chance_scaling, true)
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.xp_gain = xp_gain
	serialized.curse_chance_scaling = curse_chance_scaling
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("xp_gain"):
		xp_gain = int(serialized.xp_gain)
	if serialized.has("curse_chance_scaling"):
		curse_chance_scaling = float(serialized.curse_chance_scaling)


func _get_xp_chance(player_index: int) -> float:
	if not _can_use_player_effects(player_index):
		return max(0.0, float(value))
	var curse = max(0.0, Utils.get_stat(Keys.stat_curse_hash, player_index))
	return max(0.0, float(value) + curse * curse_chance_scaling)


func _format_chance(chance: float) -> String:
	var rounded_chance = stepify(chance, 0.01)
	if rounded_chance == int(rounded_chance):
		return str(int(rounded_chance))
	return str(rounded_chance)


func _format_xp_gain(gain: int) -> String:
	return "+" + str(gain) if gain >= 0 else str(gain)


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
