extends "res://effects/weapons/gain_stat_every_killed_enemies_effect.gd"

export(int) var highest_delta = 2
export(int) var lowest_delta = 1


static func get_id() -> String:
	return "weapon_baton_stat_shift_every_killed_enemies"


func get_args(_player_index: int) -> Array:
	return [str(value), "-" + str(highest_delta), "+" + str(lowest_delta)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.NEGATIVE, Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.highest_delta = highest_delta
	serialized.lowest_delta = lowest_delta
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	if serialized.has("highest_delta"):
		highest_delta = serialized.highest_delta as int
	if serialized.has("lowest_delta"):
		lowest_delta = serialized.lowest_delta as int
