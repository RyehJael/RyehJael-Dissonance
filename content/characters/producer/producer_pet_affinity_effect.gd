extends "res://items/global/effect.gd"

const RANGE_SCALING := 1.0

export(float) var seconds_required := 10.0
export(int) var stat_gain := 1


static func get_id() -> String:
	return "producer_pet_affinity_effect"


func apply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()

	var effects = RunData.get_player_effects(player_index)
	effects[key_hash] = {
		"range": value,
		"seconds_required": seconds_required,
		"stat_gain": stat_gain
	}
	Utils.reset_stat_cache(player_index)


func unapply(player_index: int) -> void:
	if not _can_use_player_effects(player_index):
		return
	if key_hash == Keys.empty_hash and key != "":
		_generate_hashes()

	var effects = RunData.get_player_effects(player_index)
	effects.erase(key_hash)
	Utils.reset_stat_cache(player_index)


func get_args(player_index: int) -> Array:
	return [
		_format_range(_get_current_range(player_index)),
		_format_seconds(seconds_required),
		_format_stat_gain(stat_gain),
		Utils.get_scaling_stat_icon_text(Keys.stat_range_hash, RANGE_SCALING, true)
	]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.NEUTRAL, Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return load("res://items/all/ratzilla/ratzilla_icon.png") as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.seconds_required = seconds_required
	serialized.stat_gain = stat_gain
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("seconds_required"):
		seconds_required = float(serialized.seconds_required)
	if serialized.has("stat_gain"):
		stat_gain = int(serialized.stat_gain)


func _format_seconds(seconds: float) -> String:
	if seconds == int(seconds):
		return str(int(seconds))
	return str(stepify(seconds, 0.01))


func _format_range(range_value: float) -> String:
	var rounded_range = stepify(range_value, 0.01)
	if rounded_range == int(rounded_range):
		return str(int(rounded_range))
	return str(rounded_range)


func _format_stat_gain(gain: int) -> String:
	return "+" + str(gain) if gain >= 0 else str(gain)


func _get_current_range(player_index: int) -> float:
	if not _can_use_player_effects(player_index):
		return float(value)
	return max(0.0, float(value) + Utils.get_stat(Keys.stat_range_hash, player_index) * RANGE_SCALING)


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
