extends MarginContainer

## NEEDS REFACTORING

@export var line_edit: LineEdit
@export var found_data_parent: VBoxContainer

var found_objs = []
func _on_button_pressed() -> void:
	found_objs.clear()
	var objs = EditorFuncs.canvas_manager.get_text_objs()
	for obj in objs:
		if obj.text.contains(line_edit.text):
			found_objs.append(obj)
	
	update_found_data()

func update_found_data():
	for child in found_data_parent.get_children():
		child.queue_free()

	for found_obj in found_objs:
		var h_box = HBoxContainer.new()
		h_box.custom_minimum_size.y = 10
		var label = Label.new()
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size = Vector2(150, 10)
		label.text = found_obj.text
		var btn = Button.new()
		btn.text = "Go"
		btn.pressed.connect(func():
			EditorFuncs.focus_cam_on(found_obj)
		)
		h_box.add_child(label)
		h_box.add_child(btn)
		found_data_parent.add_child(h_box)
