extends "res://items/global/effect.gd"


static func get_id() -> String:
	return "poet_curse_shop_reroll_effect"


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


func get_args(_player_index: int) -> Array:
	return [ "+" + str(value) if value >= 0 else str(value) ]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.NEGATIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
