extends CanvasLayer
class_name UIManager

@onready var btn_size_container = $Control/view/top_panel/HBoxContainer/button_size
@onready var slider_size = $Control/view/top_panel/HBoxContainer/slider_size

class FileMenuItem:
	var callback: Callable
	var label
	
	func _init(label, callback):
		self.label = label
		self.callback = callback
	
var file_menu_items: Array[FileMenuItem] = [
	FileMenuItem.new("Save", self.save),
	FileMenuItem.new("Open", self.open),
	FileMenuItem.new("Options", self.options),
	FileMenuItem.new("New", self.new),
]

func _ready():
	EditorFuncs.set_ui_manager(self)
	load_color_grid()
	
	for item_id in range(file_menu_items.size()):
		var label = file_menu_items[item_id].label
		$Control/view/top_panel/HBoxContainer/MenuBar/file_menu.add_item(label, item_id)
	
	EditorFiles.set_file_dialog($open_save_dialog)
	EditorFiles.set_file_label($Control/view/top_panel/file_name)
	EditorFiles.set_confirm_dialog($ConfirmationDialog)
	
	EditorData.latex_preview = $latex_preview
	
	EditorOptions.connect("theme_changed", func(old_palette): reload_color_grid())
	
	# Setup Slider / Buttons size controls
	slider_size.value = EditorData.current_size / EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE] * 2.5
	
	var btn_size_img : Image = load("res://sprites/circle.png").get_image()
	var btn_sizes = [0.5, 1, 2]
	var num_sizes = btn_sizes.size()
	for size_i in range(num_sizes):
		var btn = Button.new()
		btn.custom_minimum_size.x = 20
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var t_img_dup = btn_size_img.duplicate()
		var img_size_step = log((size_i + 1) / float(num_sizes) + 1.5)
		t_img_dup.resize(16 * img_size_step, 16 * img_size_step)
		btn.icon = ImageTexture.create_from_image(t_img_dup)
		
		btn_size_container.call_deferred("add_child", btn)
		btn.connect("pressed", func(): 
			update_tool_sizes(btn_sizes[size_i])
			)

func update_tool_sizes(size):
	EditorData.current_size = size * 0.4 * EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	EditorData.current_text_size = size * EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]

	if !EditorTools.is_current(EditorTools.TOOLS.TEXT):
		EditorTools.set_tool(EditorTools.TOOLS.PEN)

func save():
	EditorFuncs.handle_save()
	
func new():
	EditorFuncs.begin_handle_new()
	
func open():
	EditorFuncs.begin_handle_open()
	
func options():
	EditorFuncs.toggle_quick_tools()
	
func _on_file_menu_id_pressed(id):
	var item = file_menu_items[id]
	if item:
		item.callback.call()
	
func set_stbox_unselected(btn: Button, col: Color):
	var normal_stylebox =  btn.get_theme_stylebox("normal")
	var hover_stylebox = btn.get_theme_stylebox("hover")
	var pressed_stylebox = btn.get_theme_stylebox("pressed")
	normal_stylebox.bg_color = col
	normal_stylebox.set_border_width_all(0)
	
	hover_stylebox.bg_color = col.darkened(0.2)
	hover_stylebox.set_border_width_all(0)
	
	pressed_stylebox.bg_color = col.darkened(0.3)
	pressed_stylebox.set_border_width_all(0)
	
func set_stbox_selected(btn: Button, col: Color):
	var normal_stylebox =  btn.get_theme_stylebox("normal")
	var hover_stylebox = btn.get_theme_stylebox("hover")
	var pressed_stylebox = btn.get_theme_stylebox("pressed")
	normal_stylebox.bg_color = col.darkened(0.2)
	normal_stylebox.set_border_width_all(4)
	normal_stylebox.border_color = Color.BLACK
	
	hover_stylebox.bg_color = col.darkened(0.4)
	hover_stylebox.set_border_width_all(4)
	hover_stylebox.border_color = Color.BLACK
	
	pressed_stylebox.bg_color = col.darkened(0.5)
	pressed_stylebox.set_border_width_all(4)
	pressed_stylebox.border_color = Color.BLACK

func load_btn_stylebox(btn: Button):
	var normal_stylebox = StyleBoxFlat.new()
	var hover_stylebox = StyleBoxFlat.new()
	var pressed_stylebox = StyleBoxFlat.new()
	btn.add_theme_stylebox_override("normal", normal_stylebox)
	btn.add_theme_stylebox_override("hover", hover_stylebox)
	btn.add_theme_stylebox_override("pressed", pressed_stylebox)
	

func update_btn_stylebox_selected(btn: Button, idx: int):
	var col: Color = EditorColors.color_palette[idx]
	

var prev_sel_btn_i = -1
func load_color_grid():
	var col_btns = $Control/view/top_panel/HBoxContainer/color_grid/GridContainer.get_children()
	for i_btn in range(col_btns.size()):
		var btn = col_btns[i_btn]
		var col = EditorColors.color_palette[i_btn]
		load_btn_stylebox(btn)
		set_stbox_unselected(btn, col)
		
		btn.connect("pressed", func(): 
			EditorFuncs.handle_change_color(EditorColors.color_palette[i_btn])
			set_stbox_selected(btn, EditorColors.color_palette[i_btn])
			if prev_sel_btn_i >= 0 && prev_sel_btn_i != i_btn:
				set_stbox_unselected(col_btns[prev_sel_btn_i], EditorColors.color_palette[prev_sel_btn_i])
			
			prev_sel_btn_i = i_btn
		)
		
func reload_color_grid():
	var col_btns = $Control/view/top_panel/HBoxContainer/color_grid/GridContainer.get_children()
	for i_btn in range(col_btns.size()):
		var btn = col_btns[i_btn]
		var col = EditorColors.color_palette[i_btn]
		load_btn_stylebox(btn)
		set_stbox_unselected(btn, col)


func _on_pen_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.PEN)

func _on_hand_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.HAND)

func _on_select_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.SELECT)

func _on_delete_btn_pressed():
	EditorTools.delete()

func _on_text_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.TEXT)

func _on_eraser_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.ERASER)

func _on_copy_btn_pressed():
	EditorFuncs.handle_copy()

func _on_paste_btn_pressed():
	EditorFuncs.handle_paste()

func _on_pen_size_value_changed(value):
	update_tool_sizes(value)
	
func _on_quick_controls_container_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
			EditorFuncs.toggle_quick_tools()

## Switch between Slider / Buttons size controls
func _on_show_size_slider_pressed():
	slider_size.visible = !slider_size.visible
	btn_size_container.visible = !btn_size_container.visible

func _on_animation_player_animation_started(anim_name):
	EditorFuncs.request_high_performance()

func _on_animation_player_animation_finished(anim_name):
	EditorFuncs.release_high_performance()

func _on_export_reg_btn_pressed():
	EditorTools.set_tool(EditorTools.TOOLS.EXPORT_REGION)

var select_btn_timer : SceneTreeTimer = null
func toggle_select_btn():
	EditorTools.set_tool(EditorTools.TOOLS.EXPORT_REGION)
	_clear_select_btn_timer()
	
func _clear_select_btn_timer():
	if select_btn_timer:
		select_btn_timer.disconnect("timeout", toggle_select_btn)
		select_btn_timer = null

func _on_select_btn_button_down():
	select_btn_timer = get_tree().create_timer(0.5)
	select_btn_timer.connect("timeout", toggle_select_btn)

func _on_select_btn_button_up():
	if select_btn_timer:
		EditorTools.set_tool(EditorTools.TOOLS.SELECT)
		_clear_select_btn_timer()
		
