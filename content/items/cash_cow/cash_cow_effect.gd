class_name CashCowEffect
extends PetEffect

export(int) var growth_percent := 15
export(int) var player_max_health_percent := 50
export(float) var health_boost := 1.0
export(float) var heal_regen_ratio := 0.5
export(float) var healing_range := 150.0
export(int) var variant_index := 0
export(String) var tracking_item_id := "item_cash_cow"
export(Texture) var shadow_texture = null
export(Texture) var body_texture = null
export(Texture) var head_texture_0 = null
export(Texture) var head_texture_1 = null
var held_materials := 0
var total_collected := 0


static func get_id() -> String:
	return "cash_cow"


func get_args(_player_index: int) -> Array:
	var current_max_health := _get_current_max_health(_player_index)
	var current_health_percent := _get_effective_player_max_health_percent()
	return [str(growth_percent), str(int(round(heal_regen_ratio * 100.0))), str(current_max_health), str(current_health_percent)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.POSITIVE, Sign.POSITIVE, Sign.NEUTRAL]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return load("res://items/materials/material_ui.png") as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.growth_percent = growth_percent
	serialized.player_max_health_percent = player_max_health_percent
	serialized.health_boost = health_boost
	serialized.heal_regen_ratio = heal_regen_ratio
	serialized.healing_range = healing_range
	serialized.variant_index = variant_index
	serialized.tracking_item_id = tracking_item_id
	serialized.held_materials = held_materials
	serialized.total_collected = total_collected
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("growth_percent"):
		growth_percent = int(serialized.growth_percent)
	if serialized.has("variant_index"):
		variant_index = int(serialized.variant_index)
	if serialized.has("player_max_health_percent"):
		player_max_health_percent = int(serialized.player_max_health_percent)
	else:
		player_max_health_percent = _get_default_player_max_health_percent(variant_index)
	if serialized.has("health_boost"):
		health_boost = float(serialized.health_boost)
	if serialized.has("heal_regen_ratio"):
		heal_regen_ratio = float(serialized.heal_regen_ratio)
	if serialized.has("healing_range"):
		healing_range = float(serialized.healing_range)
	if serialized.has("tracking_item_id"):
		tracking_item_id = str(serialized.tracking_item_id)
	if serialized.has("held_materials"):
		held_materials = int(serialized.held_materials)
	if serialized.has("total_collected"):
		total_collected = int(serialized.total_collected)


func _get_current_max_health(player_index: int) -> int:
	var player_max_health := PlayerRunData.DEFAULT_MAX_HP
	if _can_use_player_effects(player_index):
		player_max_health = RunData.get_player_max_health(player_index)
	return int(max(1, int(ceil(player_max_health * (_get_effective_player_max_health_percent() / 100.0)))))


func _get_effective_player_max_health_percent() -> int:
	return int(max(1, int(round(player_max_health_percent * health_boost))))


func _get_default_player_max_health_percent(p_variant_index: int) -> int:
	var default_percentages := [50, 75, 100, 125]
	var index := int(clamp(p_variant_index, 0, default_percentages.size() - 1))
	return int(default_percentages[index])


func _can_use_player_effects(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.players_data.size()
