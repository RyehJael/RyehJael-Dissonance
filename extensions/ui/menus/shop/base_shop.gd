extends "res://ui/menus/shop/base_shop.gd"

var _poet_curse_shop_reroll_hash = Keys.generate_hash("effect_poet_curse_shop_reroll")
var _influencer_ban_harvesting_hash = Keys.generate_hash("effect_influencer_harvesting_on_ban")
var _influencer_bonus_ban_hash = Keys.generate_hash("effect_influencer_bonus_ban_on_purchase")
var _influencer_character_hash = Keys.generate_hash("character_influencer")
var _influencer_ban_icon = preload("res://items/challenges/ban_system_icon.png")
var _chal_unlock_influencer_hash = Keys.generate_hash("chal_unlock_influencer")
var _dissonance_processing_steal_players := {}


func _on_RerollButton_pressed(player_index: int) -> void:
	var has_poet_reroll = _has_poet_curse_shop_reroll(player_index)
	var reroll_count_before = _reroll_count[player_index]
	var free_rerolls_before = _free_rerolls[player_index]

	if has_poet_reroll:
		_reroll_price[player_index] = 0

	._on_RerollButton_pressed(player_index)

	if not has_poet_reroll or _reroll_count[player_index] <= reroll_count_before:
		return
	if _free_rerolls[player_index] < free_rerolls_before:
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
	if _free_rerolls[player_index] > 0:
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


func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void:
	var is_steal = _dissonance_processing_steal_players.has(player_index)
	.on_shop_item_bought(shop_item, player_index)

	if is_steal:
		return
	_try_add_influencer_purchase(player_index, shop_item)


func on_shop_item_stolen(shop_item: ShopItem, player_index: int) -> void:
	_dissonance_processing_steal_players[player_index] = true
	.on_shop_item_stolen(shop_item, player_index)
	_dissonance_processing_steal_players.erase(player_index)


func on_shop_item_banned(shop_item: ShopItem, player_index: int) -> void:
	.on_shop_item_banned(shop_item, player_index)
	_try_add_influencer_ban_harvesting(player_index)
	_try_complete_influencer_unlock_challenge(player_index)


func _try_add_influencer_ban_harvesting(player_index: int) -> void:
	if not _is_valid_dissonance_player_index(player_index):
		return

	var harvesting_gain = RunData.get_player_effect(_influencer_ban_harvesting_hash, player_index)
	if harvesting_gain <= 0:
		return

	RunData.add_stat(Keys.stat_harvesting_hash, harvesting_gain, player_index)
	RunData.add_tracked_value(player_index, _influencer_character_hash, harvesting_gain)
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()
	_update_stats(player_index)


func _try_add_influencer_purchase(player_index: int, shop_item: ShopItem) -> void:
	if not _is_valid_dissonance_player_index(player_index):
		return
	if RunData.get_player_effect(_influencer_bonus_ban_hash, player_index) <= 0:
		return

	var bonus_ban_effect = _get_influencer_bonus_ban_effect(player_index)
	if bonus_ban_effect == null:
		return

	var purchases_required = max(1, int(bonus_ban_effect.purchases_required))
	var bonus_bans = max(1, int(bonus_ban_effect.value))
	var player_data = RunData.players_data[player_index]
	player_data.dissonance_influencer_purchase_count += 1

	if player_data.dissonance_influencer_purchase_count % purchases_required != 0:
		return

	player_data.remaining_ban_token += bonus_bans
	_get_shop_items_container(player_index).on_ban_update_remaining_token()
	_display_influencer_bonus_ban_icon(shop_item)


func _display_influencer_bonus_ban_icon(shop_item: ShopItem) -> void:
	if shop_item == null:
		return

	var popup_pos = shop_item._button.rect_global_position
	var direction: Vector2

	if RunData.is_coop_run:
		popup_pos.x -= 35
		direction = Vector2(0, -30)
	else:
		popup_pos.x += shop_item._button.rect_size.x / 2.0
		direction = Vector2(25, -100)

	_floating_text_manager.display_shop_icon(_influencer_ban_icon, popup_pos, direction)


func _try_complete_influencer_unlock_challenge(player_index: int) -> void:
	if not _is_valid_dissonance_player_index(player_index):
		return
	if ChallengeService.get_chal(_chal_unlock_influencer_hash) == null:
		return
	ChallengeService.try_complete_challenge(_chal_unlock_influencer_hash, RunData.players_data[player_index].banned_items.size())


func _get_influencer_bonus_ban_effect(player_index: int):
	var character = RunData.get_player_character(player_index)
	if character == null:
		return null

	for effect in character.effects:
		if effect != null and effect.key == "effect_influencer_bonus_ban_on_purchase":
			return effect

	return null


func _is_valid_dissonance_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.get_player_count()
