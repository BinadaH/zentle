class_name ShapeBounds

var points = []
const handle_r = 15
const handle_size_squared = handle_r * handle_r
var origin = Vector2()

var objs = []

func set_objs(obj_array):
	objs = obj_array
	
func _init(rect : Rect2):
	create_rect(rect.position, rect.end)


func add_point(point : Vector2):
	points.append(point)
	
func create_rect(p1 : Vector2, p2 : Vector2):
	points.clear()
	add_point(p1)
	add_point(p1 + Vector2(p2.x - p1.x, 0))
	add_point(p2)
	add_point(p1 + Vector2(0, p2.y - p1.y))
	
	origin = p1

var curr_handle = 0
var handle_selected = false
func calc_handle(mouse_pos : Vector2):
	for p in range(points.size()):
		if (points[p] - mouse_pos).length_squared() < handle_size_squared:
			curr_handle = p
			handle_selected = true
			origin = points[(p + 2) % 4]
			return points[p]
	return null


func is_cursor_inside(mouse_pos : Vector2):
	return get_rect().grow(10).has_point(mouse_pos)

func get_handle() -> Vector2:
	return points[curr_handle]

func draw(canvas : Node2D):
	var col = EditorColors.ui_palette[EditorColors.UI.PRIMARY_HOVER]
	var r = get_rect().grow(4)
	canvas.draw_rect(r, col, false, 5)
	canvas.draw_rect(r, EditorColors.ui_palette[EditorColors.UI.PRIMARY_TRANSPARENT], true)
	
	for o in objs:
		var obj_r = EditorFuncs.get_object_rect(o)
		canvas.draw_rect(obj_r, col, false, 3)
	
	for p in range(points.size()):
		var grab_col =  EditorColors.ui_palette[EditorColors.UI.PRIMARY_PRESSED] if (handle_selected && p == curr_handle) else col
		canvas.draw_circle(points[p], handle_r, grab_col)
	

func scale(rel : Vector2, proportional : bool):
	if !handle_selected: return
	
	var handle_pos = get_handle()
	var diff = handle_pos - origin
	
	var new_pos = diff + rel
	if diff.dot(new_pos) <= 0:
		new_pos = handle_pos.normalized() * 0.01
	
	var k
	if proportional:
		k = new_pos.length() / diff.length()
	else:
		var target = new_pos
		var kx = target.x / diff.x if abs(diff.x) > 0.0001 else 1
		var ky = target.y / diff.y if abs(diff.y) > 0.0001 else 1
		k = Vector2(kx, ky)
		
	var old_points = points.duplicate()
	var offset = origin - (k * origin)
	for i in range(points.size()):
		points[i] = k * points[i] + offset
	
	if get_rect().get_area() < 20:
		points = old_points
	else:
		last_scale_factor *= k
		if EditorOptions.options[EditorOptions.OPTIONS.REALTIME_MOVE_SCALE]:
			EditorFuncs.canvas_manager.rescale_objs(objs, k, origin)
			
var last_scale_factor = 1
var last_move_factor = Vector2.ZERO
func end_move_scale():
	var do_func = func(move_val, scale, origin): 
		EditorFuncs.canvas_manager.move_objs(objs.duplicate(), move_val)
		EditorFuncs.canvas_manager.rescale_objs(objs.duplicate(), scale, origin)
		for i in range(points.size()):
			points[i] += move_val
			points[i] = scale * (points[i] - origin) + origin
		EditorData.draw_ui.queue_redraw()
	
	var inv_last_scale_factor = Vector2.ONE / last_scale_factor
	EditorHistory.create_action("move_scale", do_func.bind(last_move_factor, last_scale_factor, origin), do_func.bind(-last_move_factor, inv_last_scale_factor, origin), false)
	
	
	if !EditorOptions.options[EditorOptions.OPTIONS.REALTIME_MOVE_SCALE]:
		do_func.call(last_move_factor, last_scale_factor, origin)
	
	for obj in objs:
		EditorFuncs.canvas_manager.set_spatial_grid_pos(obj)
		if obj && obj.is_in_group("text"):
			if !(is_equal_approx(obj.scale.x, 1.0) && is_equal_approx(obj.scale.y, 1.0)):
				obj.curr_font_size *= obj.scale.x
				obj.scale = Vector2.ONE
				obj.render(obj.text)
		
		var o_rect = EditorFuncs.get_object_rect(obj)
		if obj == objs[0]:
			create_rect(o_rect.position, o_rect.end)
		else:
			merge(o_rect)
			
	EditorData.draw_ui.queue_redraw()
	last_scale_factor = 1
	last_move_factor = Vector2.ZERO
	
	
func move(rel : Vector2):
	last_move_factor += rel
	for i in points.size():
		points[i] += rel
	
	if EditorOptions.options[EditorOptions.OPTIONS.REALTIME_MOVE_SCALE]:
		EditorFuncs.canvas_manager.move_objs(objs, rel)

func get_rect() -> Rect2:
	return Rect2(points[0], points[2] - points[0])

func merge(b : Rect2):
	var r = get_rect().merge(b)
	points[0] = r.position
	points[1] = Vector2(r.end.x, r.position.y)
	points[2] = r.end
	points[3] = Vector2(r.position.x, r.end.y)
	
