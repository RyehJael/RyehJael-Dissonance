extends "res://items/global/effect.gd"

const BAN_ICON_PATH = "res://items/challenges/ban_system_icon.png"

export(int) var purchases_required := 10


static func get_id() -> String:
	return "influencer_bonus_ban_effect"


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
	return [str(purchases_required), "+" + str(value)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.NEUTRAL, Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return load(BAN_ICON_PATH) as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.purchases_required = purchases_required
	return serialized


func deserialize_and_merge(effect: Dictionary) -> void:
	.deserialize_and_merge(effect)
	purchases_required = effect.purchases_required as int if "purchases_required" in effect else purchases_required


func _ensure_effect_key(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(key_hash):
		effects[key_hash] = 0


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
