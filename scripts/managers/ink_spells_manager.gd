class_name InkSpellsManager

const PATH = "user://ink_spells.json"
var spell_data = []
var trigger_spell = {
	
}

var PCR: PointCloudRecognition

var curr_loading_spell = null
func _init():
	PCR = PointCloudRecognition.new()
	load_spells()

func is_letter_saved(letter):
	return PCR.is_letter_saved(letter)
func is_string_saved(string):
	return PCR.is_string_saved(string)
func get_missing_letters():
	var missing = []
	for trigger in trigger_spell:
		for c in trigger.split(""):
			if !missing.has(c) && !PCR.is_letter_saved(c):
				missing.append(c)
	return missing
func get_saved_letters():
	return PCR.get_saved_letters()
func forget_letter(letter):
	PCR.forget_letter(letter)
	
func save_letter(letter: String, strokes: Array[PackedVector2Array]):
	PCR.save_sample(letter, strokes)
	
class StrokeToCheck:
	var rect: Rect2
	var strokes: Array[PackedVector2Array] = []
	
func check_spell(ink_spell_strokes: Array):
	if ink_spell_strokes.size() == 0: return
	var combined_strokes: Array[StrokeToCheck] = []
	for stroke in ink_spell_strokes:
		var curr_rect = EditorFuncs.get_points_rect(stroke)
		if !curr_rect.has_area(): continue
		var found = false
		for comb_stroke in combined_strokes:
			if comb_stroke.rect.grow(10).intersects(curr_rect):
				comb_stroke.strokes.append(stroke)
				comb_stroke.rect = comb_stroke.rect.merge(curr_rect)
				found = true
				break
		if !found:
			var comb_stroke = StrokeToCheck.new()
			comb_stroke.strokes.append(stroke)
			comb_stroke.rect = curr_rect
			combined_strokes.append(comb_stroke)

	var curr_trigger = ""
	for stroke_to_check in combined_strokes:
		curr_trigger += PCR.get_prediction(stroke_to_check.strokes)
	
	if trigger_spell.has(curr_trigger):
		var combined_rect = combined_strokes[0].rect
		for i in range(1, combined_strokes.size()):
			combined_rect = combined_rect.merge(combined_strokes[i].rect)
		var original_rect = trigger_spell[curr_trigger]["rect"]
		
		var scaling_factor = combined_rect.size / original_rect.size
		var translation = combined_rect.get_center() - original_rect.get_center()
		
		for obj in trigger_spell[curr_trigger]["data"]:
			var o = obj.duplicate()
			var curr_color_idx = EditorColors.color_palette.find(EditorData.current_color)
			o.set_meta("col_i", curr_color_idx)
			if curr_color_idx != -1:
				if o is Line2D:
					o.default_color = EditorColors.color_palette[curr_color_idx]
				elif o.is_in_group("text"):
					o.curr_color = EditorColors.color_palette[curr_color_idx]
					
			EditorFuncs.canvas_manager.rescale_obj(o, scaling_factor.x, original_rect.get_center())
			EditorFuncs.canvas_manager.move_obj(o, translation)
			EditorFuncs.canvas_manager.add_to_canvas(o)

func load_spells():
	var f = FileAccess.open(PATH, FileAccess.READ)
	if !f: return
	
	var content = f.get_as_text()
	f.close()
	if !content: return
	
	var json = JSON.parse_string(content)
	if !json: return
	
	for data in json:
		if data.get("file_path", "") != "" && data.get("trigger", "") != "":
			spell_data.append(data)
		
func load_files():
	for spell in spell_data:
		var trigger = spell.get("trigger", null)
		var file_path = spell.get("file_path", null)
		if !trigger || !file_path: continue
		load_spell_file(trigger, file_path)

func load_spell_file(trigger, file_path):
	if EditorFiles.end_open_path(file_path, true):
		var rect = EditorFuncs.get_object_rect(curr_loading_spell[0])
		for	obj in range(1, curr_loading_spell.size()):
			rect = rect.merge(EditorFuncs.get_object_rect(curr_loading_spell[obj]))
		trigger_spell[trigger] = {
			"data": curr_loading_spell,
			"rect": rect
		}

func save_file():
	print("Saved ink spells")
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(spell_data))
	f.close()
	
	if save_timer:
		save_timer = null

func get_spell_index_by_trigger(trigger):
	return spell_data.find_custom(func(a): return a["trigger"] == trigger)

var save_timer: SceneTreeTimer
func update_spell_trigger(old_trigger, new_trigger):
	if old_trigger && trigger_spell.has(old_trigger):
		var old_spell_objs = trigger_spell[old_trigger]
		trigger_spell.erase(old_trigger)
		trigger_spell[new_trigger] = old_spell_objs
	
	var indx = get_spell_index_by_trigger(old_trigger)
	if indx != -1:
		spell_data[indx]["trigger"] = new_trigger
	else:
		spell_data.append({
			"file_path": "",
			"trigger": new_trigger
		})
		
	check_timer_and_save()

func update_spell_file_path(trigger, file_path):
	var indx = get_spell_index_by_trigger(trigger)
	if indx != -1:
		spell_data[indx]["file_path"] = file_path
	else:
		spell_data.append({
			"file_path": file_path, 
			"trigger": trigger
		})
		
	load_spell_file(trigger, file_path)
	check_timer_and_save()

func delete_spell(trigger):
	var indx = get_spell_index_by_trigger(trigger)
	if indx != -1:
		spell_data.remove_at(indx)
	if trigger_spell.has(trigger):
		trigger_spell.erase(trigger)
		
	check_timer_and_save()

func check_timer_and_save():
	if save_timer:
		save_timer.time_left = 2
	else:
		save_timer = EditorFuncs.get_tree().create_timer(2)
		save_timer.connect("timeout", save_file)
