extends Node

@onready var check_btn = $options/MarginContainer/HBoxContainer/CheckButton
@onready var line_edit = $options/MarginContainer/HBoxContainer/LineEdit

var export_index = 0
var title = ""
var export_on = false

func _ready():
	update_colors()
	check_btn.button_pressed = export_on
	line_edit.text = title

func update_colors():
	var st_box: StyleBoxFlat = $export_region.get_theme_stylebox("panel")
	var darker_bg = EditorColors.background_col.darkened(0.5)
	st_box.bg_color = Color(darker_bg, 0.3)
	st_box.border_color = EditorColors.background_col.lightened(0.1)
	
	st_box.set_border_width_all(5)

func should_export():
	return check_btn.button_pressed

func get_title():
	return line_edit.text if line_edit.text != "" else "Empty%s" % [export_index]

func get_options_bar():
	return $options

func toggle_export():
	check_btn.button_pressed = !check_btn.button_pressed


func _on_line_edit_text_changed(new_text):
	title = new_text
	
func _on_check_button_pressed():
	export_on = !export_on
