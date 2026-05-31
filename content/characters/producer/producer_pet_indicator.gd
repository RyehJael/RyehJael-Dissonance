extends Node2D

const INDICATOR_COLOR := Color(0.25, 0.95, 1.0, 0.75)
const FILL_COLOR := Color(0.25, 0.95, 1.0, 0.04)
const FULL_CIRCLE := PI * 2.0

var radius := 50.0
var _pulse := 0.0


func _ready() -> void:
	set_as_toplevel(true)


func setup(p_radius: float) -> void:
	radius = p_radius
	update()


func _process(delta: float) -> void:
	var parent = get_parent()
	if parent != null and parent is Node2D:
		global_position = parent.global_position
	_pulse = fmod(_pulse + delta * 2.5, FULL_CIRCLE)
	update()


func _draw() -> void:
	var pulse_alpha = 0.08 * sin(_pulse)
	var ring_color = Color(INDICATOR_COLOR.r, INDICATOR_COLOR.g, INDICATOR_COLOR.b, INDICATOR_COLOR.a + pulse_alpha)
	draw_circle(Vector2.ZERO, radius, FILL_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, FULL_CIRCLE, 64, ring_color, 4.0, true)
