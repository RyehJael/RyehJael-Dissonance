extends "res://items/global/effect.gd"

export(int) var highest_delta := 5
export(int) var lowest_delta := 3


func get_args(_player_index: int) -> Array:
	return ["-" + str(highest_delta), "+" + str(lowest_delta)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.NEGATIVE, Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.highest_delta = highest_delta
	serialized.lowest_delta = lowest_delta
	return serialized


func deserialize_and_merge(effect: Dictionary) -> void:
	.deserialize_and_merge(effect)
	highest_delta = effect.highest_delta as int if "highest_delta" in effect else highest_delta
	lowest_delta = effect.lowest_delta as int if "lowest_delta" in effect else lowest_delta
