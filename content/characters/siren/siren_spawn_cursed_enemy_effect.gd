extends "res://items/global/effect.gd"


static func get_id() -> String:
	return "siren_spawn_cursed_enemy_effect"


func apply(player_index: int) -> void:
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.apply(player_index)


func unapply(player_index: int) -> void:
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.unapply(player_index)


func get_args(player_index: int) -> Array:
	var range_stat = max(0.0, Utils.get_stat(Keys.stat_range_hash, player_index))
	var chance = stepify(range_stat * value / 100.0, 0.01)
	return [str(chance), str(value), tr("STAT_RANGE")]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_range_hash)


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0
