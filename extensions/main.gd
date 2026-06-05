extends "res://main.gd"

const CURSE_ENEMY_EFFECT_BEHAVIOR_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior_data.tres"
const CURSE_ENEMY_EFFECT_SCRIPT_PATH = "res://dlcs/dlc_1/effect_behaviors/enemy/curse_enemy_effect_behavior.gd"
const SIREN_CURSE_HP_BOOST = 150
const SIREN_CURSE_DAMAGE_BOOST = 25
const SIREN_CURSE_SPEED_BOOST = 15
const SIREN_MAX_CURSE_HP_BOOST = 300
const SIREN_RANGE_CHANCE_SCALING = 0.04
const SIREN_MAX_SPAWN_CHANCE = 75.0
const SIREN_MIN_SPAWN_DIST_FROM_PLAYER = 300
const AEONIAN_MAX_HP_PER_EXTRA_SECOND = 10
const AEONIAN_EXTRA_TIME_COLOR = Color.deepskyblue
const CASH_COW_PICKUP_PLAYER_INDEX = -7777
const PRODUCER_PET_INDICATOR_SCRIPT = preload("res://mods-unpacked/RyehJael-Dissonance/content/characters/producer/producer_pet_indicator.gd")
const PRODUCER_PET_INDICATOR_NODE_NAME = "DissonanceProducerPetIndicator"
const PRODUCER_PET_AFFINITY_RANGE_SCALING := 0.5

var _siren_spawn_cursed_enemy_hash = Keys.generate_hash("effect_siren_spawn_cursed_enemy")
var _siren_bonus_materials_hash = Keys.generate_hash("effect_siren_bonus_materials_from_cursed_enemies")
var _black_notebook_xp_from_cursed_enemy_hash = Keys.generate_hash("effect_black_notebook_xp_from_cursed_enemy")
var _black_notebook_item_hash = Keys.generate_hash("item_black_notebook")
var _siren_character_hash = Keys.generate_hash("character_siren")
var _influencer_ban_harvesting_hash = Keys.generate_hash("effect_influencer_harvesting_on_ban")
var _influencer_character_hash = Keys.generate_hash("character_influencer")
var _aeonian_round_duration_hash = Keys.generate_hash("effect_aeonian_round_duration_per_max_hp")
var _round_duration_bonus_hash = Keys.generate_hash("effect_round_duration_bonus")
var _producer_pet_affinity_hash = Keys.generate_hash("effect_producer_pet_affinity")
var _producer_character_hash = Keys.generate_hash("character_producer")
var _chal_unlock_aeonian_hash = Keys.generate_hash("chal_unlock_aeonian")
var _chal_unlock_influencer_hash = Keys.generate_hash("chal_unlock_influencer")
var _chal_unlock_siren_hash = Keys.generate_hash("chal_unlock_siren")
var _siren_curse_enemy_effect_behavior_data: Resource = null
var _pending_siren_spawn_sources := {}
var _aeonian_round_duration_bonus = 0
var _dissonance_cursed_enemy_kills_this_wave := [0, 0, 0, 0]
var _producer_pet_affinity_progress := {}
var _producer_affinity_indicators := {}


func _ready() -> void:
	_dissonance_cursed_enemy_kills_this_wave = [0, 0, 0, 0]
	if _resource_exists(CURSE_ENEMY_EFFECT_BEHAVIOR_PATH):
		_siren_curse_enemy_effect_behavior_data = load(CURSE_ENEMY_EFFECT_BEHAVIOR_PATH)
	_try_complete_aeonian_unlock_challenge()
	call_deferred("_apply_round_duration_bonus")


func _physics_process(delta: float) -> void:
	._physics_process(delta)
	_process_producer_pet_affinity(delta)


func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void:
	._on_enemy_died(enemy, args)
	_try_count_dissonance_cursed_enemy_kill(enemy, args)
	_try_gain_black_notebook_xp(enemy, args)
	_try_spawn_siren_cursed_enemy(enemy, args)


func spawn_loot(unit: Unit, entity_type: int, args: Entity.DieArgs) -> void:
	.spawn_loot(unit, entity_type, args)
	_try_spawn_siren_cursed_enemy_bonus_material(unit, entity_type, args)


func on_gold_picked_up(gold: Node, player_index: int) -> void:
	if player_index != CASH_COW_PICKUP_PLAYER_INDEX:
		.on_gold_picked_up(gold, player_index)
		return

	if gold.already_picked_up:
		return

	gold.already_picked_up = true
	_active_golds.erase(gold)
	add_node_to_pool(gold, _gold_pool_id)


