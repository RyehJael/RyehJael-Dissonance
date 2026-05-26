class_name CashCowEffect
extends PetEffect

export(int) var growth_percent := 15
export(float) var health_boost := 1.0
var held_materials := 0


static func get_id() -> String:
	return "cash_cow"


func get_args(_player_index: int) -> Array:
	return [str(growth_percent)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return load("res://items/materials/material_ui.png") as Texture


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.growth_percent = growth_percent
	serialized.health_boost = health_boost
	serialized.held_materials = held_materials
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("growth_percent"):
		growth_percent = int(serialized.growth_percent)
	if serialized.has("health_boost"):
		health_boost = float(serialized.health_boost)
	if serialized.has("held_materials"):
		held_materials = int(serialized.held_materials)
