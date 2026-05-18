class_name ExportManager

class Region:
	var panel

var region_container: Node2D
var curr_region: Region
var curr_rect: Rect2

var generate_export: GenerateExport
var export_region_scene: PackedScene

func _init():
	export_region_scene = preload("res://scenes/export_region.tscn")
	generate_export = GenerateExport.new()
	var font = load("res://fonts/JetBrainsMono-Regular.ttf")
	generate_export.SetupFont(null)
	
func make_export():
	generate_export.Setup(EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE], EditorOptions.options[EditorOptions.OPTIONS.GRID_WEIGHT], EditorColors.background_col, EditorColors.grid_col)
	var regions = EditorFuncs.get_tree().get_nodes_in_group("export_region")
	regions.sort_custom(func(reg1, reg2): return reg1.export_index < reg2.export_index)
	var page_objs = []
	var page_positions = []
	var page_sizes = []
	for reg in regions:
		if !reg.should_export(): continue
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
		
		page_objs.append(items)
		page_positions.append(rect.position)
		page_sizes.append(rect.size)
	
	if page_objs.size() == 0: return
	var pdf = generate_export.ExportPdf(page_objs, page_positions, page_sizes)
	var f = FileAccess.open("res://test_export.pdf", FileAccess.WRITE)
	f.store_buffer(pdf)
	f.close()

func handle_mouse_down():
	curr_region = Region.new()
	curr_rect.position = EditorData.world_pos
	curr_rect.size = Vector2.ZERO

func handle_mouse_up():
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	var regions = EditorFuncs.get_tree().get_nodes_in_group("export_region")
	if curr_region && curr_rect.get_area() > sq_size * sq_size:
		var reg = export_region_scene.instantiate()
		reg.z_index = -1
		reg.position = curr_rect.position
		reg.size = curr_rect.size
		reg.export_index = regions.size()
		EditorFuncs.canvas_manager.add_to_canvas(reg)
	curr_region = null
	EditorData.draw_ui.queue_redraw()
	
func handle_mouse_movement():
	if EditorData.mouse_down:
		if curr_region:
			curr_rect.end = EditorData.world_pos
			EditorData.draw_ui.queue_redraw()

	
