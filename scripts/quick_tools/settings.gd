extends MarginContainer

var ui_scales = [0.75, 1.0, 1.25, 1.5, 1.75, 2]
@export var option_button: OptionButton
@export var float_tools: OptionButton
@export var settings_grid: GridContainer
func _ready():
	# Load saved settings and setup UI after the config file is loaded
	EditorOptions.connect("config_loaded", func():
		load_settings()
	)


var settings_to_load: Array[EditorOptions.OPTIONS] = [
	EditorOptions.OPTIONS.SQ_SIZE,
	EditorOptions.OPTIONS.CTRL_TO_ZOOM,
	EditorOptions.OPTIONS.REALTIME_MOVE_SCALE,
	EditorOptions.OPTIONS.SCRATCH_TO_ERASE,
	EditorOptions.OPTIONS.ZOOM_TO_CURSOR,
	EditorOptions.OPTIONS.MAX_FPS
]

func load_settings():
	# Load scales
	for s in ui_scales:
		option_button.add_item(str(s))
		
	
	# Float tools left and center
	float_tools.add_item(str("Left"))
	float_tools.add_item(str("Center"))
	float_tools.selected = EditorOptions.options[EditorOptions.OPTIONS.FLOAT_TOOLS]
			
	# Select the saved ui_scale value from the config file
	# if the scale is a custom value ui_scales.find will return -1
	# which unselects the option button
	var saved_scale = EditorOptions.options[EditorOptions.OPTIONS.UI_SCALE]
	option_button.select(ui_scales.find(saved_scale))
	EditorFuncs.set_ui_scale(saved_scale)
	
	
	# Load other settings
	for setting in settings_to_load:
		var lab = Label.new()
		lab.text = " ".join(EditorOptions.string_options[setting].split("_")).capitalize() + ": "
		settings_grid.add_child(lab)
		var setting_type = typeof(EditorOptions.options[setting])
		match setting_type:
			TYPE_BOOL:
				var btn = CheckBox.new()
				btn.button_pressed = EditorOptions.options[setting]
				btn.connect("pressed", func():
					EditorOptions.set_and_save_editor_option(setting, !EditorOptions.options[setting]) 
				)
				settings_grid.add_child(btn)
			TYPE_INT, TYPE_FLOAT:
				var spin = SpinBox.new()
				spin.max_value = 1000
				spin.min_value = 1
				spin.value = EditorOptions.options[setting]
				spin.connect("value_changed", func(val):
					EditorOptions.set_and_save_editor_option(setting, val if setting_type == TYPE_FLOAT else int(val)) 
				)
				settings_grid.add_child(spin)
			_:
				continue
		
		
				
func _on_option_button_item_selected(index):
	EditorFuncs.set_ui_scale(ui_scales[index])
	
func _on_float_tools_btn_item_selected(index):
	EditorOptions.set_and_save_editor_option(EditorOptions.OPTIONS.FLOAT_TOOLS, index) 
