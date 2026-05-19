extends Node

signal user_color_changed(col: Color)

var line_manager: LineManager
var selection_manager: SelectionManger
var ui_manager: UIManager
var canvas_manager: CanvasManager
var export_manager: ExportManager


var latex_generator: GenerateLatexImg

func _init():
	line_manager = LineManager.new()
	selection_manager = SelectionManger.new()
	canvas_manager = CanvasManager.new()
	latex_generator = GenerateLatexImg.new()
	export_manager = ExportManager.new()
	
func _ready():
	EditorOptions.connect("theme_changed", canvas_manager.on_theme_change)
	
func set_ui_manager(manager):
	ui_manager = manager


var active_tasks : int = 0
## Call request_high_performance at the beginning of the event 
## and release_high_performance at the end.
##
## If not calling only once per event increment should be = 0 
## and call release_high_performance with decrement = 0 once the event has ended.
func request_high_performance(increment = 1):
	active_tasks += increment
	OS.low_processor_usage_mode = false

## Used with [method request_high_performance]
func release_high_performance(decrement = 1):
	active_tasks -= decrement
	if active_tasks <= 0:
		active_tasks = 0
		OS.low_processor_usage_mode = true
		
	
var animations: AnimationPlayer
func play_animation(anim_name, reversed = false):
	if reversed:
		animations.play_backwards(anim_name)
	else:
		animations.play(anim_name)
	
func toggle_quick_tools():
	if EditorData.quick_tools_opened:
		EditorFuncs.close_quick_tools()
	else:
		EditorFuncs.open_quick_tools()

func open_quick_tools():
	Input.set_custom_mouse_cursor(null)
	EditorData.quick_tools_opened = true
	play_animation("show_quick_tools")

func close_quick_tools():
	EditorData.quick_tools_opened = false
	EditorTools.update_cursor()
	play_animation("show_quick_tools", true)

func get_screen_to_world_pos(screen_pos : Vector2) -> Vector2:
	return EditorData.camera.position + (screen_pos - EditorData.main.get_viewport_rect().size / 2) / EditorData.camera.zoom.x

func get_world_to_screen_pos(world_pos : Vector2) -> Vector2:
	return (world_pos - EditorData.camera.position) * EditorData.camera.zoom.x + (EditorData.main.get_viewport_rect().size / 2)

func set_ui_scale(s: float):
	get_tree().root.content_scale_factor = s
	EditorOptions.set_and_save_editor_option(EditorOptions.OPTIONS.UI_SCALE, s)

func cam_zoomed(zoom):
	canvas_manager.update_text_edit_size()

func cam_moved(pos):
	canvas_manager.update_text_edit_size()

func focus_cam_on(obj):
	var rect = get_object_rect(obj).grow(100)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tween_pos = create_tween()
	var tween_zoom = create_tween()
	
	var target_zoom_vec = viewport_size / rect.size
	var target_zoom = min(target_zoom_vec.x, target_zoom_vec.y)
	
	tween_pos.set_trans(Tween.TRANS_CUBIC)
	tween_zoom.set_trans(Tween.TRANS_CUBIC)
	
	request_high_performance()
	request_high_performance()
	tween_pos.tween_method(EditorData.camera.move_to, EditorData.camera.position, (rect.position + rect.end) / 2, 0.7)
	
	tween_zoom.tween_method(EditorData.camera.zoom_to, EditorData.camera.zoom.x, target_zoom, 0.7)
	
	tween_pos.tween_callback(release_high_performance)
	tween_zoom.tween_callback(release_high_performance)
	
func handle_change_color(col: Color):
	if EditorTools.is_current(EditorTools.TOOLS.SELECT): 
		selection_manager.change_color(EditorData.current_color, col)
	elif !EditorTools.is_current(EditorTools.TOOLS.TEXT):
		EditorTools.set_tool(EditorTools.TOOLS.PEN)
	
	EditorData.current_color = col
	emit_signal("user_color_changed", col)

func handle_copy():
	if selection_manager.selection_made:
		canvas_manager.make_copy(selection_manager.selection_made.objs.duplicate())

func handle_paste():
	canvas_manager.paste_copy()
	
func handle_save():
	EditorFiles.begin_save_file()

func begin_handle_new():
	EditorFiles.show_confirm_dialog(self.end_handle_new)
	
func end_handle_new():
	reset()
	

func reset():
	selection_manager.clear_selection_status()
	canvas_manager.clear()
	EditorHistory.clear()
	EditorData.camera.reset()
	EditorFiles.set_current_path("")
	EditorData.spatial_grid.clear()
	
func begin_handle_open():
	EditorFiles.show_confirm_dialog(self.end_handle_open)
	
func end_handle_open():
	EditorFiles.begin_open_file()

func get_objects_rect(objs : Array) -> Rect2:
	var new_rect = null
	for o in objs:
		var r = get_object_rect(o)
		new_rect = r.merge(new_rect) if new_rect else r
		
	return new_rect

func get_points_rect(points: PackedVector2Array):
	if points.size() < 1: return Rect2()
	var r = Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r
	
func get_object_rect(obj) -> Rect2:
	if !obj: return Rect2()
	
	var r = Rect2()
	
	if obj is Line2D:
		r = get_points_rect(obj.points)
		r.position += obj.position
		
	elif obj is Control:
		r = obj.get_global_rect()
	elif obj is Sprite2D:
		if obj.texture:
			var s = obj.texture.get_size() * obj.scale
			r = Rect2(-s/2, s)
			r.position += obj.position
	elif obj.is_in_group("template"):
		r = get_objects_rect(obj.get_children())
		r.position += obj.position
	
	return r.abs()
	
func rect_intersects_rect_borders(rect1: Rect2, rect2: Rect2):
	if !rect1.intersects(rect2):
		return false
	if rect2.encloses(rect1) || rect1.encloses(rect2):
		return false

	return true

func get_grid_pos(world_pos, fac = 1) -> Vector2:
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	var x = round(world_pos.x / (sq_size * fac)) * (sq_size * fac)
	var y = round(world_pos.y / (sq_size * fac)) * (sq_size * fac)
	return Vector2(x, y)

func snap_to_grid(pos, fac = 1, threshold = 10):
	var g = get_grid_pos(pos, fac)
	return g if g.distance_to(pos) <= threshold else pos

func parse_text_and_latex(text: String):
	var segments = []
	var regex = RegEx.new()
	regex.compile("(?s)(\\$\\$|\\$)(.*?)\\1")
	
	var last_index = 0
	var matches = regex.search_all(text)
	
	for m in matches:
		var text_chunk = text.substr(last_index, m.get_start() - last_index)
		if text_chunk != "":
			var sub_parts = text_chunk.split("\n", true)
			for i in range(sub_parts.size()):
				if sub_parts[i] != "":
					segments.append({"type": "text", "content": sub_parts[i]})
				if i < sub_parts.size() - 1:
					segments.append({"type": "newline"})
		
		var tag_type = m.get_string(1)
		var content = m.get_string(2).strip_edges()
		segments.append({
			"type": "latex",
			"mode": "display" if tag_type == "$$" else "inline",
			"content": content
		})
		
		last_index = m.get_end()
	
	var final_chunk = text.substr(last_index)
	if final_chunk != "":
		var sub_parts = final_chunk.split("\n", true)
		for i in range(sub_parts.size()):
			if sub_parts[i] != "":
				segments.append({"type": "text", "content": sub_parts[i]})
			if i < sub_parts.size() - 1:
				segments.append({"type": "newline"})
				
	return segments
