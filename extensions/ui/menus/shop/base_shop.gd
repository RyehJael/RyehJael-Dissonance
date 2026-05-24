extends "res://ui/menus/shop/base_shop.gd"

var _poet_curse_shop_reroll_hash = Keys.generate_hash("effect_poet_curse_shop_reroll")


func _on_RerollButton_pressed(player_index: int) -> void:
	var has_poet_reroll = _has_poet_curse_shop_reroll(player_index)
	var reroll_count_before = _reroll_count[player_index]

	if has_poet_reroll:
		_reroll_price[player_index] = 0

	._on_RerollButton_pressed(player_index)

	if not has_poet_reroll or _reroll_count[player_index] <= reroll_count_before:
		return

	var curse_gain = RunData.get_player_effect(_poet_curse_shop_reroll_hash, player_index)
	if curse_gain <= 0:
		return

	RunData.add_stat(Keys.stat_curse_hash, curse_gain, player_index)
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()
	_update_stats(player_index)
	set_reroll_button_price(player_index)


func set_reroll_button_price(player_index: int) -> void:
	.set_reroll_button_price(player_index)

	if not _has_poet_curse_shop_reroll(player_index):
		return

	_reroll_price[player_index] = 0
	_set_poet_reroll_button(player_index)


func _has_poet_curse_shop_reroll(player_index: int) -> bool:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return false
	return RunData.get_player_effect(_poet_curse_shop_reroll_hash, player_index) > 0


func _set_poet_reroll_button(player_index: int) -> void:
	var curse_gain = RunData.get_player_effect(_poet_curse_shop_reroll_hash, player_index)
	var reroll_button = _get_reroll_button(player_index)
	reroll_button.init(0, player_index)

	var text = (tr("REROLL") + " - +" + str(curse_gain)).to_upper()
	if RunData.is_coop_run:
		reroll_button.set_text(text)
	else:
		reroll_button.set_text("      " + text)

	var curse_icon = ItemService.get_stat_small_icon(Keys.stat_curse_hash)
	if curse_icon != null:
		reroll_button.set_material_icon(curse_icon as Texture)