func on_item_box_ban_button_pressed(item_data: ItemParentData, consumable: UpgradesUI.ConsumableToProcess) -> void:
	.on_item_box_ban_button_pressed(item_data, consumable)
	_try_add_influencer_ban_harvesting(consumable.player_index)
	_try_complete_influencer_unlock_challenge(consumable.player_index)


func _on_EntitySpawner_enemy_respawned(enemy: Enemy) -> void:
	._on_EntitySpawner_enemy_respawned(enemy)
	_try_curse_pending_siren_spawn(enemy)


func _try_spawn_siren_cursed_enemy(enemy: Enemy, args: Entity.DieArgs) -> void:
	if _cleaning_up or not args.enemy_killed_by_player:
		return
	if _siren_curse_enemy_effect_behavior_data == null:
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
	if _siren_curse_enemy_effect_behavior_data == null:
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


func _try_count_dissonance_cursed_enemy_kill(enemy: Enemy, args: Entity.DieArgs) -> void:
	if _cleaning_up or not args.enemy_killed_by_player:
		return
	if enemy == null or not is_instance_valid(enemy) or not _is_cursed_enemy(enemy):
		return
	if ChallengeService.get_chal(_chal_unlock_siren_hash) == null:
		return

	var player_index = args.killed_by_player_index
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	_ensure_dissonance_cursed_enemy_kill_slot(player_index)
	_dissonance_cursed_enemy_kills_this_wave[player_index] += 1
	ChallengeService.try_complete_challenge(_chal_unlock_siren_hash, _dissonance_cursed_enemy_kills_this_wave[player_index])


func _try_gain_black_notebook_xp(enemy: Enemy, args: Entity.DieArgs) -> void:
	if _cleaning_up or not args.enemy_killed_by_player:
		return
	if enemy == null or not is_instance_valid(enemy) or not _is_cursed_enemy(enemy):
		return

	var player_index = args.killed_by_player_index
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var effect_data = RunData.get_player_effect(_black_notebook_xp_from_cursed_enemy_hash, player_index)
	if not (effect_data is Dictionary):
		return

	var base_chance = max(0.0, float(effect_data.get("base_chance", 0.0)))
	var curse_chance_scaling = max(0.0, float(effect_data.get("curse_chance_scaling", 0.0)))
	var xp_gain = max(0, int(effect_data.get("xp_gain", 0)))
	if base_chance <= 0.0 or xp_gain <= 0:
		return

	var curse = max(0.0, Utils.get_stat(Keys.stat_curse_hash, player_index))
	var chance = max(0.0, base_chance + curse * curse_chance_scaling) / 100.0
	if not Utils.get_chance_success(chance):
		return

	RunData.add_xp(xp_gain, player_index)
	if player_index >= 0 and player_index < RunData.tracked_item_effects.size() and not RunData.tracked_item_effects[player_index].has(_black_notebook_item_hash):
		RunData.tracked_item_effects[player_index][_black_notebook_item_hash] = 0
	RunData.add_tracked_value(player_index, _black_notebook_item_hash, xp_gain)


func _ensure_dissonance_cursed_enemy_kill_slot(player_index: int) -> void:
	if player_index < _dissonance_cursed_enemy_kills_this_wave.size():
		return
	var old_size = _dissonance_cursed_enemy_kills_this_wave.size()
	_dissonance_cursed_enemy_kills_this_wave.resize(player_index + 1)
	for index in range(old_size, _dissonance_cursed_enemy_kills_this_wave.size()):
		_dissonance_cursed_enemy_kills_this_wave[index] = 0


func _try_add_influencer_ban_harvesting(player_index: int) -> void:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var harvesting_gain = _get_siren_player_effect(_influencer_ban_harvesting_hash, player_index)
	if harvesting_gain <= 0:
		return

	RunData.add_stat(Keys.stat_harvesting_hash, harvesting_gain, player_index)
	RunData.add_tracked_value(player_index, _influencer_character_hash, harvesting_gain)
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()


