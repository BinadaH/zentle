class_name CanvasManager

var copy_buffer = []

## Save the passed objs inside [member CanvasManager.copy_buffer]
func make_copy(objs: Array):
	copy_buffer.clear()
	if objs.size() > 0:
		copy_buffer = objs
	DisplayServer.clipboard_set("")

## If the user has an image in the clipboard, the function adds a [TextureRect] with the corresponding image.
## Otherwise it duplicates [member copy_buffer] into the canvas
func paste_copy():
	var has_img = DisplayServer.clipboard_has_image()
	if !has_img && copy_buffer.size() <= 0: return
	var new_objs = []
	var rect = Rect2()
	if has_img:
		var img = DisplayServer.clipboard_get_image()
		var tex = ImageTexture.create_from_image(img)
		var tex_rect = TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		# Scale the size to compensate for camera zoom
		tex_rect.size = tex.get_size() / EditorData.camera.zoom.x
		# All imgs are behind lines
		tex_rect.z_index = -1
		
		tex_rect.texture = tex
		
		# When pasted, the img is centered around the mouse pos
		tex_rect.position = EditorData.world_pos - tex_rect.size / 2
		
		new_objs.append(tex_rect)
		
		rect = tex_rect.get_rect()
		copy_buffer.clear()
	else:
		for obj in copy_buffer:
			var new_obj = obj.duplicate()
			
			# Add an offset to the copied item
			move_obj(new_obj, Vector2.ONE * EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE])
			
			new_objs.append(new_obj)
			var new_rect = EditorFuncs.get_object_rect(new_obj)
			
			# Copy text if the the item is a text object 
			if obj.is_in_group("text"):
				new_obj.text = obj.text
			
			if obj == copy_buffer[0]:
				rect = new_rect
			else:
				rect = rect.merge(new_rect)

	EditorHistory.create_action("paste", add_objs.bind(new_objs), remove_objs.bind(new_objs), true)
	
	# Select the new items after they are pasted
	EditorFuncs.selection_manager.perform_objs_selection(new_objs, rect)

func add_to_canvas(node):
	if is_instance_valid(node):
		EditorData.main.canvas.add_child(node)
		set_spatial_grid_pos(node)

func remove_from_canvas(node):
	if is_instance_valid(node):
		clear_spatial_grid_pos(node)
		EditorData.main.canvas.remove_child(node)

func get_canvas():
	return EditorData.main.canvas

func remove_objs(objs):
	for obj in objs:
		remove_from_canvas(obj)
	
func add_objs(objs):
	for obj in objs:
		add_to_canvas(obj)

func rescale_obj(obj, k, origin):
	if !is_instance_valid(obj): return
	if obj is Line2D:
		obj.position = k * (obj.position - origin) + origin
		
		var avg_scale = ((abs(k.x) + abs(k.y)) / 2.0) if k is Vector2 else k
		
		for i in range(obj.points.size()):
			obj.points[i] *= k
	elif obj && obj.is_in_group("text"):
		obj.scale *= k
		obj.position = k * (obj.position - origin) + origin
	elif obj is Control:
		obj.size *= k
		obj.position = k * (obj.position - origin) + origin
	elif obj.is_in_group("template"):
		obj.update_scale(k.x, origin)
	elif obj.is_in_group("pdf"):
		obj.update_scale(k.x, origin)
	
func rescale_objs(objs, k, origin):
	for obj in objs:
		rescale_obj(obj, k, origin)
		
func move_obj(obj, rel):
	if !is_instance_valid(obj): return
	if obj is Line2D:
		for i in range(obj.points.size()):
			obj.points[i] += rel
	elif obj is Control:
		obj.position += rel
	elif obj.is_in_group("template"):
		obj.position += rel
	elif obj.is_in_group("pdf"):
		obj.position += rel
		
func move_objs(objs, rel):
	for obj in objs:
		move_obj(obj, rel)
		
func edit_text_under_mouse():
	for child in EditorData.get_tree().get_nodes_in_group("text"):
		if child.is_visible_in_tree() && child.get_global_rect().has_point(EditorData.world_pos):
			child.edit_text()
			child.move_caret_to_mouse()
			return true
	return false


# TODO refactoring
var erasing = false
var curr_erased_lines = []
func update_eraser():
	if EditorData.mouse_down:
		erasing = true
		var rect_size = EditorData.curr_eraser_size / EditorData.camera.zoom.x
		var vec_size = Vector2(rect_size, rect_size)
		var mouse_rect = Rect2(EditorData.world_pos, Vector2.ZERO).grow(rect_size * 0.5)
		var mouse_cell = round(EditorData.world_pos / EditorData.SPATIAL_GRID_SIZE)
		for x in range(-1, 2):
			for y in range(-1, 2):
				for line in EditorData.spatial_grid.get(Vector2i(mouse_cell) + Vector2i(x, y), []):
					if not (line is Line2D): continue
					if EditorFuncs.get_object_rect(line).grow(line.width / 2).intersects(mouse_rect):
						if is_rect_over_line2d(line, mouse_rect):
							for cell in line.get_meta("spatial_grid"):
								if EditorData.spatial_grid.has(cell):
									EditorData.spatial_grid[cell].erase(line)
									if EditorData.spatial_grid[cell].is_empty():
										EditorData.spatial_grid.erase(cell)
									
							if is_instance_valid(line):
								if line.get_parent() ==  EditorData.main.canvas:
									var undo_func = func(l):
										add_to_canvas(l)

									EditorHistory.create_action("erase", EditorFuncs.canvas_manager.remove_from_canvas.bind(line), undo_func.bind(line), true, null, line)
							else:
								pass #remove from grid?

