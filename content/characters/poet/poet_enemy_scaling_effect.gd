extends "res://items/global/effect.gd"

export(int) var nb_stat_scaled = 1


static func get_id() -> String:
	return "poet_enemy_scaling_effect"


func apply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.apply(player_index)
	_add_enemy_scaling_links(player_index)


func unapply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_key(player_index)
	.unapply(player_index)
	_remove_enemy_scaling_links(player_index)


func get_args(player_index: int) -> Array:
	return [
		"+" + str(value) if value >= 0 else str(value),
		str(nb_stat_scaled),
		tr("STAT_CURSE"),
		"+" + str(_get_current_enemy_scaling(player_index))
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.NEGATIVE, Sign.NEUTRAL, Sign.NEUTRAL, Sign.NEGATIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture


func _add_enemy_scaling_links(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[Keys.stat_links_hash].push_back(_get_enemy_scaling_link(Keys.enemy_health_hash))
	effects[Keys.stat_links_hash].push_back(_get_enemy_scaling_link(Keys.enemy_damage_hash))
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()


func _remove_enemy_scaling_links(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[Keys.stat_links_hash].erase(_get_enemy_scaling_link(Keys.enemy_health_hash))
	effects[Keys.stat_links_hash].erase(_get_enemy_scaling_link(Keys.enemy_damage_hash))
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()


func _get_enemy_scaling_link(stat_hash: int) -> Array:
	return [stat_hash, value, Keys.stat_curse_hash, nb_stat_scaled, true]


func _get_current_enemy_scaling(player_index: int) -> int:
	if not _can_use_player_effects(player_index):
		return 0
	var curse = max(0.0, RunData.get_stat(Keys.stat_curse_hash, player_index))
	return int(floor(curse / nb_stat_scaled)) * value


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
