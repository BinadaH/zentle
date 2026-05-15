class_name SelectionManger


var snap_enabled = false

var selection_rect
var selection_made : ShapeBounds
var selection_moving = false

func update_selection():
	if !selection_made:
		if EditorData.mouse_down:
			if !selection_rect:
				selection_rect = Rect2(EditorData.world_pos, Vector2.ZERO)
			else:
				var start_pos = selection_rect.position
				selection_rect = Rect2(start_pos, EditorData.world_pos - start_pos)
				EditorData.draw_ui.queue_redraw()
		else:
			if selection_rect and selection_rect.size.length() > 5:
				_perform_area_selection()
			selection_rect = null
			EditorData.draw_ui.queue_redraw()
			
	else:
		_handle_existing_selection()
	

func _perform_area_selection():
	var found_objs = []
	var combined_rect : Rect2
	var area: Rect2 = selection_rect.abs()

	for child in EditorFuncs.canvas_manager.get_children():
		var to_add = false
		var obj_rect = Rect2()
		
		if child is Line2D:
			to_add = EditorFuncs.canvas_manager.is_rect_over_line2d(child, area)
			if to_add:
				obj_rect = EditorFuncs.get_object_rect(child)
		else:
			obj_rect = EditorFuncs.get_object_rect(child)
			to_add = area.encloses(obj_rect) if EditorData.ctrl_pressed else area.intersects(obj_rect)
		
		if to_add:
			found_objs.append(child)
			combined_rect = combined_rect.merge(obj_rect) if found_objs.size() > 1 else obj_rect
			
	if found_objs.size() > 0:
		selection_made = ShapeBounds.new(combined_rect)
		selection_made.set_objs(found_objs)



var drag_start_mouse_pos : Vector2 = Vector2.ZERO
var drag_start_obj_pos : Vector2 = Vector2.ZERO
func _handle_existing_selection():
	if EditorData.mouse_down:
		if !selection_moving and !selection_made.handle_selected:
			if selection_made.calc_handle(EditorData.world_pos):
				pass
			elif selection_made.is_cursor_inside(EditorData.world_pos):
				selection_moving = true
				drag_start_mouse_pos = EditorData.world_pos
				drag_start_obj_pos = selection_made.points[0]
			else:
				clear_selection_status()
				return

		#Scale
		if selection_made.handle_selected:
			var rel
			if snap_enabled:
				var target_pos = EditorFuncs.get_grid_pos(EditorData.world_pos)
				rel = target_pos - selection_made.points[selection_made.curr_handle]
			else: 
				rel = EditorData.mouse_relative / EditorData.camera.zoom.x 
			
			selection_made.scale(rel, Input.is_key_pressed(KEY_SHIFT))
			EditorData.draw_ui.queue_redraw()
		
		#Move
		elif selection_moving:
			var total_mouse_delta = EditorData.world_pos - drag_start_mouse_pos
			
			var desired_pos = drag_start_obj_pos + total_mouse_delta
			
			if snap_enabled:
				var snapped_pos = EditorFuncs.get_grid_pos(desired_pos)
				
				var current_obj_pos = selection_made.points[0]
				var snap_rel = snapped_pos - current_obj_pos
				
				if snap_rel != Vector2.ZERO:
					selection_made.move(snap_rel)
					EditorData.draw_ui.queue_redraw()
			else:
				selection_made.move(EditorData.mouse_relative / EditorData.camera.zoom.x)
				EditorData.draw_ui.queue_redraw()
	else:
		if selection_moving || selection_made.handle_selected:
			selection_made.end_move_scale()
			selection_moving = false
			selection_made.handle_selected = false
			EditorData.draw_ui.queue_redraw()

func single_click_selection():
	if selection_made:
		if selection_made.calc_handle(EditorData.world_pos):
			return
		if !selection_made.is_cursor_inside(EditorData.world_pos) && !EditorData.ctrl_pressed:
			clear_selection_status()
		else:
			return
	
	var objs = EditorFuncs.canvas_manager.get_children()
	for objs_i in range(objs.size() - 1, -1, -1):
		var child = objs[objs_i]
		var is_selected = false
		var new_rect
		
		if child is Line2D:
			var area = Rect2(EditorData.world_pos, Vector2.ZERO)
			is_selected = EditorFuncs.canvas_manager.is_rect_over_line2d(child, area)
			if is_selected:
				new_rect = EditorFuncs.get_object_rect(child)
		else:
			new_rect = EditorFuncs.get_object_rect(child)
			is_selected = new_rect.has_point(EditorData.world_pos)
			
		if is_selected:
			if selection_made && selection_made.objs.has(child):
				continue
			if selection_made && EditorData.ctrl_pressed:
				selection_made.merge(new_rect)
				selection_made.objs.append(child)
			else:
				selection_made = ShapeBounds.new(new_rect)
				selection_made.set_objs([child])
				
			update_selection()
			break
			


func perform_objs_selection(objs, rect):
	clear_selection_status()
	selection_made = ShapeBounds.new(rect)
	selection_made.set_objs(objs)
	EditorData.draw_ui.queue_redraw()

func change_color(old: Color, new: Color):
	if !selection_made: return
	var do = func(to, objs): 
		for obj in objs:
			if !is_instance_valid(obj): continue
			if obj is Line2D:
				obj.default_color = to
			elif obj.is_in_group("text"):
				obj.modulate = to
				obj.curr_color = to
					
	EditorHistory.create_action("change_color", do.bind(new, selection_made.objs.duplicate()), do.bind(old, selection_made.objs.duplicate()))

func clear_selection_status():
	selection_made = null
	selection_rect = null
	EditorData.draw_ui.queue_redraw()
	
func get_first_selected_obj():
	if selection_made:
		return selection_made.objs[0]
	return null
