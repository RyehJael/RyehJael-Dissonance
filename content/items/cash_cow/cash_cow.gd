class_name CashCow
extends Pet

const CASH_COW_PICKUP_PLAYER_INDEX := -7777
const INVULNERABLE_COOLDOWN := 0.6
const CASH_COW_DEFAULT_SHADOW := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_shadow.png")
const CASH_COW_DEFAULT_BODY := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_body.png")
const CASH_COW_DEFAULT_HEAD_0 := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_head_0.png")
const CASH_COW_DEFAULT_HEAD_1 := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_head_1.png")
const HEAD_TEXTURE_TRACK := "Animation/Viewport/offset/sp_body/sp_head:texture"
const COW_HEAD_ITEM_ID := "item_cow_head"
const CASH_COW_VARIANT_ITEM_IDS := [
	"item_cash_cow",
	"item_cash_cow_rare",
	"item_cash_cow_epic",
	"item_cash_cow_legendary"
]
const CASH_COW_VARIANT_THRESHOLDS := [0, 50, 150, 400]

export(AudioStream) var sound_dying
export(AudioStream) var sound_rising
export(AudioStream) var sound_pet

var growth_percent := 15
var heal_regen_ratio := 0.5
var healing_range := 150.0
var held_materials := 0
var _effect = null
var _invulnerable_cooldown := 0.0
var _healing_players := []
var _healing_timer := FixedTimer.new()
var _healing_movement_locked := false
var _can_move_before_healing := true
var _mode_before_healing := RigidBody2D.MODE_CHARACTER
var _head_animations_localized := false
var _shadow_texture: Texture = CASH_COW_DEFAULT_SHADOW
var _body_texture: Texture = CASH_COW_DEFAULT_BODY
var _head_texture_0: Texture = CASH_COW_DEFAULT_HEAD_0
var _head_texture_1: Texture = CASH_COW_DEFAULT_HEAD_1

onready var life_bar = $"%LifeBar" as UIProgressBar


func _ready() -> void:
	_reset_pet_ready_signal_connections()
	._ready()
	_replace_head_animation_textures()
	_apply_cash_cow_textures()
	_animation_player.play("move")
	if is_connected("health_updated", self, "on_health_updated"):
		disconnect("health_updated", self, "on_health_updated")
	var _error_hp_lifebar = connect("health_updated", self, "on_health_updated")


func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_effect = effect
	growth_percent = int(effect.get("growth_percent"))
	heal_regen_ratio = float(effect.get("heal_regen_ratio"))
	healing_range = float(effect.get("healing_range"))
	held_materials = int(effect.get("held_materials"))
	_apply_effect_textures(effect)
	_apply_effect_stats(false)
	_update_healing_range()
	_sync_tracking()
	emit_signal("health_updated", self, current_stats.health, max_stats.health)


func on_health_updated(_unit: Unit, current_val: int, max_val: int) -> void:
	if max_val <= 0:
		return

	if ProgressData.settings.hp_bar_on_bosses:
		if not life_bar.visible:
			life_bar.show()
		life_bar.update_value(current_val, max_val)
	elif life_bar.visible:
		life_bar.hide()


func _physics_process(delta: float) -> void:
	if _end_of_wave or dead:
		return

	_process_healing(delta)
	._physics_process(delta)

	if _invulnerable_cooldown > 0:
		_invulnerable_cooldown = max(_invulnerable_cooldown - delta, 0.0)
	elif _hurtbox.is_disabled():
		_hurtbox.enable()


func _on_ItemAttractArea_area_entered(item: Item) -> void:
	if dead or not item is Gold:
		return
	if item.already_picked_up:
		return
	if item.attracted_by == null or item.attracted_by == self:
		item.attracted_by = self


func _on_ItemPickUpArea_area_entered(area: Area2D) -> void:
	if dead or not area is Gold:
		return

	var gold = area as Gold
	if gold.already_picked_up:
		return

	var collected_value := int(gold.value)
	_set_held_materials(held_materials + collected_value)
	_add_collected_materials(collected_value)
	gold.pickup(CASH_COW_PICKUP_PLAYER_INDEX)
	current_target = null
	update_target()


