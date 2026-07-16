extends CanvasSerializer

enum OBJECT_TYPES{
	LINE,
	TEXT,
	IMAGE,
	EXPORT_REGION
}

enum OBJECT_DATA{
	# Global
	TYPE,
	POSITION,

	COLOR_INDEX,
	COLOR, # if a col_i (color_index) is not specified, the object's Color will be saved
	
	# Line
	POINTS,
	PRESSURE_POINTS,
	WIDTH,
	STROKE_TYPE,
	
	# Image
	IMAGE_BUFFER,
	SIZE,
	
	# Text
	FONT_SIZE,
	TEXT,
	
	# Export region
	EXPORT_ON,
	EXPORT_TITLE,
	EXPORT_IDX
}

## This function loads and returns:
## the color index inside the palette if it's saved
## if not, it tries to load the direct Color.
## Color.WHITE if none of the above is found 
func load_col(data: Dictionary) -> Color:
	var col_i = data.get(OBJECT_DATA.COLOR_INDEX, -1)
	if col_i > -1: return EditorColors.color_palette[col_i]
	else: return data.get(OBJECT_DATA.COLOR, Color.WHITE)
	
## This function saves:
## the color index if the current color is present inside the palette
## if not, it save s the direct Color
func save_col(col: Color):
	var col_i = EditorColors.color_palette.find(col)
	if col_i > -1: return {OBJECT_DATA.COLOR_INDEX: col_i}
	else: return {OBJECT_DATA.COLOR: col}

func serialize_canvas():
	var data = {
		"version": CURR_FS_VERSION,
		"content": []
	}
	var line_manager = EditorFuncs.line_manager
	var children = EditorFuncs.canvas_manager.get_children()
	for child in children:
		if child is Line2D and child.width_curve:
			var press_points
			if child.has_meta("press_p"):
				press_points = child.get_meta("press_p")
			else:
				var curve = child.width_curve
				var pc = curve.point_count
				press_points = []
				press_points.resize(pc)
				for i in pc:
					press_points[i] = curve.get_point_position(i).y
				
			var line_obj : Dictionary[OBJECT_DATA, Variant] = {
				OBJECT_DATA.TYPE: OBJECT_TYPES.LINE,
				OBJECT_DATA.POINTS: child.points,
				OBJECT_DATA.POSITION: child.position,
				OBJECT_DATA.PRESSURE_POINTS: press_points,
				OBJECT_DATA.WIDTH: child.width,
				OBJECT_DATA.STROKE_TYPE: child.get_meta("stroke", line_manager.STROKE_TYPES.NORMAL)
			}
			line_obj.merge(save_col(child.default_color))
			data["content"].append(line_obj)
			
		elif child is TextureRect:
			var img_object = {
				OBJECT_DATA.TYPE: OBJECT_TYPES.IMAGE,
				OBJECT_DATA.POSITION: child.position,
				OBJECT_DATA.IMAGE_BUFFER: child.texture.get_image().save_webp_to_buffer(false, 0.75),
				OBJECT_DATA.SIZE: child.size,
			}
			
			data["content"].append(img_object)
			
		elif child.is_in_group("text"):
			var text_obj = {
				OBJECT_DATA.TYPE: OBJECT_TYPES.TEXT,
				OBJECT_DATA.POSITION: child.position,
				OBJECT_DATA.TEXT: child.text,
				OBJECT_DATA.FONT_SIZE: child.curr_font_size,
			}
			text_obj.merge(save_col(child.curr_color))
			data["content"].append(text_obj)
		elif child.is_in_group("export_region"):
			var export_region_obj = {
				OBJECT_DATA.TYPE: OBJECT_TYPES.EXPORT_REGION,
				OBJECT_DATA.POSITION: child.position,
				OBJECT_DATA.SIZE: child.size,
				OBJECT_DATA.EXPORT_ON: child.should_export(),
				OBJECT_DATA.EXPORT_TITLE: child.get_title(),
				OBJECT_DATA.EXPORT_IDX: child.export_index
			}
			data["content"].append(export_region_obj)
			
	return data

func deserialize_canvas(data: Dictionary):
	var return_data = []
	var line_manager = EditorFuncs.line_manager
	
	var text_scene = load("res://scenes/text.tscn")
	var export_region_scene = load("res://scenes/export_region.tscn")
	for obj in data.get("content", []):
		match obj.get(OBJECT_DATA.TYPE, null):
			OBJECT_TYPES.LINE:
				var l_type = obj.get(OBJECT_DATA.STROKE_TYPE)
				var l_d = line_manager.dash_line.duplicate() if l_type == line_manager.STROKE_TYPES.DASHED else line_manager.base_line.duplicate() 
					
				l_d.position = obj[OBJECT_DATA.POSITION]
				l_d.points = obj[OBJECT_DATA.POINTS] 
				l_d.default_color = load_col(obj)
				l_d.width = obj[OBJECT_DATA.WIDTH]
				l_d.set_meta("stroke", l_type)
				l_d.set_meta("col_i", obj.get(OBJECT_DATA.COLOR_INDEX, 0))
				
				
				l_d.width_curve = Curve.new()
				var curr_press_points = obj[OBJECT_DATA.PRESSURE_POINTS]
				var p_count = curr_press_points.size()
				for i in range(p_count):
					var x_pos = float(i) / max(1, p_count - 1)
					l_d.width_curve.add_point(Vector2(x_pos, curr_press_points[i]))
				l_d.set_meta("press_p", curr_press_points)
				
				return_data.append(l_d)
			
			OBJECT_TYPES.IMAGE:
				var r = TextureRect.new()
				r.position = obj[OBJECT_DATA.POSITION]
				var im = Image.new()
				im.load_webp_from_buffer(obj[OBJECT_DATA.IMAGE_BUFFER])
				r.texture = ImageTexture.create_from_image(im)
				
				r.size = obj.get(OBJECT_DATA.SIZE, r.size)
				return_data.append(r)
				
			OBJECT_TYPES.TEXT:
				var new_text = text_scene.instantiate()
				new_text.position = obj[OBJECT_DATA.POSITION]
				new_text.curr_font_size = obj[OBJECT_DATA.FONT_SIZE]
				
				return_data.append(new_text)
				
				new_text.text = obj[OBJECT_DATA.TEXT]
				new_text.curr_color = load_col(obj)
				new_text.modulate = new_text.curr_color
				new_text.set_meta("col_i", obj.get("col_i", 0))
			OBJECT_TYPES.EXPORT_REGION:
				var reg = export_region_scene.instantiate()
				reg.position = obj[OBJECT_DATA.POSITION]
				reg.title = obj[OBJECT_DATA.EXPORT_TITLE]
				reg.export_on = obj[OBJECT_DATA.EXPORT_ON]
				reg.export_index = obj[OBJECT_DATA.EXPORT_IDX]
				reg.size = obj[OBJECT_DATA.SIZE]
				
				return_data.append(reg)
				
	return return_data
