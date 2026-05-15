class_name ExportManager

class Region:
	var panel: Panel

var region_container: Node2D
var curr_region: Region
var curr_rect: Rect2

var regions: Array[Region] = []
var selected_region : Region = null

func handle_mouse_down():
	if !selected_region:
		curr_region = Region.new()
		curr_rect.position = EditorData.world_pos
		curr_rect.size = Vector2.ZERO
	else:
		if EditorFuncs.selection_manager.selection_made:
			EditorFuncs.selection_manager._handle_existing_selection()
	
func handle_mouse_up():
	curr_rect = curr_rect.abs()
	if !curr_rect.has_area():
		var new_selected_region = get_region_under_mouse()
		if new_selected_region:
			selected_region = new_selected_region
			EditorFuncs.selection_manager.perform_objs_selection([selected_region.panel], selected_region.panel.get_global_rect())
		elif EditorFuncs.selection_manager.selection_made:
			if !EditorFuncs.selection_manager.selection_made.handle_selected:
				EditorFuncs.selection_manager.clear_selection_status()
				selected_region = null
		else:
			selected_region = null
	else:
		var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
		if curr_region:
			if curr_rect.get_area() < sq_size * sq_size:
				curr_rect.size = Vector2(sq_size, sq_size) * 2
			var panel = Panel.new()
			panel.position = curr_rect.position
			panel.size = curr_rect.size
			curr_region.panel = panel
			regions.append(curr_region)
			region_container.add_child(panel)
	curr_region = null
	EditorData.draw_ui.queue_redraw()
	
func handle_mouse_movement():
	if EditorData.mouse_down:
		if EditorFuncs.selection_manager.selection_made:
			EditorFuncs.selection_manager._handle_existing_selection()
		elif curr_region:
			curr_rect.end = EditorData.world_pos
			EditorData.draw_ui.queue_redraw()

func get_region_under_mouse():
	for reg in regions:
		if reg.panel.get_global_rect().has_point(EditorData.world_pos):
			return reg
	
