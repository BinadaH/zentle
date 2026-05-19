extends MarginContainer
class_name Text

var text = ""
@export var min_height = 50
@export var max_height = 500
@export var curr_font_size = 20
@export var curr_color = Color.WHITE
var text_edit: CodeEdit = null

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(text_edit):
			text_edit.queue_free()

func _ready():
	var cl = get_tree().get_nodes_in_group("canvas_ui")
	if cl and cl[0]:
		text_edit = CodeEdit.new()
		text_edit.connect("caret_changed", on_caret_changed)
		
		text_edit.add_auto_brace_completion_pair("$", "$")
		text_edit.auto_brace_completion_enabled = true
		text_edit.auto_brace_completion_highlight_matching = true
		
		#text_edit.mouse_default_cursor_shape = Control.CURSOR_ARROW
		text_edit.add_to_group("text_edit")
		text_edit.position = position
		text_edit.custom_minimum_size = Vector2(0, 0)
		
		text_edit.add_theme_font_size_override("font_size", curr_font_size)
		text_edit.add_theme_constant_override("line_spacing", 0)
		text_edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

		var focus_style_box = StyleBoxFlat.new()
		focus_style_box.shadow_size = 4
		focus_style_box.shadow_color = Color(0.292, 0.292, 0.292, 1.0)
		focus_style_box.bg_color = Color(0.089, 0.089, 0.089, 1.0)
		focus_style_box.set_content_margin_all(0)
		text_edit.add_theme_stylebox_override("focus", focus_style_box)

		
		cl[0].add_child(text_edit)
		
		text_edit.scroll_fit_content_height = true
		text_edit.scroll_fit_content_width = true
		
		text_edit.set_meta("target_text", weakref(self))
		
		text_edit.connect("focus_exited", Callable(self, "_on_text_edit_focus_exited"))
		text_edit.connect("gui_input", Callable(self, "_on_text_edit_gui_input"))
		text_edit.connect("focus_entered", Callable(self, "_on_text_edit_focus_entered"))
		
		if text != "":
			render(text)
	
	else:
		push_error("Didn't find canvas_layer")

func markdown_to_bbcode(markdown_text: String) -> String:
	var result = markdown_text
	var regex = RegEx.new()

	# Bold **T** [b]testo[/b]
	regex.compile("\\*\\*(.*?)\\*\\*")
	result = regex.sub(result, "[b]$1[/b]", true)

	# Underline __T__ [b]testo[/b]
	regex.compile("__(.*?)__")
	result = regex.sub(result, "[u]$1[/u]", true)

	return result


var latex_blocks = []
func render(text: String):
	EditorData.can_use_shortcuts = true
	if text == "":
		EditorFuncs.canvas_manager.remove_from_canvas(self)
		queue_free()
		return
	
	$content.visible = true
	for child in $content.get_children():
		$content.remove_child(child)
	
	self.text = text
	latex_blocks.clear()
	text = markdown_to_bbcode(text)
	var parsed_data = EditorFuncs.parse_text_and_latex(text)
	var line = HBoxContainer.new()
	for data in parsed_data:
		if data.type == "text" :
			var new_l = get_text_node()
			new_l.text = data.content
			line.add_child(new_l)
		elif data.type == "latex":
			if data.mode == "inline":
				var ret : ImageTexture = get_latex_img(data.content, curr_font_size, curr_font_size * 0.5)
				if ret:
					latex_blocks.append(data.content)
					var new_s = TextureRect.new()
					new_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
					new_s.expand_mode = TextureRect.EXPAND_KEEP_SIZE
					new_s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					
					new_s.texture = ret
					line.add_child(new_s)

		elif data.type == "newline":
			if line.get_child_count() == 0:
				var l = Control.new()
				l.custom_minimum_size.y = curr_font_size + 25
				$content.add_child(l)
			else:
				$content.add_child(line)
				line = HBoxContainer.new()
	
	if line.get_child_count() > 0:
		$content.add_child(line)

	size.y = 0
	size.x = 0
	update_minimum_size()
	text_edit.visible = false
	EditorFuncs.canvas_manager.set_spatial_grid_pos(self)

func edit_text():
	text_edit.add_theme_color_override("font_color", curr_color)
	$content.visible = false
	text_edit.visible = true
	EditorData.can_use_shortcuts = false
	text_edit.grab_focus()
	text_edit.add_theme_font_size_override("font_size", curr_font_size * EditorData.camera.zoom.x)
	text_edit.position = EditorFuncs.get_world_to_screen_pos(position)
	
	await get_tree().process_frame
	EditorFuncs.canvas_manager.update_text_edit_size()
	
func move_caret_to_mouse():
	var local_mouse = text_edit.get_local_mouse_pos()
	var caret_pos = text_edit.get_line_column_at_pos(local_mouse)
	text_edit.set_caret_column(caret_pos.x)
	text_edit.set_caret_line(caret_pos.y)

func _on_text_edit_focus_exited():
	text_edit.visible = false
	EditorData.latex_preview.visible = false
	render(text_edit.text)

func _on_text_edit_focus_entered():
	text_edit.text = text

func _on_text_edit_gui_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.ctrl_pressed:
				match event.keycode:
					KEY_PLUS:
						curr_font_size += 10
						text_edit.add_theme_font_size_override("font_size", curr_font_size)
						EditorFuncs.canvas_manager.update_text_edit_size()
					KEY_MINUS:
						curr_font_size = max(10, curr_font_size - 10)
						text_edit.add_theme_font_size_override("font_size", curr_font_size)
						EditorFuncs.canvas_manager.update_text_edit_size()
					KEY_ENTER:
						text_edit.release_focus()
						
		if event.keycode == KEY_ESCAPE:
			text_edit.release_focus()

func get_text_node():
	var new_l = RichTextLabel.new()
	new_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	new_l.fit_content = true
	new_l.bbcode_enabled = true
	new_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	new_l.add_theme_font_size_override("normal_font_size", curr_font_size)
	new_l.add_theme_font_size_override("bold_font_size", curr_font_size)
	new_l.add_theme_font_size_override("italics_font_size", curr_font_size)
	new_l.add_theme_font_size_override("bold_italics_font_size", curr_font_size)
	
	return new_l
	
func get_latex_img(expression: String, font_size: float, error_size: float) -> ImageTexture:
	return EditorFuncs.latex_generator.GetImage(expression, font_size, error_size)

func on_caret_changed():
	var line_i = text_edit.get_caret_line()
	var row_i = text_edit.get_caret_column()
	var caret_line: String = text_edit.get_line(line_i)
	var block_start = -1
	
	var caret_in_block = false
	var block = ""
	for char_i in caret_line.length():
		if caret_line[char_i] == '$':
			if block_start < 0:
				block_start = char_i
			else:
				if row_i >= block_start && row_i <= char_i:
					# Caret in $$ block
					caret_in_block = true
					block = caret_line.substr(block_start + 1, char_i - block_start - 1)
					break
				block_start = -1
	
	if caret_in_block:
		var ret : ImageTexture = get_latex_img(block, 30, 25)
		if ret:
			EditorData.latex_preview.visible = true
			EditorData.latex_preview.texture = ret
			EditorData.latex_preview.modulate = EditorColors.color_palette[0]
	else:
		EditorData.latex_preview.visible = false

func get_line_nodes() -> Array:
	return $content.get_children()
