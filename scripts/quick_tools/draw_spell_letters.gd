extends MarginContainer


@export var curr_msg: Label

var missing_letters = []
func _on_visibility_changed():
	if is_visible_in_tree():
		missing_letters = EditorFuncs.ink_spells_manager.get_missing_letters()
		curr_msg.text = "Write the letter %s" % [get_new_letter()]
	else:
		reset()
		
func get_new_letter():
	return missing_letters[-1] if missing_letters.size() > 0 else null
	
var curr_line: Line2D
@export var draw_panel: Panel
func _on_panel_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				begin()
			else:
				end()
	elif event is InputEventMouseMotion:
		var outside = event.position.x < 0 || event.position.y < 0 || event.position.x > draw_panel.size.x || event.position.y > draw_panel.size.y
		if outside: return
		update(event.position)

func begin():
	EditorFuncs.request_high_performance()
	curr_line = Line2D.new()
	curr_line.joint_mode = Line2D.LINE_JOINT_ROUND
	curr_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	curr_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	curr_line.width = 5
	draw_panel.add_child(curr_line)
	timer.stop()
	
var strokes_to_save: Array[PackedVector2Array] = []
func end():
	strokes_to_save.append(PackedVector2Array(curr_line.points))
	curr_line = null
	EditorFuncs.release_high_performance()
	timer.start()

@export var timer: Timer
func update(pos):
	if curr_line:
		var old_points = curr_line.points
		old_points.append(pos)
		curr_line.points = old_points
		
func reset():
	if curr_line:
		curr_line = null
		EditorFuncs.release_high_performance()
		
	for line in draw_panel.get_children():
		line.queue_free()
		
func _on_timer_timeout():
	for line in draw_panel.get_children():
		line.queue_free()
	
	EditorFuncs.ink_spells_manager.save_letter(missing_letters[-1], strokes_to_save)
	
	strokes_to_save = []
	missing_letters.pop_back()
	var new_letter = get_new_letter()
	if new_letter:
		curr_msg.text = "Write the letter %s" % [new_letter]
	else:
		visible = false
