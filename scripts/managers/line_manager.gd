class_name LineManager

var current_line: Line2D = null
var dash_line: Line2D
var base_line: Line2D 

var curr_points = []
var curr_pressures = []
var curr_length = 0

const SIMPLIFY_LINE_FACTOR = 0.75

enum STROKE_TYPES {
	NORMAL,
	DASHED,
}

var shape_recognizer : ShapeRecognizer

func _init():
	dash_line = Line2D.new()
	base_line = Line2D.new()
	
	base_line.add_to_group("lines")
	dash_line.add_to_group("lines")
	
	base_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	base_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	base_line.joint_mode = Line2D.LINE_JOINT_ROUND
	
	shape_recognizer = ShapeRecognizer.new()

func handle_mouse_motion():
	if EditorData.mouse_down:
		if !current_line:
			#creating the line on mouse down
			create_line()
		else:
			#updating the line that was previously created
			update_line()
	else:
		#On mouse release, if line exists -> reset the state
		done()

func create_line():
	if EditorData.shift_pressed && !EditorData.ctrl_pressed:
		current_line = dash_line.duplicate()
		current_line.set_meta("stroke", STROKE_TYPES.DASHED)
	else:
		current_line = base_line.duplicate()
		current_line.set_meta("stroke", STROKE_TYPES.NORMAL)
		
	current_line.default_color = EditorData.current_color
	current_line.width = EditorData.current_size
	current_line.width_curve = Curve.new()
	
	curr_points.append(EditorData.world_pos)
	curr_pressures.append(EditorData.pressure)
	
	check_shape_timer = EditorData.get_tree().create_timer(EditorOptions.options[EditorOptions.OPTIONS.SHAPE_RECOGNIZER_DELAY])
	check_shape_timer.connect("timeout", check_shape)
	
	current_line.visible = false
	curr_length = 0


var last_smooth_point = null
var last_smooth_pressure = null
var smoothed_pressures = PackedFloat32Array()
var smoothed_points = PackedVector2Array()

const MIN_DISTANCE = 1
var check_shape_timer : SceneTreeTimer = null

func update_line():
	if found_shape:
		update_shape()
	else:
		draw_line()
	
func update_shape():
	var world_snapped = EditorFuncs.snap_to_grid(EditorData.world_pos, EditorOptions.shape_snap_tolerance, EditorOptions.shape_snap_dist)
	match found_shape.shape:
		ShapeRecognizer.SHAPES.CIRCLE:
			var new_radius = (found_shape.center - world_snapped).length()
			current_line.points = shape_recognizer.get_ellipse_points(found_shape.center, new_radius, new_radius)
		ShapeRecognizer.SHAPES.ELLIPSE:
			var new_semi_ax = (found_shape.center - world_snapped)
			current_line.points = shape_recognizer.get_ellipse_points(found_shape.center, new_semi_ax.x, new_semi_ax.y)
		ShapeRecognizer.SHAPES.RECTANGLE:
			var half_size = abs(world_snapped - found_shape.center)
			var new_rect = Rect2(found_shape.center - half_size, half_size * 2)
			found_shape.bounding_box = new_rect
			current_line.points = shape_recognizer.get_rect_points(new_rect)
		ShapeRecognizer.SHAPES.SEGMENT:
			current_line.points = [found_shape.points[0], world_snapped]

func draw_line():
	var current_raw_pressure = EditorData.pressure
	if last_smooth_pressure == null:
		last_smooth_pressure = current_raw_pressure
	else:
		last_smooth_pressure = lerp(last_smooth_pressure, current_raw_pressure, 0.1)
	
	var target_point = EditorData.world_pos
	if last_smooth_point != null:
		target_point = lerp(last_smooth_point, target_point, 0.25)
	else:
		last_smooth_point = target_point
	
	if not smoothed_points.is_empty():
		if target_point.distance_to(smoothed_points[-1]) < MIN_DISTANCE:
			return
	
	curr_length += last_smooth_point.distance_to(target_point)
	last_smooth_point = target_point
	smoothed_pressures.append(last_smooth_pressure)
	smoothed_points.append(target_point)
	
	# Add new point to the draw_line viewport
	EditorData.draw_line.draw_new_point(target_point, last_smooth_pressure * EditorData.current_size * 0.5)
	
	check_shape_timer.time_left = 1

