extends Control

var has_new_point = false
var new_point: Vector2
var new_radius: float
var last_point: Vector2
var last_radius: float
var first_point = true

func _ready():
	clear_viewport(false)

func _draw():
	if !has_new_point: return
	
	# We interpolate between the last point and the new point
	# to draw a smooth line made of circles
	var dist = (last_point - new_point).length()
	var step_dist = max(1.0, new_radius * 0.35)
	if dist > step_dist:
		var steps = int(dist / step_dist)
		for i in range(1, steps + 1):
			var p = float(i) / steps
			var curr_pos = lerp(last_point, new_point, p)
			var curr_r = lerp(last_radius, new_radius, p)
			draw_circle(curr_pos, curr_r, EditorData.current_color, true, -1, true)
	else:
		draw_circle(new_point, new_radius, EditorData.current_color)
		
	has_new_point = false
	last_point = new_point
	last_radius = new_radius

## This function clears the draw_line viewport
func clear_viewport(animate = true):
	has_new_point = false
	first_point = true
	queue_redraw()
	if animate:
		var t = create_tween()
		t.tween_property(get_parent().get_parent(), "modulate", Color.TRANSPARENT, 0.1)
		t.tween_callback(reset)
	else:
		reset()
		
func reset():
	get_parent().render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	get_parent().get_parent().modulate.a = 1

## This function queues a new point to be drawn
func draw_new_point(point, radius):
	has_new_point = true
	var half_view_size = get_rect().size / 2
	var transformed_position = (point - EditorData.camera.position) * EditorData.camera.zoom.x + half_view_size - get_parent().get_parent().get_global_rect().position / 2
	new_point = transformed_position
	new_radius = radius * EditorData.camera.zoom.x
	
	if first_point:
		last_point = new_point
		last_radius = new_radius
		first_point = false
		
	queue_redraw()
	
