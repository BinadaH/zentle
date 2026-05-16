class_name ExportManager

class Region:
	var panel: Panel

var region_container: Node2D
var curr_region: Region
var curr_rect: Rect2

func make_export():
	var regions = EditorFuncs.get_tree().get_nodes_in_group("export_region")
	print(regions)

func handle_mouse_down():
	curr_region = Region.new()
	curr_rect.position = EditorData.world_pos
	curr_rect.size = Vector2.ZERO
	
func handle_mouse_up():
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	if curr_region:
		if curr_rect.get_area() < sq_size * sq_size:
			curr_rect.size = Vector2(sq_size, sq_size) * 2
		var panel = Panel.new()
		panel.add_to_group("export_region")
		panel.position = curr_rect.position
		panel.size = curr_rect.size
		curr_region.panel = panel
		EditorFuncs.canvas_manager.add_to_canvas(panel)
	curr_region = null
	EditorData.draw_ui.queue_redraw()
	
func handle_mouse_movement():
	if EditorData.mouse_down:
		if curr_region:
			curr_rect.end = EditorData.world_pos
			EditorData.draw_ui.queue_redraw()

	
