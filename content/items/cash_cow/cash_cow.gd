class_name CashCow
extends Pet

const CASH_COW_PICKUP_PLAYER_INDEX := -7777
const INVULNERABLE_COOLDOWN := 0.6

export(AudioStream) var sound_dying
export(AudioStream) var sound_rising
export(AudioStream) var sound_pet

var growth_percent := 15
var held_materials := 0
var _effect = null
var _invulnerable_cooldown := 0.0

onready var life_bar = $"%LifeBar" as UIProgressBar


func _ready() -> void:
	._ready()
	_animation_player.play("move")
	var _error_hp_lifebar = connect("health_updated", self, "on_health_updated")


func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_effect = effect
	growth_percent = int(effect.get("growth_percent"))
	held_materials = int(effect.get("held_materials"))
	max_stats.health = int(ceil(max_stats.health * float(effect.get("health_boost"))))
	current_stats.health = max_stats.health
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


func _on_HealingTriggeringZone_body_entered(_body) -> void:
	pass


func _on_HealingTriggeringZone_body_exited(_body) -> void:
	pass


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
