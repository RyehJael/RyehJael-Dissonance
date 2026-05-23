extends "res://main.gd"

const CURSE_ENEMY_EFFECT_BEHAVIOR_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior_data.tres"
const CURSE_ENEMY_EFFECT_SCRIPT_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior.gd"
const SIREN_CURSE_HP_BOOST = 200
const SIREN_CURSE_DAMAGE_BOOST = 50
const SIREN_CURSE_SPEED_BOOST = 75
const SIREN_MAX_CURSE_HP_BOOST = 300

var _siren_spawn_cursed_enemy_hash = Keys.generate_hash("effect_siren_spawn_cursed_enemy_from_range")
var _siren_bonus_materials_hash = Keys.generate_hash("effect_siren_bonus_materials_from_cursed_enemies")
var _siren_curse_enemy_effect_behavior_data: Resource = null


func _ready() -> void:
	_siren_curse_enemy_effect_behavior_data = load(CURSE_ENEMY_EFFECT_BEHAVIOR_PATH)
	._ready()


func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
	._on_enemy_died(enemy, args)
	_try_spawn_siren_cursed_enemy(enemy, args)


func spawn_loot(unit: Unit, entity_type: int, args: Entity.DieArgs) -> void:
	.spawn_loot(unit, entity_type, args)
	_try_spawn_siren_cursed_enemy_bonus_material(unit, entity_type, args)


func _try_spawn_siren_cursed_enemy(enemy: Enemy, args: Entity.DieArgs) -> void:
	if _cleaning_up or not args.enemy_killed_by_player:
		return
	if enemy == null or not is_instance_valid(enemy) or enemy is Boss or enemy.is_loot or not enemy.can_be_cursed:
		return

	var player_index = args.killed_by_player_index
	if not _is_valid_siren_player_index(player_index):
		return

	var chance_factor = _get_siren_player_effect(_siren_spawn_cursed_enemy_hash, player_index)
	if chance_factor <= 0:
		return

	var range_stat = max(0.0, Utils.get_stat(Keys.stat_range_hash, player_index))
	var spawn_chance = clamp(range_stat * chance_factor / 10000.0, 0.0, 1.0)
	if not Utils.get_chance_success(spawn_chance):
		return

	_spawn_siren_cursed_enemy(enemy, player_index)


func _spawn_siren_cursed_enemy(enemy: Enemy, player_index: int) -> void:
	if enemy.filename == "":
		return

	var enemy_scene = load(enemy.filename)
	if enemy_scene == null:
		return

	var spawn_pos = _get_siren_spawn_pos(enemy.global_position)
	var spawn_args = EntitySpawner.SpawnEntityArgs.new(spawn_pos, EntityType.ENEMY)
	var spawned_enemy = _entity_spawner.spawn_entity(enemy_scene, spawn_args)
	if spawned_enemy != null and spawned_enemy is Enemy:
		_curse_siren_spawned_enemy(spawned_enemy, player_index)


func _get_siren_spawn_pos(from_pos: Vector2) -> Vector2:
	var spawn_pos = _entity_spawner.get_spawn_pos_in_area(from_pos, 260)
	var tries = 0
	while _entity_spawner.distance_squared_to_closest_player(spawn_pos) < 200 * 200 and tries < 10:
		spawn_pos = _entity_spawner.get_spawn_pos_in_area(from_pos, 260)
		tries += 1
	return spawn_pos


func _curse_siren_spawned_enemy(enemy: Enemy, _player_index: int) -> void:
	if _siren_curse_enemy_effect_behavior_data == null or _siren_curse_enemy_effect_behavior_data.scene == null:
		return
	if _is_cursed_enemy(enemy):
		return

	var enemy_being_cursed_effect_behavior = _siren_curse_enemy_effect_behavior_data.scene.instance()
	enemy.effect_behaviors.add_child(enemy_being_cursed_effect_behavior.init(enemy))

	var boost_args := BoostArgs.new()
	boost_args.hp_boost = SIREN_CURSE_HP_BOOST + min(_get_total_curse(), SIREN_MAX_CURSE_HP_BOOST) * 2
	boost_args.damage_boost = SIREN_CURSE_DAMAGE_BOOST
	boost_args.speed_boost = SIREN_CURSE_SPEED_BOOST
	boost_args.show_outline = false
	enemy.boost(boost_args)
	enemy.can_be_boosted = false


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


func _is_cursed_enemy(unit: Unit) -> bool:
	if unit == null or not ("effect_behaviors" in unit):
		return false

	for effect_behavior in unit.effect_behaviors.get_children():
		var script = effect_behavior.get_script()
		if script != null and script.resource_path == CURSE_ENEMY_EFFECT_SCRIPT_PATH:
			return true

	return false


func _get_total_curse() -> int:
	var curse = 0
	for player_index in RunData.get_player_count():
		if RunData.get_player_effects(player_index).has(Keys.stat_curse_hash):
			curse += Utils.get_stat(Keys.stat_curse_hash, player_index)
	return curse
