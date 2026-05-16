extends CanvasSerializer


enum OBJECT_TYPES{
	LINE,
	TEXT,
	IMAGE,
}

func load_col(data: Dictionary) -> Color:
	var col_i = data.get("col_i", -1)
	if col_i > -1: return EditorColors.color_palette[col_i]
	else: return data.get("col", Color.WHITE)
	
func save_col(col: Color):
	var col_i = EditorColors.color_palette.find(col)
	if col_i > -1: return {"col_i": col_i}
	else: return {"col": col}

func serialize_canvas():
	var data = {
		"version": CURR_FS_VERSION,
		"content": []
	}
	var line_manager = EditorFuncs.line_manager
	var children = EditorFuncs.canvas_manager.get_children()
	for child in children:
		if child is Line2D and child.width_curve:
			var curve = child.width_curve
			var press_points = []
			var pc = curve.point_count
			for i in pc:
				press_points.append(curve.get_point_position(i).y)
			
			var line_obj = {
				"type": OBJECT_TYPES.LINE,
				"points": child.points,
				"pos": child.position,
				"press": press_points,
				"width": child.width,
				"stroke": child.get_meta("stroke", line_manager.STROKE_TYPES.NORMAL)
			}
			line_obj.merge(save_col(child.default_color))
			data["content"].append(line_obj)
			
		elif child is TextureRect:
			data["content"].append({
				"type": OBJECT_TYPES.IMAGE,
				"p": child.position,
				"t": child.texture.get_image().save_webp_to_buffer(false, 0.75),
				"s": child.size,
			})
			
		elif child.is_in_group("text"):
			var text_obj = {
				"type": OBJECT_TYPES.TEXT,
				"p": child.position,
				"t": child.text,
				"f": child.curr_font_size,
			}
			text_obj.merge(save_col(child.curr_color))
			data["content"].append(text_obj)
			
	return data

func deserialize_canvas(data: Dictionary):
	var return_data = []
	var line_manager = EditorFuncs.line_manager
	
	var text_scene = load("res://scenes/text.tscn")
	for obj in data.get("content", []):
		match obj.get("type", null):
			OBJECT_TYPES.LINE:
				var l_type = obj.get("stroke")
				var l_d
				if l_type == line_manager.STROKE_TYPES.DASHED:
					l_d = line_manager.dash_line.duplicate()
				else:
					l_d = line_manager.base_line.duplicate()
					
				l_d.position = obj["pos"]
				l_d.points = obj["points"] 
				l_d.default_color = load_col(obj)
				l_d.width = obj["width"]
				l_d.set_meta("stroke", l_type)
				l_d.set_meta("col_i", obj.get("col_i", 0))
				
				l_d.width_curve = Curve.new()
				var p_count = obj["press"].size()
				for i in range(p_count):
					var x_pos = float(i) / max(1, p_count - 1)
					l_d.width_curve.add_point(Vector2(x_pos, obj["press"][i]))
				
				return_data.append(l_d)
			
			OBJECT_TYPES.IMAGE:
				var r = TextureRect.new()
				r.position = obj["p"]
				var im = Image.new()
				im.load_webp_from_buffer(obj["t"])
				r.texture = ImageTexture.create_from_image(im)
				
				r.size = obj.get("s", r.size)
				return_data.append(r)
				
			OBJECT_TYPES.TEXT:
				var new_text = text_scene.instantiate()
				new_text.position = obj["p"]
				new_text.curr_font_size = obj["f"]
				
				return_data.append(new_text)
				
				new_text.text = obj["t"]
				new_text.curr_color = load_col(obj)
				new_text.modulate = new_text.curr_color
				new_text.set_meta("col_i", obj.get("col_i", 0))
				
	return return_data
