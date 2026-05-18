extends HBoxContainer

func _get_drag_data(at_position):
	var preview = self.duplicate()
	preview.modulate.a = 0.5
	set_drag_preview(preview)
	
	return self

func _can_drop_data(at_position, data):
	if data is Control && data.get_parent() == get_parent() && data != self:
		var curr_index = get_index()
		var new_index = curr_index
		if at_position.y > size.y / 2:
			$Line2D.position.y = size.y
			$Line2D.show()
		else:
			$Line2D.position.y = 0
			$Line2D.show()
			
		return true
	return false

func _drop_data(at_position, data):
	var dragging = data as Control
	var curr_index = get_index()
	var new_index = curr_index
	if at_position.y > size.y / 2:
		new_index += 1

	get_parent().move_to_index(dragging, new_index)

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		$Line2D.hide()
	elif what == NOTIFICATION_MOUSE_EXIT:
		$Line2D.hide()