func _on_Hurtbox_area_entered(hitbox: Area2D) -> void:
	if dead or _invulnerable_cooldown > 0.0:
		return
	if not hitbox.active or hitbox.ignored_objects.has(self):
		return

	var dmg_taken = [0, 0]
	var from = hitbox.from if is_instance_valid(hitbox.from) else null
	var from_player_index = from.player_index if (from != null and "player_index" in from) else RunData.DUMMY_PLAYER_INDEX

	if hitbox.deals_damage:
		var args := TakeDamageArgs.new(from_player_index, hitbox)
		args.from = from
		dmg_taken = take_damage(1, args)

	hitbox.hit_something(self, dmg_taken[1])
	_hurtbox.disable()
	_invulnerable_cooldown = INVULNERABLE_COOLDOWN


func die(args := Entity.DieArgs.new()) -> void:
	_can_move = false
	_healing_timer.stop()
	_healing_players.clear()
	_healing_movement_locked = false

	if args.cleaning_up:
		_end_of_wave = true
		return

	if dead:
		return

	dead = true
	_pending_die = true
	_hurtbox.disable()
	_disable_item_areas()

	var dropped_materials := held_materials
	_drop_held_materials()
	_release_attracted_gold()
	_transform_into_cow_head(dropped_materials)
	SoundManager.play(sound_dying, 0, 0.1)
	emit_signal("died", self, args)
	_remove_from_map()


func end_of_wave_callback() -> void:
	if not dead and held_materials > 0:
		var bonus = int(ceil(held_materials * (growth_percent / 100.0)))
		_set_held_materials(held_materials + bonus)
	if _healing_movement_locked:
		_set_healing_movement_locked(false)
	_healing_timer.stop()
	.end_of_wave_callback()


func _drop_held_materials() -> void:
	if held_materials <= 0:
		return

	var main = get_tree().current_scene
	if main != null and main.has_method("spawn_gold"):
		main.spawn_gold(float(held_materials), global_position, min(300, 80 + held_materials * 4))
	_set_held_materials(0)


func _set_held_materials(value: int) -> void:
	held_materials = max(0, value)
	if _effect != null:
		_effect.held_materials = held_materials
	_sync_tracking()


func _sync_tracking() -> void:
	if player_index >= 0 and player_index < RunData.get_player_count():
		var tracking_item_id := "item_cash_cow"
		if _effect != null and _effect.get("tracking_item_id") != null:
			tracking_item_id = str(_effect.get("tracking_item_id"))
		RunData.set_tracked_value(player_index, Keys.generate_hash(tracking_item_id), held_materials)


func _add_collected_materials(value: int) -> void:
	if value <= 0 or _effect == null:
		return

	_effect.total_collected = max(0, int(_effect.get("total_collected")) + value)
	_try_upgrade_variant()


func _try_upgrade_variant() -> void:
	if _effect == null:
		return
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var current_variant = clamp(int(_effect.get("variant_index")), 0, CASH_COW_VARIANT_ITEM_IDS.size() - 1)
	var target_variant := _get_variant_index_for_total(int(_effect.get("total_collected")))
	if target_variant <= current_variant:
		return

	_replace_owned_cash_cow(target_variant)


func _get_variant_index_for_total(total_collected: int) -> int:
	var target_variant := 0
	for index in CASH_COW_VARIANT_THRESHOLDS.size():
		if total_collected >= int(CASH_COW_VARIANT_THRESHOLDS[index]):
			target_variant = index
	return target_variant


func _replace_owned_cash_cow(target_variant: int) -> void:
	var current_item := _get_owned_cash_cow_item()
	if current_item == null:
		return

	var target_item_id = CASH_COW_VARIANT_ITEM_IDS[target_variant]
	if current_item.my_id == target_item_id:
		_effect.variant_index = target_variant
		_apply_effect_stats(true)
		return

	var target_template = ItemService.get_item_from_id(Keys.generate_hash(target_item_id))
	if target_template == null:
		return

	var target_item = target_template.duplicate(true) as ItemData
	var target_effect = _get_cash_cow_effect(target_item)
	if target_item == null or target_effect == null:
		return

	target_item.is_cursed = current_item.is_cursed
	target_item.curse_factor = current_item.curse_factor
	if target_item.is_cursed:
		_apply_curse_to_effect(target_effect, target_item.curse_factor)
	_copy_non_cash_cow_effects(current_item, target_item, target_effect)
	_copy_effect_runtime_state(_effect, target_effect)

	RunData.remove_item(current_item, player_index)
	RunData.add_item(target_item, player_index)

	_effect = target_effect
	growth_percent = int(_effect.get("growth_percent"))
	heal_regen_ratio = float(_effect.get("heal_regen_ratio"))
	healing_range = float(_effect.get("healing_range"))
	_apply_effect_textures(_effect)
	_apply_effect_stats(true)
	_update_healing_range()
	_sync_tracking()
	emit_signal("health_updated", self, current_stats.health, max_stats.health)


