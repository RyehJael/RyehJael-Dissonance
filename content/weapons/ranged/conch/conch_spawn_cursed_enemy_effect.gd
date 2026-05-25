extends NullEffect


static func get_id() -> String:
	return "weapon_conch_spawn_cursed_enemy"


func get_args(_player_index: int) -> Array:
	return [str(value)]


func get_text(player_index: int, colored: bool = true) -> String:
	var signs = [] if not colored else [Sign.POSITIVE]
	return Text.text(text_key.to_upper(), get_args(player_index), signs)


func get_icon(_player_index: int) -> Texture:
	return ItemService.get_stat_small_icon(Keys.stat_curse_hash) as Texture