func _process_producer_pet_affinity(delta: float) -> void:
	if _cleaning_up or _entity_spawner == null or not RunData.wave_in_progress:
		_clear_producer_pet_affinity_state()
		return

	var visible_producer_ids := {}
	var has_active_producer := false
	for player_index in RunData.get_player_count():
		var affinity_data = _get_producer_pet_affinity_data(player_index)
		if affinity_data.empty():
			continue

		var player = _get_valid_producer_player(player_index)
		if player == null:
			continue

		var affinity_range = max(0.0, float(affinity_data.get("range", 0.0)) + Utils.get_stat(Keys.stat_range_hash, player_index) * PRODUCER_PET_AFFINITY_RANGE_SCALING)
		var seconds_required = max(0.1, float(affinity_data.get("seconds_required", 10.0)))
		var stat_gain = int(affinity_data.get("stat_gain", 1))
		if affinity_range <= 0.0 or stat_gain == 0:
			continue

		has_active_producer = true
		_ensure_producer_pet_affinity_progress_slot(player_index)

		var active_pet_type_keys := {}
		var has_pet_in_range := false
		var range_sq = affinity_range * affinity_range
		for pet in _get_producer_player_pets(player_index):
			if not _is_valid_producer_pet(pet, player_index):
				continue

			var pet_type_key = _get_producer_pet_type_key(pet)
			active_pet_type_keys[pet_type_key] = true
			if player.global_position.distance_squared_to(pet.global_position) <= range_sq:
				has_pet_in_range = true
				_advance_producer_pet_affinity_progress(player_index, pet, pet_type_key, seconds_required, stat_gain, delta)

		if has_pet_in_range:
			visible_producer_ids[player.get_instance_id()] = player
			_show_producer_affinity_indicator(player, affinity_range)

		_remove_inactive_producer_pet_affinity_progress(player_index, active_pet_type_keys)

	if not has_active_producer:
		_producer_pet_affinity_progress.clear()

	_hide_inactive_producer_affinity_indicators(visible_producer_ids)


func _get_producer_pet_affinity_data(player_index: int) -> Dictionary:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return {}

	var effect = RunData.get_player_effect(_producer_pet_affinity_hash, player_index)
	if effect is Dictionary:
		return effect
	return {}


func _get_valid_producer_player(player_index: int) -> Player:
	if player_index < 0 or player_index >= _players.size():
		return null
	var player = _players[player_index]
	if player == null or not is_instance_valid(player) or player.dead:
		return null
	return player


func _get_producer_player_pets(player_index: int) -> Array:
	var pets := []
	for pet in _entity_spawner.pets:
		if _is_valid_producer_pet(pet, player_index):
			pets.push_back(pet)

	for structure in _entity_spawner.structures:
		if structure != null and is_instance_valid(structure) and bool(structure.get("is_pet")) and _is_valid_producer_pet(structure, player_index):
			pets.push_back(structure)

	var player = _get_valid_producer_player(player_index)
	if player != null:
		for jellyshield in player.jellyshields:
			if _is_valid_producer_pet(jellyshield, player_index):
				pets.push_back(jellyshield)

	return pets


func _is_valid_producer_pet(pet, player_index: int) -> bool:
	if pet == null or not is_instance_valid(pet) or not (pet is Node2D):
		return false
	if bool(pet.get("dead")):
		return false

	var pet_player_index = pet.get("player_index")
	if pet_player_index == null or int(pet_player_index) != player_index:
		return false

	return _get_producer_pet_stat_hash(pet) != Keys.empty_hash


func _ensure_producer_pet_affinity_progress_slot(player_index: int) -> void:
	if not _producer_pet_affinity_progress.has(player_index):
		_producer_pet_affinity_progress[player_index] = {}


func _advance_producer_pet_affinity_progress(player_index: int, pet: Node2D, pet_type_key: String, seconds_required: float, stat_gain: int, delta: float) -> void:
	var stat_hash = _get_producer_pet_stat_hash(pet)
	if stat_hash == Keys.empty_hash or pet_type_key.empty():
		return

	var progress_by_pet_type: Dictionary = _producer_pet_affinity_progress[player_index]
	var progress = float(progress_by_pet_type[pet_type_key]) if progress_by_pet_type.has(pet_type_key) else 0.0
	progress += delta

	var total_gain = 0
	while progress >= seconds_required:
		total_gain += stat_gain
		progress -= seconds_required

	progress_by_pet_type[pet_type_key] = progress

	if total_gain == 0:
		return

	RunData.add_stat(stat_hash, total_gain, player_index)
	if player_index >= 0 and player_index < RunData.tracked_item_effects.size() and not RunData.tracked_item_effects[player_index].has(_producer_character_hash):
		RunData.tracked_item_effects[player_index][_producer_character_hash] = 0
	RunData.add_tracked_value(player_index, _producer_character_hash, total_gain)
	LinkedStats.reset_player(player_index)
	EntityService.reset_cache()


func _remove_inactive_producer_pet_affinity_progress(player_index: int, active_pet_type_keys: Dictionary) -> void:
	if not _producer_pet_affinity_progress.has(player_index):
		return

	var progress_by_pet_type: Dictionary = _producer_pet_affinity_progress[player_index]
	for pet_type_key in progress_by_pet_type.keys():
		if not active_pet_type_keys.has(pet_type_key):
			progress_by_pet_type.erase(pet_type_key)


