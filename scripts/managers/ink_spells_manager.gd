class_name InkSpellsManager

const PATH = "user://ink_spells.json"
var spell_data = []
var trigger_spell = {
	
}

var PCR: PointCloudRecognition

var curr_loading_spell = null
func _init():
	load_spells()
	PCR = PointCloudRecognition.new()

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
	print(curr_trigger)
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
	var content = f.get_as_text()
	f.close()
	
	var json = JSON.parse_string(content)

	if json:
		spell_data = json
		
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
	
var save_timer: SceneTreeTimer
func update_spell_trigger(index, trigger):
	var old_trigger = spell_data[index].get("trigger", null)
	if old_trigger:
		var old_spell_objs = trigger_spell[old_trigger]
		trigger_spell.erase(old_trigger)
		trigger_spell[trigger] = old_spell_objs
		
	spell_data[index]["trigger"] = trigger
	check_timer_and_save()

func update_spell_file_path(index, file_path):
	spell_data[index]["file_path"] = file_path
	load_spell_file(spell_data[index]["trigger"], file_path)
	check_timer_and_save()
	
func check_timer_and_save():
	if save_timer:
		save_timer.time_left = 2
	else:
		save_timer = EditorFuncs.get_tree().create_timer(2)
		save_timer.connect("timeout", save_file)
