extends "res://items/global/effect.gd"

export(int) var nb_stat_scaled = 10


static func get_id() -> String:
	return "aeonian_round_duration_effect"


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
		_format_seconds(value),
		str(nb_stat_scaled),
		_format_seconds(_get_current_bonus(player_index)),
		str(_get_current_max_hp(player_index))
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.NEUTRAL, Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_max_hp_hash) as Texture


func _get_current_bonus(player_index: int) -> int:
	return int(floor(_get_current_max_hp(player_index) / float(nb_stat_scaled))) * value


func _get_current_max_hp(player_index: int) -> int:
	return int(max(0.0, RunData.get_stat(Keys.stat_max_hp_hash, player_index)))


func _format_seconds(seconds: int) -> String:
	return "+" + str(seconds) if seconds >= 0 else str(seconds)


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
