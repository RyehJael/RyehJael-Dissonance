class_name CashCowTargetBehavior
extends TargetBehavior

signal target_found()
signal target_player()

var _main: Main = null


func init(parent: Node) -> Node:
	.init(parent)

	if _main == null:
		_main = parent._entity_spawner_ref._main
		var _error = _main.connect("gold_spawned", self, "on_gold_spawned")

	return self


func update_target() -> void:
	_disconnect_current_target()
	_parent.current_target = null

	var min_dist_squared := Utils.LARGE_NUMBER
	for gold in _main._active_golds:
		if gold.already_picked_up:
			continue
		if gold.attracted_by != null and gold.attracted_by != _parent:
			continue

		var dist_squared = global_position.distance_squared_to(gold.global_position)
		if dist_squared < min_dist_squared:
			min_dist_squared = dist_squared
			_parent.current_target = gold

	if _parent.current_target != null:
		var _error = _parent.current_target.connect("picked_up", self, "on_gold_picked_up")
		emit_signal("target_found", self)
	else:
		_parent.current_target = self


func on_gold_picked_up(gold: Node, _player_index: int) -> void:
	if gold != null and gold.is_connected("picked_up", self, "on_gold_picked_up"):
		gold.disconnect("picked_up", self, "on_gold_picked_up")
	_parent.current_target = null


func on_gold_spawned() -> void:
	_disconnect_current_target()
	_parent.current_target = null


func _disconnect_current_target() -> void:
	if _parent.current_target is Gold and _parent.current_target.is_connected("picked_up", self, "on_gold_picked_up"):
		_parent.current_target.disconnect("picked_up", self, "on_gold_picked_up")
