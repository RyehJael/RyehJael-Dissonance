extends "res://main.gd"

const CURSE_ENEMY_EFFECT_BEHAVIOR_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior_data.tres"
const CURSE_ENEMY_EFFECT_SCRIPT_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior.gd"
const SIREN_CURSE_HP_BOOST = 150
const SIREN_CURSE_DAMAGE_BOOST = 25
const SIREN_CURSE_SPEED_BOOST = 15
const SIREN_MAX_CURSE_HP_BOOST = 300
const SIREN_RANGE_CHANCE_SCALING = 0.04
const SIREN_MIN_SPAWN_DIST_FROM_PLAYER = 300
const AEONIAN_MAX_HP_PER_EXTRA_SECOND = 10
const AEONIAN_EXTRA_TIME_COLOR = Color.deepskyblue

var _siren_spawn_cursed_enemy_hash = Keys.generate_hash("effect_siren_spawn_cursed_enemy")
var _siren_bonus_materials_hash = Keys.generate_hash("effect_siren_bonus_materials_from_cursed_enemies")
var _siren_character_hash = Keys.generate_hash("character_siren")
var _aeonian_round_duration_hash = Keys.generate_hash("effect_aeonian_round_duration_per_max_hp")
var _round_duration_bonus_hash = Keys.generate_hash("effect_round_duration_bonus")
var _siren_curse_enemy_effect_behavior_data: Resource = null
var _pending_siren_spawn_sources := {}
var _aeonian_round_duration_bonus = 0


func _ready() -> void:
	_siren_curse_enemy_effect_behavior_data = load(CURSE_ENEMY_EFFECT_BEHAVIOR_PATH)
	call_deferred("_apply_round_duration_bonus")


func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
	._on_enemy_died(enemy, args)
	_try_spawn_siren_cursed_enemy(enemy, args)


func spawn_loot(unit: Unit, entity_type: int, args: Entity.DieArgs) -> void:
	.spawn_loot(unit, entity_type, args)
	_try_spawn_siren_cursed_enemy_bonus_material(unit, entity_type, args)


func _on_EntitySpawner_enemy_respawned(enemy: Enemy) -> void:
	._on_EntitySpawner_enemy_respawned(enemy)
	_try_curse_pending_siren_spawn(enemy)


func _try_spawn_siren_cursed_enemy(enemy: Enemy, args: Entity.DieArgs) -> void:
	if _cleaning_up or not args.enemy_killed_by_player:
		return
	if enemy == null or not is_instance_valid(enemy) or enemy is Boss or enemy.is_loot or not enemy.can_be_cursed:
		return

	var player_index = args.killed_by_player_index
	if not _is_valid_siren_player_index(player_index):
		return

	var chance_percent = _get_siren_spawn_cursed_enemy_chance(player_index)
	if chance_percent <= 0:
		return

	var spawn_chance = clamp(chance_percent / 100.0, 0.0, 1.0)
	if not Utils.get_chance_success(spawn_chance):
		return

	_spawn_siren_cursed_enemy(enemy, player_index)


func request_dissonance_cursed_enemy_spawn(enemy: Enemy, player_index: int) -> void:
	if _cleaning_up:
		return
	if enemy == null or not is_instance_valid(enemy) or enemy is Boss or enemy.is_loot or not enemy.can_be_cursed:
		return
	if not _is_valid_siren_player_index(player_index):
		return

	_spawn_siren_cursed_enemy(enemy, player_index)


func _spawn_siren_cursed_enemy(enemy: Enemy, player_index: int) -> void:
	if enemy.filename == "":
		return

	var enemy_scene = load(enemy.filename)
	if enemy_scene == null:
		return

	var source_marker = Reference.new()
	_pending_siren_spawn_sources[source_marker.get_instance_id()] = [source_marker, player_index]
	_entity_spawner.spawn_entity_birth(EntityType.ENEMY, enemy_scene, _get_siren_spawn_pos(), null, -1, source_marker)


func _get_siren_spawn_pos() -> Vector2:
	var spawn_pos = _entity_spawner.get_spawn_pos_in_area(Vector2.ZERO, -1)
	var min_dist_from_player = SIREN_MIN_SPAWN_DIST_FROM_PLAYER
	var tries = 0
	while _entity_spawner.distance_squared_to_closest_player(spawn_pos) < min_dist_from_player * min_dist_from_player and tries < 60:
		spawn_pos = _entity_spawner.get_spawn_pos_in_area(Vector2.ZERO, -1)
		min_dist_from_player = max(25, min_dist_from_player - 5) as int
		tries += 1
	return spawn_pos