func _transform_into_cow_head(dropped_materials: int) -> void:
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var current_item := _get_owned_cash_cow_item()
	if current_item == null:
		return

	var cow_head_template = ItemService.get_item_from_id(Keys.generate_hash(COW_HEAD_ITEM_ID))
	if cow_head_template == null:
		return

	var cow_head = cow_head_template.duplicate(true) as ItemData
	if cow_head == null:
		return
	if "materials_dropped" in cow_head:
		cow_head.materials_dropped = dropped_materials
	cow_head.is_cursed = false
	cow_head.curse_factor = 0.0

	RunData.remove_item(current_item, player_index)
	RunData.add_item(cow_head, player_index)


func _get_owned_cash_cow_item() -> ItemData:
	var fallback = null
	for item in RunData.get_player_items_ref(player_index):
		if not (item is ItemData) or not _is_cash_cow_variant(item):
			continue
		if fallback == null:
			fallback = item
		if _effect != null and item.effects.has(_effect):
			return item
	return fallback


func _is_cash_cow_variant(item: ItemData) -> bool:
	return item != null and CASH_COW_VARIANT_ITEM_IDS.has(item.my_id)


func _get_cash_cow_effect(item: ItemData):
	if item == null:
		return null

	for effect in item.effects:
		if effect != null and effect.get_id() == "cash_cow":
			return effect
	return null


func _copy_effect_runtime_state(source_effect, target_effect) -> void:
	target_effect.is_cursed = bool(source_effect.get("is_cursed"))
	target_effect.held_materials = int(source_effect.get("held_materials"))
	target_effect.total_collected = int(source_effect.get("total_collected"))
	target_effect.variant_index = int(target_effect.get("variant_index"))


func _copy_non_cash_cow_effects(source_item: ItemData, target_item: ItemData, target_effect) -> void:
	var target_effects := [target_effect]
	for source_effect in source_item.effects:
		if source_effect == null or source_effect == _effect:
			continue
		if source_effect.get_id() == "cash_cow":
			continue

		var copied_effect = source_effect.duplicate(true)
		if copied_effect != null and copied_effect.has_method("_generate_hashes"):
			copied_effect._generate_hashes()
		target_effects.push_back(copied_effect)

	target_item.effects = target_effects


func _apply_curse_to_effect(effect, curse_factor: float) -> void:
	var curse_modifier = max(0.0, curse_factor)
	effect.growth_percent = int(ceil(int(effect.get("growth_percent")) * (1.0 + curse_modifier * 0.5)))
	effect.health_boost = float(effect.get("health_boost")) * (1.0 + curse_modifier * 0.25)


func _apply_effect_stats(preserve_health: bool) -> void:
	if _effect == null:
		return

	growth_percent = int(_effect.get("growth_percent"))
	heal_regen_ratio = float(_effect.get("heal_regen_ratio"))
	healing_range = float(_effect.get("healing_range"))
	held_materials = int(_effect.get("held_materials"))

	var previous_max_health := max(1, max_stats.health)
	var previous_health := max(1, current_stats.health)
	var effect_max_health := int(ceil(float(_effect.get("max_health")) * float(_effect.get("health_boost"))))
	max_stats.health = max(1, effect_max_health)
	if preserve_health:
		var gained_max_health := max(0, max_stats.health - previous_max_health)
		current_stats.health = int(min(max_stats.health, previous_health + gained_max_health))
	else:
		current_stats.health = max_stats.health


func _apply_effect_textures(effect) -> void:
	_shadow_texture = _get_effect_texture(effect, "shadow_texture", CASH_COW_DEFAULT_SHADOW)
	_body_texture = _get_effect_texture(effect, "body_texture", CASH_COW_DEFAULT_BODY)
	_head_texture_0 = _get_effect_texture(effect, "head_texture_0", CASH_COW_DEFAULT_HEAD_0)
	_head_texture_1 = _get_effect_texture(effect, "head_texture_1", CASH_COW_DEFAULT_HEAD_1)
	_apply_cash_cow_textures()


