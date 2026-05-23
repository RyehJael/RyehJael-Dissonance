extends "res://items/global/effect.gd"

const RANGE_CHANCE_SCALING = 0.03


static func get_id() -> String:
	return "siren_spawn_cursed_enemy_effect"


func apply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.apply(player_index)


func unapply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.unapply(player_index)


func get_args(player_index: int) -> Array:
	return [
		_format_chance(_get_spawn_chance(player_index)),
		Utils.get_scaling_stat_icon_text(Keys.stat_range_hash, RANGE_CHANCE_SCALING, true)
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()


func _get_spawn_chance(player_index: int) -> float:
	if not _can_use_player_effects(player_index):
		return float(value)
	return float(value) + max(0.0, Utils.get_stat(Keys.stat_range_hash, player_index) * RANGE_CHANCE_SCALING)


func _format_chance(chance: float) -> String:
	var rounded_chance = stepify(chance, 0.01)
	if rounded_chance == int(rounded_chance):
		return str(int(rounded_chance))
	return str(rounded_chance)
