class_name BatonWeapon
extends "res://weapons/melee/melee_weapon.gd"

var baton_shift_effect_hash := Keys.generate_hash("effect_baton_stat_shift_every_killed_enemies")

var _baton_wave_index := -1
var _baton_kills_this_wave := 0


func on_killed_something(_thing_killed: Node, hitbox: Hitbox) -> void:
	var attack_id := hitbox.player_attack_id

	if attack_id >= 0:
		var attack_kill_count = _kill_count_by_attack_id.get(attack_id, 0)
		attack_kill_count += 1
		_kill_count_by_attack_id[attack_id] = attack_kill_count
		for effect in RunData.get_player_effect(Keys.gain_stat_when_attack_killed_enemies_hash, player_index):
			assert (effect[0] is int)
			var stat_hash = effect[0]
			var stat_value = effect[1]
			if attack_kill_count == effect[2]:
				RunData.add_stat(stat_hash, stat_value, player_index)
				if stat_hash == Keys.stat_engineering_hash and RunData.get_player_character(player_index).my_id_hash == Keys.character_dwarf_hash:
					RunData.add_tracked_value(player_index, Keys.character_dwarf_hash, stat_value)

	_enemies_killed_this_wave_count += 1
	_reset_baton_wave_counter_if_needed()
	_baton_kills_this_wave += 1

	for effect in effects:
		if effect is GainStatEveryKilledEnemiesEffect and effect.value > 0:
			if effect.key_hash == baton_shift_effect_hash:
				if _baton_kills_this_wave % effect.value == 0:
					if RunData.apply_primary_stat_shift(player_index, effect.highest_delta, effect.lowest_delta, true):
						emit_signal("tracked_value_updated", effect.lowest_delta)
			elif _enemies_killed_this_wave_count % effect.value == 0:
				assert (effect.stat_hash is int and effect.stat_hash != Keys.empty_hash)
				if RunData.is_stat_gain_disabled(player_index, effect.stat_hash):
					continue
				RunData.add_stat(effect.stat_hash, effect.stat_nb, player_index)
				emit_signal("tracked_value_updated", effect.stat_nb)


func _reset_baton_wave_counter_if_needed() -> void:
	if RunData.current_wave != _baton_wave_index:
		_baton_wave_index = RunData.current_wave
		_baton_kills_this_wave = 0