func _get_effect_texture(effect, property_name: String, default_texture: Texture) -> Texture:
	if effect == null:
		return default_texture

	var texture = effect.get(property_name)
	if texture is Texture:
		return texture
	return default_texture


func _apply_cash_cow_textures() -> void:
	var shadow = get_node_or_null("Animation/Viewport/offset/sp_shadow") as Sprite
	if shadow != null:
		shadow.texture = _shadow_texture

	var body = get_node_or_null("Animation/Viewport/offset/sp_body") as Sprite
	if body != null:
		body.texture = _body_texture

	_replace_head_animation_textures()
	_set_cash_cow_head_texture(_head_texture_1)


func _remove_from_map() -> void:
	_release_attracted_gold()
	if _target_behavior != null and _target_behavior.has_method("_disconnect_current_target"):
		_target_behavior._disconnect_current_target()
	if _entity_spawner_ref != null:
		_entity_spawner_ref.pets.erase(self)
		_entity_spawner_ref.targetable_pets.erase(self)

	hide()
	queue_free()


func _release_attracted_gold() -> void:
	var main = get_tree().current_scene
	if main == null or not ("_active_golds" in main):
		return

	for gold in main._active_golds:
		if gold != null and is_instance_valid(gold) and gold.attracted_by == self:
			gold.attracted_by = null


func _disable_item_areas() -> void:
	var item_attract_area = get_node_or_null("ItemAttractArea") as Area2D
	if item_attract_area != null:
		item_attract_area.set_deferred("monitoring", false)

	var item_pick_up_area = get_node_or_null("ItemPickUpArea") as Area2D
	if item_pick_up_area != null:
		item_pick_up_area.set_deferred("monitoring", false)


func _reset_pet_ready_signal_connections() -> void:
	var main = get_tree().current_scene
	if main == null:
		return

	if "_pause_menu" in main and main._pause_menu != null:
		var menu_options = main._pause_menu._menu_options
		if menu_options != null:
			if menu_options.is_connected("pet_highlighting_changed", self, "update_highlight"):
				menu_options.disconnect("pet_highlighting_changed", self, "update_highlight")
			if menu_options.is_connected("pet_transparency_changed", self, "_update_transparency"):
				menu_options.disconnect("pet_transparency_changed", self, "_update_transparency")

	if main.is_connected("end_of_the_wave", self, "end_of_wave_callback"):
		main.disconnect("end_of_the_wave", self, "end_of_wave_callback")


func _replace_head_animation_textures() -> void:
	_localize_head_animations()

	for animation_name in _animation_player.get_animation_list():
		var animation = _animation_player.get_animation(animation_name)
		if animation == null:
			continue

		for track_index in range(animation.get_track_count()):
			if str(animation.track_get_path(track_index)) != HEAD_TEXTURE_TRACK:
				continue

			for key_index in range(animation.track_get_key_count(track_index)):
				var texture = animation.track_get_key_value(track_index, key_index)
				animation.track_set_key_value(track_index, key_index, _get_cash_cow_head_texture(texture))


func _localize_head_animations() -> void:
	if _head_animations_localized:
		return

	var animation_names = _animation_player.get_animation_list()
	var animation_next := {}
	var blend_times := []

	for from_animation in animation_names:
		animation_next[from_animation] = _animation_player.animation_get_next(from_animation)
		for to_animation in animation_names:
			var blend_time = _animation_player.get_blend_time(from_animation, to_animation)
			if blend_time > 0.0:
				blend_times.push_back([from_animation, to_animation, blend_time])

	for animation_name in animation_names:
		var animation = _animation_player.get_animation(animation_name)
		if animation == null:
			continue

		_animation_player.remove_animation(animation_name)
		_animation_player.add_animation(animation_name, animation.duplicate(true))

	for animation_name in animation_next:
		var next_animation = animation_next[animation_name]
		if next_animation != "":
			_animation_player.animation_set_next(animation_name, next_animation)

	for blend_time_data in blend_times:
		_animation_player.set_blend_time(blend_time_data[0], blend_time_data[1], blend_time_data[2])

	_head_animations_localized = true


func _get_cash_cow_head_texture(texture) -> Texture:
	if texture is Texture and texture.resource_path.find("head_0") != -1:
		return _head_texture_0
	return _head_texture_1


