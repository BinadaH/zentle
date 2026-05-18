extends MarginContainer


func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			load_export_regions()

@onready var container = $HBoxContainer/ScrollContainer/VBoxContainer2/container
@onready var line_scene = preload("res://scenes/quick_tools/exports_line.tscn")
# TODO: refactoring (shouldn't need to reload every time)
func load_export_regions():
	var lines = container.get_children()
	for line in lines:
		line.queue_free()
	
	var regs = get_tree().get_nodes_in_group("export_region")
	regs.sort_custom(func(a, b): return a.export_index < b.export_index)
	for reg in regs:
		var line = line_scene.instantiate()
		var export_btn = CheckButton.new()
		export_btn.button_pressed = reg.should_export()
		export_btn.size_flags_horizontal = Control.SIZE_EXPAND
		export_btn.connect("pressed", func():
			reg.toggle_export()
		)
		var go_to_btn = Button.new()
		
		go_to_btn.text = "->"
		go_to_btn.connect("pressed", func():
			EditorFuncs.close_quick_tools()
			EditorFuncs.focus_cam_on(reg)
		)
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND
		label.text = reg.get_title()
		
		line.add_child(label)
		line.add_child(export_btn)
		line.add_child(go_to_btn)
		line.set_meta("reg_obj", reg)
		
		container.add_child(line)