func _try_curse_pending_siren_spawn(enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.source_spawner == null:
		return

	var source_id = enemy.source_spawner.get_instance_id()
	if not _pending_siren_spawn_sources.has(source_id):
		return

	var pending_spawn = _pending_siren_spawn_sources[source_id]
	_pending_siren_spawn_sources.erase(source_id)
	enemy.set_source(null)

	var player_index = pending_spawn[1]
	if _is_valid_siren_player_index(player_index):
		if _curse_siren_spawned_enemy(enemy, player_index):
			_add_siren_spawn_tracked_value(player_index)


func _curse_siren_spawned_enemy(enemy: Enemy, player_index: int) -> bool:
	if _siren_curse_enemy_effect_behavior_data == null or _siren_curse_enemy_effect_behavior_data.scene == null:
		return false
	if _is_cursed_enemy(enemy):
		return false

	enemy.can_be_cursed = false
	enemy.call_deferred("set", "can_be_cursed", true)

	var enemy_being_cursed_effect_behavior = _siren_curse_enemy_effect_behavior_data.scene.instance()
	enemy.effect_behaviors.add_child(enemy_being_cursed_effect_behavior.init(enemy))

	var curse_value = _get_siren_spawned_enemy_curse_value(player_index)
	var boost_args := BoostArgs.new()
	boost_args.hp_boost = SIREN_CURSE_HP_BOOST + min(curse_value, SIREN_MAX_CURSE_HP_BOOST) * 2
	boost_args.damage_boost = SIREN_CURSE_DAMAGE_BOOST
	boost_args.speed_boost = SIREN_CURSE_SPEED_BOOST
	boost_args.show_outline = false
	enemy.boost(boost_args)
	enemy.can_be_boosted = false
	return true


func _get_siren_spawned_enemy_curse_value(player_index: int) -> int:
	if not _is_valid_siren_player_index(player_index):
		return 1
	var player_curse := int(Utils.get_stat(Keys.stat_curse_hash, player_index))
	if player_curse <= 0:
		return 1
	return player_curse


func _add_siren_spawn_tracked_value(player_index: int) -> void:
	if player_index < 0 or player_index >= RunData.tracked_item_effects.size():
		return
	if not RunData.tracked_item_effects[player_index].has(_siren_character_hash):
		RunData.tracked_item_effects[player_index][_siren_character_hash] = 0
	RunData.add_tracked_value(player_index, _siren_character_hash, 1)


func _try_spawn_siren_cursed_enemy_bonus_material(unit: Unit, entity_type: int, args: Entity.DieArgs) -> void:
	if _cleaning_up or entity_type != EntityType.ENEMY or unit == null or not unit.can_drop_loot or not _is_cursed_enemy(unit):
		return

	var player_index = args.killed_by_player_index
	if not _is_valid_siren_player_index(player_index):
		return

	var bonus_materials = _get_siren_player_effect(_siren_bonus_materials_hash, player_index)
	if bonus_materials <= 0:
		return

	spawn_gold(bonus_materials, unit.global_position, unit.stats.gold_spread)


func _is_valid_siren_player_index(player_index: int) -> bool:
	return player_index >= 0 and player_index < RunData.get_player_count()


func _get_siren_player_effect(effect_hash: int, player_index: int) -> int:
	var effects = RunData.get_player_effects(player_index)
	if not effects.has(effect_hash):
		effects[effect_hash] = 0
	return effects[effect_hash]


func _get_siren_spawn_cursed_enemy_chance(player_index: int) -> float:
	var base_chance = _get_siren_player_effect(_siren_spawn_cursed_enemy_hash, player_index)
	if base_chance <= 0:
		return 0.0
	var range_bonus = max(0.0, Utils.get_stat(Keys.stat_range_hash, player_index) * SIREN_RANGE_CHANCE_SCALING)
	return base_chance + range_bonus


func _apply_round_duration_bonus() -> void:
	if _cleaning_up or _wave_timer == null:
		return

	_aeonian_round_duration_bonus = _get_aeonian_round_duration_bonus()
	var flat_duration_bonus = _get_flat_round_duration_bonus()
	var total_duration_bonus = _aeonian_round_duration_bonus + flat_duration_bonus
	if total_duration_bonus <= 0:
		return

	var current_time_left = _wave_timer.time_left
	_wave_timer.wait_time += total_duration_bonus
	if not _wave_timer.is_stopped():
		_wave_timer.start(max(0.1, current_time_left + total_duration_bonus))
	if _aeonian_round_duration_bonus > 0:
		_schedule_aeonian_extra_time_color(current_time_left + flat_duration_bonus)


func _schedule_aeonian_extra_time_color(base_time_left: float) -> void:
	if base_time_left <= 0.1:
		call_deferred("_on_aeonian_extra_time_started")
		return

	var extra_time_timer = get_tree().create_timer(base_time_left, false)
	extra_time_timer.connect("timeout", self, "_on_aeonian_extra_time_started")


func _on_aeonian_extra_time_started() -> void:
	if _cleaning_up or _wave_timer == null or _wave_timer_label == null:
		return
	if not is_instance_valid(_wave_timer) or not is_instance_valid(_wave_timer_label):
		return
	if _aeonian_round_duration_bonus <= 0 or _wave_timer.is_stopped():
		return

	_wave_timer_label.change_color(AEONIAN_EXTRA_TIME_COLOR)


func _get_aeonian_round_duration_bonus() -> int:
	var duration_bonus = 0
	for player_index in RunData.get_player_count():
		var seconds_per_chunk = _get_siren_player_effect(_aeonian_round_duration_hash, player_index)
		if seconds_per_chunk <= 0:
			continue
		var max_hp = max(0.0, RunData.get_stat(Keys.stat_max_hp_hash, player_index))
		duration_bonus += int(floor(max_hp / float(AEONIAN_MAX_HP_PER_EXTRA_SECOND))) * seconds_per_chunk
	return duration_bonus


func _get_flat_round_duration_bonus() -> int:
	var duration_bonus = 0
	for player_index in RunData.get_player_count():
		duration_bonus += _get_siren_player_effect(_round_duration_bonus_hash, player_index)
	return duration_bonus


func _is_cursed_enemy(unit: Unit) -> bool:
	if unit == null or not ("effect_behaviors" in unit):
		return false

	for effect_behavior in unit.effect_behaviors.get_children():
		var script = effect_behavior.get_script()
		if script != null and script.resource_path == CURSE_ENEMY_EFFECT_SCRIPT_PATH:
			return true

	return false