func _set_cash_cow_head_texture(texture: Texture) -> void:
	var head = get_node_or_null("Animation/Viewport/offset/sp_body/sp_head") as Sprite
	if head != null:
		head.texture = texture


func _process_healing(delta: float) -> void:
	var healing_player = _get_healing_player()
	_set_healing_movement_locked(healing_player != null)

	if healing_player == null or current_stats.health >= max_stats.health:
		_healing_timer.stop()
		return

	var heal_value = _get_player_health_regen_value(healing_player)
	var heal_interval = _get_player_health_regen_interval(healing_player)
	if heal_value <= 0 or heal_interval <= 0.0:
		_healing_timer.stop()
		return

	_healing_timer.wait_time = heal_interval
	if _healing_timer.is_stopped():
		_healing_timer.start()

	var loop_count = _healing_timer.try_loop(delta)
	if loop_count > 0:
		var _healed = _heal_cash_cow(heal_value * loop_count)


func _get_healing_player() -> Player:
	for player in _healing_players:
		if is_instance_valid(player):
			return player
	return null


func _get_player_health_regen_interval(player: Player) -> float:
	if heal_regen_ratio <= 0.0 or RunData.get_player_effect_bool(Keys.no_heal_hash, player.player_index):
		return -1.0

	if RunData.get_player_effect(Keys.torture_hash, player.player_index) > 0:
		return 1.0 / heal_regen_ratio

	var stat_hp_regeneration = Utils.get_stat(Keys.stat_hp_regeneration_hash, player.player_index)
	if stat_hp_regeneration <= 0:
		return -1.0

	return RunData.get_hp_regeneration_timer(int(stat_hp_regeneration)) / heal_regen_ratio


func _get_player_health_regen_value(player: Player) -> int:
	if RunData.get_player_effect_bool(Keys.no_heal_hash, player.player_index):
		return 0

	var torture_effect = RunData.get_player_effect(Keys.torture_hash, player.player_index)
	if torture_effect > 0:
		return int(torture_effect)

	var hp_regen_val = 1
	var bonus_hp_regen_effects = RunData.get_player_effect(Keys.hp_regen_bonus_hash, player.player_index)
	if bonus_hp_regen_effects.size() > 0:
		var multiplier = 0
		for effect in bonus_hp_regen_effects:
			if player.current_stats.health < player.max_stats.health * (effect[1] / 100.0):
				multiplier += effect[0]
		hp_regen_val = int(hp_regen_val * (1.0 + multiplier))

	return int(max(0, hp_regen_val))


func _heal_cash_cow(value: int) -> int:
	var actual_value := int(min(value, max_stats.health - current_stats.health))
	if actual_value <= 0:
		return 0

	current_stats.health += actual_value
	emit_signal("health_updated", self, current_stats.health, max_stats.health)
	return actual_value


func _set_healing_movement_locked(value: bool) -> void:
	if _healing_movement_locked == value:
		return

	_healing_movement_locked = value
	if value:
		_can_move_before_healing = _can_move
		_mode_before_healing = mode
		_can_move = false
		mode = RigidBody2D.MODE_STATIC
	else:
		_can_move = _can_move_before_healing
		mode = _mode_before_healing
		if _can_move and not dead and not _end_of_wave:
			_animation_player.play("move")


func _update_healing_range() -> void:
	var healing_shape = get_node_or_null("HealingTriggeringZone/CollisionShape2D") as CollisionShape2D
	if healing_shape == null or not healing_shape.shape is CircleShape2D:
		return

	var circle_shape = healing_shape.shape as CircleShape2D
	circle_shape.radius = healing_range


func _on_HealingTriggeringZone_body_entered(body) -> void:
	if not body is Player:
		return

	var player = body as Player
	if player.player_index != player_index or _healing_players.has(player):
		return

	_healing_players.push_back(player)


func _on_HealingTriggeringZone_body_exited(body) -> void:
	if not body is Player:
		return

	_healing_players.erase(body)


func _can_pet() -> void:
	if dead:
		return
	if _check_can_be_pet():
		yield(get_tree().create_timer(0.1), "timeout")
		_animation_player.play("pet")
		SoundManager.play(sound_pet, 1, 0)
		yield(get_tree().create_timer(1.45), "timeout")
		_animation_player.play("move")
	else:
		yield(get_tree().create_timer(0.1), "timeout")
		_animation_player.play("move")
