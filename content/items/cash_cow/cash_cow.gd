class_name CashCow
extends Pet

const CASH_COW_PICKUP_PLAYER_INDEX := -7777
const INVULNERABLE_COOLDOWN := 0.6
const CASH_COW_HEAD_0 := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_head_0.png")
const CASH_COW_HEAD_1 := preload("res://mods-unpacked/RyehJael-Dissonance/content/items/cash_cow/cash_cow_head_1.png")
const HEAD_TEXTURE_TRACK := "Animation/Viewport/offset/sp_body/sp_head:texture"

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

onready var life_bar = $"%LifeBar" as UIProgressBar


func _ready() -> void:
	._ready()
	_replace_head_animation_textures()
	_set_cash_cow_head_texture(CASH_COW_HEAD_1)
	_animation_player.play("move")
	var _error_hp_lifebar = connect("health_updated", self, "on_health_updated")


func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_effect = effect
	growth_percent = int(effect.get("growth_percent"))
	heal_regen_ratio = float(effect.get("heal_regen_ratio"))
	healing_range = float(effect.get("healing_range"))
	held_materials = int(effect.get("held_materials"))
	max_stats.health = int(ceil(max_stats.health * float(effect.get("health_boost"))))
	current_stats.health = max_stats.health
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

	_set_held_materials(held_materials + gold.value)
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

	_drop_held_materials()
	SoundManager.play(sound_dying, 0, 0.1)
	dead = true
	_pending_die = true
	_hurtbox.disable()
	emit_signal("died", self, args)
	_animation_player.play("dead")


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
		RunData.set_tracked_value(player_index, Keys.generate_hash("item_cash_cow"), held_materials)


func _replace_head_animation_textures() -> void:
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


func _get_cash_cow_head_texture(texture) -> Texture:
	if texture is Texture and texture.resource_path.find("head_0") != -1:
		return CASH_COW_HEAD_0
	return CASH_COW_HEAD_1


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
		return torture_effect

	var hp_regen_val = 1
	var bonus_hp_regen_effects = RunData.get_player_effect(Keys.hp_regen_bonus_hash, player.player_index)
	if bonus_hp_regen_effects.size() > 0:
		var multiplier = 0
		for effect in bonus_hp_regen_effects:
			if player.current_stats.health < player.max_stats.health * (effect[1] / 100.0):
				multiplier += effect[0]
		hp_regen_val = int(hp_regen_val * (1.0 + multiplier))

	return max(0, hp_regen_val)


func _heal_cash_cow(value: int) -> int:
	var actual_value = min(value, max_stats.health - current_stats.health)
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