## This function is called when the camera is moved / zoomed to update
## a CodeEdit if a text object is currently being edited
func update_text_edit_size():
	# Get the CodeEdit node (if it's being currently used by a text object)
	var curr_focused = EditorData.get_viewport().gui_get_focus_owner()
	if !curr_focused || curr_focused.is_queued_for_deletion() || !curr_focused.is_in_group("text_edit"):
		return
	
	var text_edit = curr_focused
	# Get the corresponding text object
	var target: Text = text_edit.get_meta("target_text").get_ref()
	text_edit.position = EditorFuncs.get_world_to_screen_pos(target.position)
	text_edit.add_theme_font_size_override("font_size", target.curr_font_size * EditorData.camera.zoom.x)
	# We wait for a frame after setting the font size and position
	# to adjust the CodeEdit's size
	await EditorData.get_tree().process_frame
	if text_edit:
		text_edit.size.y = 0
		text_edit.size.x = 0
		text_edit.update_minimum_size()

func clear():
	for child in get_children():
		if child in copy_buffer:
			remove_from_canvas(child)
		else:
			child.queue_free()

func get_children():
	return EditorData.main.canvas.get_children()
	
func on_theme_change(old_palette):
	for line2d in EditorData.get_tree().get_nodes_in_group("lines"):
		var col_i = old_palette.find(line2d.default_color)
		if col_i >= 0:
			line2d.default_color = EditorColors.color_palette[col_i]
		
	for text in EditorData.get_tree().get_nodes_in_group("text"):
		var col_i = old_palette.find(text.curr_color)
		if col_i >= 0:
			text.curr_color = EditorColors.color_palette[col_i]
			text.modulate = text.curr_color
			
	for reg in EditorData.get_tree().get_nodes_in_group("export_region"):
		reg.update_colors()


func is_rect_over_line2d(line: Line2D, rect : Rect2):
	rect = rect.grow(line.width * 0.5)
	var r_top_left = rect.position
	var r_top_right = Vector2(rect.end.x, rect.position.y)
	var r_bottom_left = Vector2(rect.position.x, rect.end.y)
	var r_bottom_right = rect.end
	
	var rect_segments = [
		[r_top_left, r_top_right],
		[r_top_right, r_bottom_right],
		[r_bottom_right, r_bottom_left],
		[r_bottom_left, r_top_left]
	]
	
	for point_i in range(line.points.size() - 1):
		var curr_point = line.points[point_i] + line.position
		if rect.has_point(curr_point):
			return true
			
		var next_point = line.points[point_i + 1] + line.position
		for edge in rect_segments:
			if Geometry2D.segment_intersects_segment(curr_point, next_point, edge[0], edge[1]):
				return true
	return false


func clear_spatial_grid_pos(obj):
	var curr_cells = obj.get_meta("spatial_grid", [])
	for cell in curr_cells:
		if EditorData.spatial_grid.has(cell):
			EditorData.spatial_grid[cell].erase(obj)
	
	obj.set_meta("spatial_grid", [])

func set_spatial_grid_pos(obj):
	clear_spatial_grid_pos(obj)
	var curr_rect = EditorFuncs.get_object_rect(obj)
	var start_cell = (curr_rect.position / EditorData.SPATIAL_GRID_SIZE).floor()
	var end_cell = (curr_rect.end / EditorData.SPATIAL_GRID_SIZE).floor()
	
	var curr_spatial_grid = []
	for x in range(int(start_cell.x), int(end_cell.x) + 1):
		for y in range(int(start_cell.y), int(end_cell.y) + 1):
			var new_pos = Vector2i(x, y)
			curr_spatial_grid.append(new_pos)
	
			if !EditorData.spatial_grid.has(new_pos):
				EditorData.spatial_grid[new_pos] = [obj]
			else:
				if !(obj in EditorData.spatial_grid[new_pos]):
					EditorData.spatial_grid[new_pos].append(obj)
		
	obj.set_meta("spatial_grid", curr_spatial_grid)

func get_lines_under_rect(rect: Rect2) -> Array:
	var start_cell = (rect.position / EditorData.SPATIAL_GRID_SIZE).floor()
	var end_cell = (rect.end / EditorData.SPATIAL_GRID_SIZE).floor()

	
	var objs = []
	for x in range(int(start_cell.x), int(end_cell.x) + 1):
		for y in range(int(start_cell.y), int(end_cell.y) + 1):
			var new_pos = Vector2i(x, y)
			if EditorData.spatial_grid.has(new_pos):
				var cell_objs = EditorData.spatial_grid[new_pos]
				for obj in cell_objs:
					if obj is Line2D:
						if !(obj in objs) && is_rect_over_line2d(obj, rect):
							objs.append(obj)
	return objs
