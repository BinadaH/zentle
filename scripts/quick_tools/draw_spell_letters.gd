extends MarginContainer


@export var curr_msg: Label
@export var next_btn: Button

var testing = false
var testing_letter = ""

var missing_letters = []
func _on_visibility_changed():
	if is_visible_in_tree():
		if testing:
			curr_msg.text = "Testing"
			next_btn.text = "Test"
		else:
			missing_letters = EditorFuncs.ink_spells_manager.get_missing_letters()
			curr_msg.text = "Write the letter %s" % [get_new_letter()]
			next_btn.text = "Next"
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

	
var strokes_to_save: Array[PackedVector2Array] = []
func end():
	strokes_to_save.append(PackedVector2Array(curr_line.points))
	curr_line = null
	EditorFuncs.release_high_performance()

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

func _on_next_btn_pressed():
	if testing:
		var pred = EditorFuncs.ink_spells_manager.PCR.get_prediction(strokes_to_save)
		curr_msg.text = "Predicted %s" % [pred]
		await get_tree().create_timer(1).timeout
		curr_msg.text = "Testing"
	else:
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

func _on_clear_btn_pressed():
	for line in draw_panel.get_children():
		line.queue_free()
	strokes_to_save = []
