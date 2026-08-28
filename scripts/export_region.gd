extends VBoxContainer

@export var check_btn: CheckButton
@export var line_edit: LineEdit
@export var preset_option_button: OptionButton

var export_index = 0
var title = ""
var export_on = false

class Preset:
	var name: String = ""
	var size: Vector2
	func _init(name: String, size: Vector2):
		self.name = name
		self.size = size
	
var presets: Array[Preset] = [
	Preset.new("A4_Landscape", Vector2(842, 595)),
	Preset.new("A4_Portrait", Vector2(595, 842)),
]

func _ready():
	update_ui_scale()
	update_colors()
	check_btn.button_pressed = export_on
	line_edit.text = title

	preset_option_button.connect("item_selected", preset_changed)
	for preset in presets:
		preset_option_button.add_item(preset.name)

func preset_changed(idx: int):
	var new_preset = presets[idx]
	var offset = $options.size.y
	size = new_preset.size
	size.y += offset
	
func update_ui_scale():
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	check_btn.add_theme_font_size_override("font_size", sq_size * 0.5)
	line_edit.add_theme_font_size_override("font_size", sq_size * 0.5)
	preset_option_button.add_theme_font_size_override("font_size", sq_size * 0.5)
	$options.custom_maximum_size.y = sq_size
	
func update_colors():
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	var st_box: StyleBoxFlat = $export_region.get_theme_stylebox("panel").duplicate()
	$export_region.add_theme_stylebox_override("panel", st_box)
	var darker_bg = EditorColors.background_col.darkened(0.5)
	st_box.bg_color = Color(darker_bg, 0.3)
	st_box.border_color = EditorColors.background_col.lightened(0.1)
	
	st_box.set_border_width_all(sq_size * 0.2)

func should_export():
	return check_btn.button_pressed

func get_title():
	return line_edit.text if line_edit.text != "" else "Empty%s" % [export_index]

func get_options_bar():
	return $options

func toggle_export():
	check_btn.button_pressed = !check_btn.button_pressed

func set_export_to(to):
	export_on = to
	check_btn.set_pressed_no_signal(to)

func _on_line_edit_text_changed(new_text):
	title = new_text
	
func _on_check_button_pressed():
	export_on = !export_on

func _on_visible_on_screen_enabler_2d_screen_exited():
	line_edit.release_focus()
