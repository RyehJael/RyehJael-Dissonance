class_name CashCowEffect
extends PetEffect

export(int) var growth_percent := 15
export(int) var max_health := 15
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
	var current_max_health = int(ceil(max_health * health_boost))
	return [str(growth_percent), str(int(round(heal_regen_ratio * 100.0))), str(current_max_health)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE, Sign.POSITIVE, Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return load("res://items/materials/material_ui.png") as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.growth_percent = growth_percent
	serialized.max_health = max_health
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
	if serialized.has("max_health"):
		max_health = int(serialized.max_health)
	if serialized.has("health_boost"):
		health_boost = float(serialized.health_boost)
	if serialized.has("heal_regen_ratio"):
		heal_regen_ratio = float(serialized.heal_regen_ratio)
	if serialized.has("healing_range"):
		healing_range = float(serialized.healing_range)
	if serialized.has("variant_index"):
		variant_index = int(serialized.variant_index)
	if serialized.has("tracking_item_id"):
		tracking_item_id = str(serialized.tracking_item_id)
	if serialized.has("held_materials"):
		held_materials = int(serialized.held_materials)
	if serialized.has("total_collected"):
		total_collected = int(serialized.total_collected)
