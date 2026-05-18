extends Node

enum TOOLS{
	PEN,
	HAND,
	SELECT,
	LINE,
	SPACER,
	TEXT,
	ERASER,
	EXPORT_REGION,
	NONE
}

var toggle_shortcuts = {
	KEY_E: TOOLS.ERASER,
	KEY_S: TOOLS.SELECT,
	KEY_H: TOOLS.HAND,
	KEY_Q: TOOLS.PEN,
	KEY_T: TOOLS.TEXT,
	KEY_R: TOOLS.EXPORT_REGION,
}

var preloaded_cursors : Dictionary[TOOLS, Image] = {
	
}

var current_tool: TOOLS = TOOLS.PEN
var saved_tool: TOOLS = TOOLS.NONE

func _ready():
	# Update the cursor when the user changes colors
	EditorFuncs.connect("user_color_changed", func(col): 
			if current_tool == TOOLS.TEXT || current_tool == TOOLS.PEN:
				update_cursor()
			)
			
	# Update the cursor when the user changes theme
	EditorOptions.connect("theme_changed", func(col): update_cursor())
	
	EditorData.current_color = EditorColors.color_palette[0]
	
	# Load Cursor Imgs
	
	preloaded_cursors[TOOLS.HAND] = load("res://sprites/icons/hand_cursor.png").get_image()
	preloaded_cursors[TOOLS.HAND].resize(32, 32)
	
	preloaded_cursors[TOOLS.SELECT] = load("res://sprites/icons/select_cursor.png").get_image()
	preloaded_cursors[TOOLS.SELECT].resize(32, 32)
	
	preloaded_cursors[TOOLS.EXPORT_REGION] = load("res://sprites/icons/region_cursor.png").get_image()
	preloaded_cursors[TOOLS.EXPORT_REGION].resize(32, 32)
	
	preloaded_cursors[TOOLS.ERASER] = Image.create(EditorData.curr_eraser_size, EditorData.curr_eraser_size, false, Image.FORMAT_RGB8)
	preloaded_cursors[TOOLS.PEN] = Image.create(4, 4, false, Image.FORMAT_RGB8)
	preloaded_cursors[TOOLS.TEXT] =  load("res://sprites/icons/text_cursor.png").get_image()
	
	
	update_cursor()
	
	
func is_current(_tool: TOOLS):
	return current_tool == _tool
	
var is_hold = false
func toggle_to(_tool: TOOLS, active: bool):
	if !active:
		if is_hold:
			set_tool(saved_tool)
		saved_tool = TOOLS.NONE
	elif !is_current(_tool):
		is_hold = false
		get_tree().create_timer(0.2).connect("timeout", func(): is_hold = true)
		saved_tool = current_tool
		set_tool(_tool)
	
func update_cursor():
	var img = preloaded_cursors[current_tool].duplicate()
	match current_tool:
		TOOLS.ERASER:
			img.fill(Color.WHITE)
		TOOLS.PEN:
			img.fill(EditorData.current_color)
		TOOLS.TEXT:
			var overlay = Image.create_empty(img.get_width(), img.get_height(), false, img.get_format())
			overlay.fill(EditorData.current_color)
			img.blit_rect_mask(overlay, img, Rect2i(Vector2.ZERO, overlay.get_size()), Vector2.ZERO)
	
	Input.set_custom_mouse_cursor(img, Input.CURSOR_ARROW, img.get_size() / 2)
		
func set_tool(_tool: TOOLS):
	if _tool == current_tool || _tool == TOOLS.NONE: 
		return

	# Clear the selection status when leaving Select tool
	if current_tool == TOOLS.SELECT:
		EditorFuncs.selection_manager.clear_selection_status()
		
	current_tool = _tool
	update_cursor()
	
func delete():
	var sel = EditorFuncs.selection_manager.selection_made
	if sel && sel.objs.size() > 0:
		EditorHistory.create_action("delete_selection", EditorFuncs.canvas_manager.remove_objs.bind(sel.objs.duplicate()), EditorFuncs.canvas_manager.add_objs.bind(sel.objs.duplicate()))
	
	EditorFuncs.selection_manager.clear_selection_status()
