extends "res://global/screenshaker.gd"

const BATON_WEAPON_ID = "weapon_baton"


func _on_unit_took_damage(unit: Unit, value: int, knockback_direction: Vector2, is_crit: bool, is_dodge: bool, is_protected: bool, armor_did_something: bool, args: TakeDamageArgs, hit_type: int, is_one_shot: bool) -> void:
	if _is_baton_hit(args):
		return

	._on_unit_took_damage(unit, value, knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, args, hit_type, is_one_shot)


func _is_baton_hit(args: TakeDamageArgs) -> bool:
	if args == null or args.hitbox == null:
		return false

	var source = args.hitbox.from
	return is_instance_valid(source) and source.get("weapon_id") == BATON_WEAPON_ID
