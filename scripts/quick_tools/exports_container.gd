extends VBoxContainer


func move_to_index(child, index):
	move_child(child, index)
	var lines = get_children()
	for line_i in lines.size():
		var reg = lines[line_i].get_meta("reg_obj", null)
		if reg && is_instance_valid(reg):
			reg.export_index = line_i
