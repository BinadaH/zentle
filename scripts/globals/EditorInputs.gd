extends Node


## This function receives every _unhandled_input that is not blocked by a UI element.  
func handle_input(event: InputEvent):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventKey:
		handle_key(event)

func handle_key(event: InputEventKey):
	if event.keycode == KEY_CTRL:
		EditorData.ctrl_pressed = event.pressed
	elif event.keycode == KEY_SHIFT:
		EditorData.shift_pressed = event.pressed
	elif event.keycode == KEY_DELETE:
		EditorTools.delete()
	elif event.keycode == KEY_ESCAPE:
		if EditorData.quick_tools_opened:
			EditorFuncs.close_quick_tools()
		elif EditorTools.is_current(EditorTools.TOOLS.SELECT):
			EditorFuncs.selection_manager.clear_selection_status()
			
	
	elif event.pressed && event.ctrl_pressed:
		if event.keycode == KEY_Y or (event.shift_pressed && event.keycode == KEY_Z):
			EditorHistory.redo()
			EditorFuncs.selection_manager.clear_selection_status()
		elif event.keycode == KEY_Z:
			EditorHistory.undo()
			EditorFuncs.selection_manager.clear_selection_status()
		elif event.keycode == KEY_C:
			EditorFuncs.handle_copy()
		elif event.keycode == KEY_V:
			EditorFuncs.handle_paste()
		elif event.keycode == KEY_S:
			EditorFuncs.handle_save()
		if event.keycode == KEY_T && event.shift_pressed:
			EditorFuncs.toggle_quick_tools()
	else:
		if EditorData.can_use_shortcuts && !EditorData.quick_tools_opened:
			if EditorTools.toggle_shortcuts.has(event.keycode):
				EditorTools.toggle_to(EditorTools.toggle_shortcuts[event.keycode], event.pressed)

# TODO refactoring
func handle_mouse_button(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		EditorData.mouse_down = event.pressed
		calc_mouse_position(event)
		if event.pressed:
			EditorFuncs.request_high_performance()
		else:
			EditorFuncs.release_high_performance()
		
		if event.pressed:
			if EditorTools.is_current(EditorTools.TOOLS.SELECT):
				# Exit from editing a [Text] object while using the Select Tool and clicking outside the CodeEdit
				EditorData.mouse_relative = Vector2(0, 0)
				var text_edit = get_viewport().gui_get_focus_owner()
				if text_edit && text_edit.is_in_group("text_edit") && !text_edit.get_rect().has_point(EditorFuncs.get_screen_to_world_pos(event.position)):
					text_edit.release_focus()
				
				# If a CodeEdit is not currently focused
				else:
					# Check for single click selection of an object
					EditorFuncs.selection_manager.single_click_selection()
					
					if event.double_click:
						# Edit a text object by double clicking while using the Select Tool
						var text_obj = EditorFuncs.selection_manager.get_first_selected_obj()
						if text_obj && text_obj.is_in_group("text"):
							text_obj.edit_text()
							EditorFuncs.selection_manager.clear_selection_status()
				
			
			elif EditorTools.is_current(EditorTools.TOOLS.TEXT):
				# Create Text
				if (!EditorFuncs.canvas_manager.edit_text_under_mouse()):
						
					var curr_focus = EditorData.get_viewport().gui_get_focus_owner()
					if (curr_focus && !curr_focus.get_parent().is_in_group("text")) || !curr_focus:
						var new_t_s = load("res://scenes/text.tscn")
						var new_t = new_t_s.instantiate()
						new_t.position = EditorData.world_pos
						new_t.position.y -= EditorData.current_text_size / 2
						new_t.curr_font_size = EditorData.current_text_size
						new_t.curr_color = EditorData.current_color
						new_t.modulate = new_t.curr_color
						
						EditorHistory.create_action("create_text", EditorFuncs.canvas_manager.add_to_canvas.bind(new_t), EditorFuncs.canvas_manager.remove_from_canvas.bind(new_t), true, new_t)
						new_t.edit_text()
						
			elif EditorTools.is_current(EditorTools.TOOLS.ERASER):
				EditorFuncs.canvas_manager.update_eraser()
			elif EditorTools.is_current(EditorTools.TOOLS.EXPORT_REGION):
				EditorFuncs.export_manager.handle_mouse_down()
			elif EditorTools.is_current(EditorTools.TOOLS.PEN):
				EditorFuncs.line_manager.handle_mouse_button()
				
		
		# BUTTON LEFT UP
		else:
			match EditorTools.current_tool:
				EditorTools.TOOLS.SELECT:
					EditorFuncs.selection_manager.update_selection()
				EditorTools.TOOLS.EXPORT_REGION:
					EditorFuncs.export_manager.handle_mouse_up()
				EditorTools.TOOLS.PEN:
					EditorFuncs.line_manager.handle_mouse_button()
					

	elif event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
		match EditorTools.current_tool:
			EditorTools.TOOLS.SELECT:
				EditorFuncs.selection_manager.clear_selection_status()
	
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		EditorData.middle_down = event.pressed
		if event.pressed:
			EditorFuncs.request_high_performance()
		else:
			EditorFuncs.release_high_performance()
			
	if event.button_index == MOUSE_BUTTON_MIDDLE || event.button_index == MOUSE_BUTTON_LEFT:
		var focused = get_viewport().gui_get_focus_owner()
		if focused && !focused.is_in_group("text_edit"):
			focused.release_focus()

func handle_mouse_motion(event: InputEventMouseMotion):
	calc_mouse_position(event)
	EditorData.pressure = max(event.pressure, 0.3)

	match EditorTools.current_tool:
		EditorTools.TOOLS.PEN:
			EditorFuncs.line_manager.handle_mouse_motion()
		EditorTools.TOOLS.SELECT:
			EditorFuncs.selection_manager.snap_enabled = event.ctrl_pressed
			EditorFuncs.selection_manager.update_selection()
		EditorTools.TOOLS.ERASER:
			EditorFuncs.canvas_manager.update_eraser()
		EditorTools.TOOLS.EXPORT_REGION:
			EditorFuncs.export_manager.handle_mouse_movement()
			
func calc_mouse_position(event: InputEvent):
	# Workaround: event.relative occasionally returns fixed Vector2.ZERO, calculating
	# manually from position
	EditorData.mouse_relative = event.position - EditorData.screen_pos
	
	EditorData.screen_pos = event.position 
	var new_world_pos = EditorFuncs.get_screen_to_world_pos(event.position)
	
	EditorData.snapped_world_relative = EditorFuncs.get_grid_pos(new_world_pos, 0.5) - EditorFuncs.get_grid_pos(EditorData.world_pos, 0.5)
	
	EditorData.world_pos = new_world_pos
