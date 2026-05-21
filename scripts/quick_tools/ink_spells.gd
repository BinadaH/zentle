extends MarginContainer

@export var container: GridContainer
@export var missing_letters_ui: VBoxContainer
@export var letters_saved_ui: Label

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
		
		var trigger_line_edit = LineEdit.new()
		trigger_line_edit.text = trigger
		trigger_line_edit.connect("text_changed", func(new_text):
			EditorFuncs.ink_spells_manager.update_spell_trigger(spell_i, new_text)
		)
	
		var path_button = Button.new()
		path_button.text = file_path.get_base_dir().get_file().path_join(file_path.get_file()) 
		path_button.connect("pressed", func():
			EditorFuncs.ui_manager.create_file_dialog(
				FileDialog.FileMode.FILE_MODE_OPEN_FILE,
				func(path):
					update_file_path(path_button, spell_i, path),
				["*.zentle"]
			)
		)
		
		var delete_button = Button.new()
		delete_button.icon = del_ico
		delete_button.expand_icon = true
		delete_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		container.add_child(trigger_line_edit)
		container.add_child(path_button)
		container.add_child(delete_button)
	
	missing_letters_ui.visible = are_letters_missing
	letters_saved_ui.visible = !are_letters_missing
	
		
func update_file_path(btn: Button, index: int, path: String):
	btn.text = path.get_base_dir().get_file().path_join(path.get_file()) 
	EditorFuncs.ink_spells_manager.update_spell_file_path(index, path)

@export var draw_letters_ui: MarginContainer
@export var home_ui: CenterContainer
func _on_start_btn_pressed():
	draw_letters_ui.visible = true
	home_ui.visible = false

func _on_draw_letters_visibility_changed():
	if !draw_letters_ui.is_visible_in_tree():
		home_ui.visible = true
		draw_letters_ui.visible = false
		var are_letters_missing = EditorFuncs.ink_spells_manager.get_missing_letters().size() > 0
		missing_letters_ui.visible = are_letters_missing
		letters_saved_ui.visible = !are_letters_missing
		
		
