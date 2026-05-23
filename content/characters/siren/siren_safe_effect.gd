extends "res://items/global/effect.gd"


static func get_id() -> String:
	return "siren_safe_effect"


func apply(player_index: int) -> void:
	if not _can_apply_to_player(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_entries(player_index)
	.apply(player_index)


func unapply(player_index: int) -> void:
	if not _can_apply_to_player(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()
	_ensure_effect_entries(player_index)
	.unapply(player_index)


func _can_apply_to_player(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()


func _ensure_effect_entries(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if key_hash != Keys.empty_hash and not effects.has(key_hash):
		effects[key_hash] = _get_default_effect_value()
	if custom_key_hash != Keys.empty_hash and not effects.has(custom_key_hash):
		effects[custom_key_hash] = []


func _get_default_effect_value():
	match storage_method:
		StorageMethod.KEY_VALUE, StorageMethod.APPEND_KEY, StorageMethod.APPEND_KEY_VALUE:
			return []
		_:
			return 0
