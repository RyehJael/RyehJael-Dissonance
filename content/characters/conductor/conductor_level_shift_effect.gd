extends "res://items/global/effect.gd"


func get_args(_player_index: int) -> Array:
	return ["-5", "+2"]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.NEGATIVE, Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)