func _get_producer_pet_stat_hash(pet) -> int:
	var script_name = _get_producer_object_script_name(pet)
	match script_name:
		"ratzilla":
			return Keys.stat_max_hp_hash
		"blazemander":
			return Keys.stat_elemental_damage_hash
		"bonk_dog":
			return Keys.stat_melee_damage_hash
		"bot_o_mine":
			return Keys.stat_engineering_hash
		"catling_gun":
			return Keys.stat_ranged_damage_hash
		"doc_moth":
			return Keys.stat_hp_regeneration_hash
		"lootworm":
			return Keys.stat_harvesting_hash
		"scapegoat":
			return Keys.stat_armor_hash
		"jellyshield":
			return Keys.stat_luck_hash
		"wandering_bot":
			return Keys.stat_speed_hash
		"cash_cow":
			return Keys.stat_harvesting_hash

	return _infer_producer_pet_stat_hash(pet)


func _get_producer_pet_type_key(pet) -> String:
	var script = pet.get_script()
	if script != null and not script.resource_path.empty():
		return script.resource_path

	var filename = pet.get("filename")
	if filename is String and not filename.empty():
		return filename

	return str(_get_producer_pet_stat_hash(pet))


func _infer_producer_pet_stat_hash(pet) -> int:
	if not pet.has_method("get_stats"):
		return Keys.empty_hash

	var best_stat_hash = Keys.empty_hash
	var best_scaling_weight = -1.0
	for stats_resource in pet.get_stats():
		if stats_resource == null:
			continue
		var scaling_stats = stats_resource.get("scaling_stats")
		if not (scaling_stats is Array):
			continue

		for scaling_stat in scaling_stats:
			if not (scaling_stat is Array) or scaling_stat.size() < 2:
				continue
			if not (scaling_stat[0] is String):
				continue

			var stat_hash = Keys.generate_hash(scaling_stat[0])
			if not Utils.is_stat_key(stat_hash):
				continue

			var scaling_weight = abs(float(scaling_stat[1]))
			if scaling_weight > best_scaling_weight:
				best_stat_hash = stat_hash
				best_scaling_weight = scaling_weight

	return best_stat_hash


func _get_producer_object_script_name(object) -> String:
	var script = object.get_script()
	if script == null:
		return ""
	return script.resource_path.get_file().get_basename()


func _show_producer_affinity_indicator(producer: Node2D, affinity_range: float) -> void:
	var indicator = _get_or_create_producer_affinity_indicator(producer)
	if indicator == null:
		return

	indicator.call("setup", affinity_range)
	indicator.show()
	_producer_affinity_indicators[producer.get_instance_id()] = producer


func _get_or_create_producer_affinity_indicator(producer: Node2D) -> Node2D:
	var indicator: Node2D = null
	if producer.has_node(PRODUCER_PET_INDICATOR_NODE_NAME):
		indicator = producer.get_node(PRODUCER_PET_INDICATOR_NODE_NAME) as Node2D
	else:
		indicator = Node2D.new()
		indicator.name = PRODUCER_PET_INDICATOR_NODE_NAME
		indicator.z_index = 100
		indicator.set_script(PRODUCER_PET_INDICATOR_SCRIPT)
		producer.add_child(indicator)

	return indicator


func _hide_inactive_producer_affinity_indicators(visible_producer_ids: Dictionary) -> void:
	for producer_id in _producer_affinity_indicators.keys():
		var producer = _producer_affinity_indicators[producer_id]
		if visible_producer_ids.has(producer_id) and producer != null and is_instance_valid(producer):
			continue

		_hide_producer_affinity_indicator(producer)
		_producer_affinity_indicators.erase(producer_id)


func _hide_producer_affinity_indicator(producer) -> void:
	if producer == null or not is_instance_valid(producer) or not (producer is Node):
		return
	if not producer.has_node(PRODUCER_PET_INDICATOR_NODE_NAME):
		return
	producer.get_node(PRODUCER_PET_INDICATOR_NODE_NAME).hide()


func _clear_producer_pet_affinity_state() -> void:
	_producer_pet_affinity_progress.clear()
	_hide_inactive_producer_affinity_indicators({})


func _try_complete_aeonian_unlock_challenge() -> void:
	var challenge = ChallengeService.get_chal(_chal_unlock_aeonian_hash)
	if challenge == null:
		return
	if RunData.current_wave >= challenge.value:
		ChallengeService.complete_challenge(_chal_unlock_aeonian_hash)


func _try_complete_influencer_unlock_challenge(player_index: int) -> void:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return
	if ChallengeService.get_chal(_chal_unlock_influencer_hash) == null:
		return
	ChallengeService.try_complete_challenge(_chal_unlock_influencer_hash, RunData.players_data[player_index].banned_items.size())


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
	return min(SIREN_MAX_SPAWN_CHANCE, base_chance + range_bonus)


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


func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)
