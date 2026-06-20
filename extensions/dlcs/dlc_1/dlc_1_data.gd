extends "res://dlcs/dlc_1/dlc_1_data.gd"

const BATON_WEAPON_ID = "weapon_baton"
const BATON_SHIFT_EFFECT_KEY = "effect_baton_stat_shift_every_killed_enemies"
const BATON_CURSE_VALUE_RATE = 0.025
const BATON_REFERENCE_VALUES = {
	Tier.COMMON: 17,
	Tier.UNCOMMON: 34,
	Tier.RARE: 66,
	Tier.LEGENDARY: 130,
}
const BATON_BASE_INTERVALS = {
	Tier.COMMON: 20,
	Tier.UNCOMMON: 18,
	Tier.RARE: 16,
	Tier.LEGENDARY: 12,
}
const CASH_COW_ITEM_IDS = [
	"item_cash_cow",
	"item_cash_cow_rare",
	"item_cash_cow_epic",
	"item_cash_cow_legendary"
]


func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) -> ItemParentData:
	var cursed_item = .curse_item(item_data, player_index, turn_randomization_off, min_modifier)
	if _is_baton(item_data) and cursed_item != item_data:
		_rebalance_cursed_baton(cursed_item)
	elif _is_cash_cow(item_data) and cursed_item != item_data:
		_rebalance_cursed_cash_cow(cursed_item)
	return cursed_item


func _is_baton(item_data: ItemParentData) -> bool:
	return item_data is WeaponData and item_data.weapon_id == BATON_WEAPON_ID


func _is_cash_cow(item_data: ItemParentData) -> bool:
	return item_data != null and item_data is ItemData and CASH_COW_ITEM_IDS.has(item_data.my_id)


func _rebalance_cursed_baton(item_data: ItemParentData) -> void:
	var curse_modifier = max(0.0, item_data.curse_factor)

	for effect in item_data.effects:
		if effect.key_hash == Keys.stat_curse_hash:
			effect.value = _get_baton_curse_value(item_data.tier, curse_modifier)
		elif effect.key == BATON_SHIFT_EFFECT_KEY:
			_apply_baton_shift_curse(effect, item_data.tier, curse_modifier)


func _apply_baton_shift_curse(effect: Effect, tier: int, curse_modifier: float) -> void:
	var base_interval = BATON_BASE_INTERVALS.get(tier, effect.value)
	var base_highest_delta = max(1, int(effect.get("highest_delta")))
	effect.value = int(max(6, floor(base_interval / (1.0 + curse_modifier * 0.5))))
	effect.set("highest_delta", _get_cursed_baton_highest_delta(base_highest_delta, curse_modifier))
	effect.set("lowest_delta", 1 + (1 if curse_modifier >= 0.6 else 0))


func _get_cursed_baton_highest_delta(base_highest_delta: int, curse_modifier: float) -> int:
	return int(max(1, floor(base_highest_delta / (1.0 + curse_modifier))))


func _get_baton_curse_value(tier: int, curse_modifier: float) -> int:
	var reference_value = BATON_REFERENCE_VALUES.get(tier, 34)
	return round(max(1.0, BATON_CURSE_VALUE_RATE * reference_value * (1.0 + curse_modifier))) as int


func _rebalance_cursed_cash_cow(item_data: ItemParentData) -> void:
	var curse_modifier = max(0.0, item_data.curse_factor)

	for effect in item_data.effects:
		if effect.get_id() == "cash_cow":
			effect.set("growth_percent", int(ceil(int(effect.get("growth_percent")) * (1.0 + curse_modifier * 0.5))))
			effect.set("health_boost", float(effect.get("health_boost")) * (1.0 + curse_modifier * 0.25))
