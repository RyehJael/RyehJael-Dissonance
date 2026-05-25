class_name ConchWeapon
extends "res://weapons/ranged/ranged_weapon.gd"

var conch_spawn_cursed_enemy_hash := Keys.generate_hash("effect_conch_spawn_cursed_enemy")


func on_killed_something(thing_killed: Node, hitbox: Hitbox) -> void:
	.on_killed_something(thing_killed, hitbox)

	if not _is_valid_conch_kill(thing_killed):
		return

	for effect in effects:
		if effect != null and effect.key_hash == conch_spawn_cursed_enemy_hash:
			_try_spawn_cursed_enemy(thing_killed, effect.value)


func _try_spawn_cursed_enemy(enemy: Enemy, chance_percent: int) -> void:
	if chance_percent <= 0:
		return
	if not Utils.get_chance_success(clamp(float(chance_percent) / 100.0, 0.0, 1.0)):
		return

	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.has_method("request_dissonance_cursed_enemy_spawn"):
		current_scene.request_dissonance_cursed_enemy_spawn(enemy, player_index)


func _is_valid_conch_kill(thing_killed: Node) -> bool:
	return thing_killed != null and is_instance_valid(thing_killed) and thing_killed is Enemy
