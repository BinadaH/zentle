extends MarginContainer

@export var container: GridContainer
@export var missing_letters_ui: VBoxContainer
@export var letters_saved_ui: Label
@export var list_saved_ui: MarginContainer
@export  var list_btn: Button

func _ready():
	load_spells()

@onready var del_ico = preload("res://sprites/icons/delete_tool.png")
func load_spells():
	var are_letters_missing = false
	var spells = EditorFuncs.ink_spells_manager.spell_data
	for spell_i in range(spells.size()):
		var spell = spells[spell_i]
		var trigger: String = spell.get("trigger", null)
		var file_path = spell.get("file_path", null)
		if !trigger || !file_path: continue
		are_letters_missing = !EditorFuncs.ink_spells_manager.is_string_saved(trigger)
		
		create_spell_container_row(trigger, file_path)
	
	missing_letters_ui.visible = are_letters_missing
	letters_saved_ui.visible = !are_letters_missing

func create_spell_container_row(trigger, file_path):
	var trigger_line_edit = LineEdit.new()
	trigger_line_edit.text = trigger
	trigger_line_edit.placeholder_text = "Cannot be empty"
	trigger_line_edit.set_meta("curr_trigger", trigger)
	trigger_line_edit.connect("text_changed", func(new_text):
		var old_trigger = trigger_line_edit.get_meta("curr_trigger", "")
		EditorFuncs.ink_spells_manager.update_spell_trigger(old_trigger, new_text)
		var are_letters_missing = EditorFuncs.ink_spells_manager.get_missing_letters().size() != 0
		missing_letters_ui.visible = are_letters_missing
		letters_saved_ui.visible = !are_letters_missing
		trigger_line_edit.set_meta("curr_trigger", new_text)
	)

	var path_button = Button.new()
	path_button.text = file_path.get_base_dir().get_file().path_join(file_path.get_file()) if file_path else "Choose a file"
	path_button.custom_minimum_size.x = 200
	path_button.clip_text = true
	path_button.connect("pressed", func():
		var curr_trigger = trigger_line_edit.get_meta("curr_trigger", "")
		if curr_trigger:
			EditorFuncs.ui_manager.create_file_dialog(
				FileDialog.FileMode.FILE_MODE_OPEN_FILE,
				func(path):
					if path:
						update_file_path(path_button, curr_trigger, path)
						var are_letters_missing = EditorFuncs.ink_spells_manager.get_missing_letters().size() != 0
						missing_letters_ui.visible = are_letters_missing
						letters_saved_ui.visible = !are_letters_missing
					,
				["*.zentle"]
			)
		else:
			path_button.text = "Trigger cannot be empty"
			await get_tree().create_timer(1).timeout
			path_button.text = file_path.get_base_dir().get_file().path_join(file_path.get_file()) if file_path else "Choose a file"
			
	)
	
	var delete_button = Button.new()
	delete_button.icon = del_ico
	delete_button.expand_icon = true
	delete_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_button.connect("pressed", func():
		var curr_trigger = trigger_line_edit.get_meta("curr_trigger", "")
		EditorFuncs.ink_spells_manager.delete_spell(curr_trigger)
		trigger_line_edit.queue_free()
		path_button.queue_free()
		delete_button.queue_free()
	)
	
	container.add_child(trigger_line_edit)
	container.add_child(path_button)
	container.add_child(delete_button)

func show_draw_letters():
	draw_letters_ui.visible = true
	home_ui.visible = false
	list_saved_ui.visible = false
	list_btn.text = "List"
func show_home():
	draw_letters_ui.visible = false
	home_ui.visible = true
	list_saved_ui.visible = false
	list_btn.text = "List"
func show_list_saved():
	draw_letters_ui.visible = false
	home_ui.visible = false
	list_saved_ui.visible = true
	list_btn.text = "Back"
	
func update_file_path(btn: Button, trigger: String, path: String):
	btn.text = path.get_base_dir().get_file().path_join(path.get_file()) 
	EditorFuncs.ink_spells_manager.update_spell_file_path(trigger, path)

@export var draw_letters_ui: MarginContainer
@export var home_ui: CenterContainer
func _on_start_btn_pressed():
	draw_letters_ui.testing = false
	show_draw_letters()

func _on_draw_letters_visibility_changed():
	if !draw_letters_ui.is_visible_in_tree():
		home_ui.visible = true
		draw_letters_ui.visible = false

func _on_home_visibility_changed():
	if home_ui.visible:
		var are_letters_missing = EditorFuncs.ink_spells_manager.get_missing_letters().size() > 0
		missing_letters_ui.visible = are_letters_missing
		letters_saved_ui.visible = !are_letters_missing


@export var list_saved_container: GridContainer
func _on_list_saved_btn_pressed():
	if list_saved_ui.visible:
		show_home()
	else:
		show_list_saved()
		for c in list_saved_container.get_children():
			c.queue_free()
		
		for letter in EditorFuncs.ink_spells_manager.get_saved_letters():
			var l = Label.new()
			l.text = letter
			list_saved_container.add_child(l)
			
			var b1 = Button.new()
			b1.text = "Test"
			list_saved_container.add_child(b1)
			b1.connect("pressed", func():
				draw_letters_ui.testing = true
				draw_letters_ui.testing_letter = letter
				show_draw_letters()
			)
			
			var b2 = Button.new()
			b2.text = "Delete"
			list_saved_container.add_child(b2)
			b2.connect("pressed", func():
				EditorFuncs.ink_spells_manager.forget_letter(letter)
				list_saved_container.remove_child(l)
				list_saved_container.remove_child(b1)
				list_saved_container.remove_child(b2)
			)

func _on_add_new_spell_pressed():
	create_spell_container_row("", "")
