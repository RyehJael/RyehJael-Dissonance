extends "res://items/global/effect.gd"

const BAN_ICON_PATH = "res://items/challenges/ban_system_icon.png"


static func get_id() -> String:
	return "disturbing_photo_ban_effect"


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
	return []


func get_text(player_index: int, _colored: bool = true) -> String:
	return Text.text(text_key.to_upper(), get_args(player_index), [])


func get_icon(_player_index: int) -> Texture:
	return load(BAN_ICON_PATH) as Texture


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
