extends ItemData

export(int) var materials_dropped := 0


func _get_tracking_text(_player_index: int) -> String:
	if tracking_text == "[EMPTY]" or tracking_text == "":
		return ""

	return "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(
		tracking_text.to_upper(),
		[Text.get_formatted_number(materials_dropped)]
	) + "[/color]"


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.materials_dropped = materials_dropped
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("materials_dropped"):
		materials_dropped = int(serialized.materials_dropped)
