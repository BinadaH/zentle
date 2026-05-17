class_name ExportManager

class Region:
	var panel: Panel

var region_container: Node2D
var curr_region: Region
var curr_rect: Rect2

var generate_export: GenerateExport

func _init():
	generate_export = GenerateExport.new()
	var font = load("res://fonts/JetBrainsMono-Regular.ttf")
	generate_export.SetupFont(null)
	
func make_export():
	generate_export.Setup(EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE], EditorOptions.options[EditorOptions.OPTIONS.GRID_WEIGHT], EditorColors.background_col, EditorColors.grid_col)
	var regions = EditorFuncs.get_tree().get_nodes_in_group("export_region")
	var i = 0
	for reg in regions:
		var rect = reg.get_global_rect()
		var start_cell = (rect.position / EditorData.SPATIAL_GRID_SIZE).floor()
		var end_cell = (rect.end / EditorData.SPATIAL_GRID_SIZE).floor()
		
		var items = []
		for x in range(int(start_cell.x), int(end_cell.x + 1)):
			for y in range(int(start_cell.y), int(end_cell.y + 1)):
				var cell = Vector2i(x, y)
				for node in EditorData.spatial_grid[cell]:
					if !(node in items):
						items.append(node)
		
		var img = generate_export.ExportSvg(items, rect.position, rect.size)
		
		var f = FileAccess.open("res://img%s.svg" % [i], FileAccess.WRITE)
		f.store_buffer(img)
		f.close()
		i += 1
	
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
		panel.z_index = -1
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

	