var found_shape : ShapeRecognizer.ShapeRecognizerResult = null
var shape_check_iter = 0
func check_shape():
	if !current_line: return
	shape_check_iter += 1
	var result = shape_recognizer.get_shape(smoothed_points, shape_check_iter)
	if result.recognized:
		found_shape = result
		current_line.points = result.points
		EditorFuncs.canvas_manager.add_to_canvas(current_line)
		current_line.visible = true
		EditorData.draw_line.clear_viewport()
		current_line.width_curve.clear_points()
		current_line.width_curve.add_point(Vector2(1.0, 1.0))
	else:
		check_shape_timer = EditorData.get_tree().create_timer(1)
		check_shape_timer.connect("timeout", check_shape)
		check_shape_timer.time_left = EditorOptions.options[EditorOptions.OPTIONS.SHAPE_RECOGNIZER_DELAY]


func _update_width_curve():
	if smoothed_pressures.size() == 0: return
	var steps = 100
	for i in range(0, steps, 1):
		var p = float(i) / steps
		var index = int(smoothed_pressures.size()* p)
		current_line.width_curve.add_point(Vector2(p, smoothed_pressures[index]))
	
func done():
	if !current_line: return
	current_line.visible = true
	
	var call_history_do_func = true
	if found_shape:
		found_shape = null
		call_history_do_func = false
	elif smoothed_points.size() == 1:
		var p = smoothed_points[0]
		smoothed_points.append(p + Vector2(0.1, 0.1)) 
		smoothed_pressures.append(smoothed_pressures[0])
		current_line.points = smoothed_points
	else:
		var is_scratch = shape_recognizer.is_scratch(smoothed_points, curr_length)
		if is_scratch.recognized:
			var rect = is_scratch.bounding_box
			var lines_to_erase = EditorFuncs.canvas_manager.get_lines_under_rect(rect)
			EditorHistory.create_action("erase", EditorFuncs.canvas_manager.remove_objs.bind(lines_to_erase), EditorFuncs.canvas_manager.add_objs.bind(lines_to_erase), true, null, lines_to_erase)
			reset_line()
			return
		else:
			smoothed_points = simplify_points(smoothed_points, SIMPLIFY_LINE_FACTOR)
		
		current_line.points = smoothed_points
	
	_update_width_curve()
	EditorHistory.create_action("Create Line", EditorFuncs.canvas_manager.add_to_canvas.bind(current_line), EditorFuncs.canvas_manager.remove_from_canvas.bind(current_line), call_history_do_func, current_line)
	EditorFuncs.canvas_manager.set_spatial_grid_pos(current_line)
	
	reset_line()
	
func reset_line():
	current_line = null
	last_smooth_point = null
	last_smooth_pressure = null
	smoothed_pressures.clear()
	smoothed_points.clear()
	curr_pressures.clear()
	curr_points.clear()
	if check_shape_timer:
		check_shape_timer.disconnect("timeout", check_shape)
	check_shape_timer = null
	shape_check_iter = 0
	
	EditorData.draw_line.clear_viewport()

func simplify_points(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() < 3:
		return points

	var dmax = 0.0
	var index = 0
	var end = points.size() - 1
	
	for i in range(1, end):
		var d = _get_distance_to_segment(points[i], points[0], points[end])
		if d > dmax:
			index = i
			dmax = d

	if dmax > epsilon:
		var left = simplify_points(points.slice(0, index + 1), epsilon)
		var right = simplify_points(points.slice(index, points.size()), epsilon)
		left.remove_at(left.size() - 1)
		left.append_array(right)
		return left
	else:
		return PackedVector2Array([points[0], points[end]])

func _get_distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	if a == b: return p.distance_to(a)
	var l2 = a.distance_squared_to(b)
	var t = max(0, min(1, (p - a).dot(b - a) / l2))
	var projection = a + t * (b - a)
	return p.distance_to(projection)
	
