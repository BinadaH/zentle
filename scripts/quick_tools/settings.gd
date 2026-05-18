extends MarginContainer

var ui_scales = [0.75, 1.0, 1.25, 1.5, 1.75, 2]
@onready var option_button: OptionButton = $Settings/ui_scale/OptionButton
func _ready():
	# Load saved settings and setup UI after the config file is loaded
	EditorOptions.connect("config_loaded", func():
		load_settings()
	)

func load_settings():
	for s in ui_scales:
		option_button.add_item(str(s))
			
	# Select the saved ui_scale value from the config file
	# if the scale is a custom value ui_scales.find will return -1
	# which unselects the option button
	var saved_scale = EditorOptions.options[EditorOptions.OPTIONS.UI_SCALE]
	option_button.select(ui_scales.find(saved_scale))
	EditorFuncs.set_ui_scale(saved_scale)

func _on_option_button_item_selected(index):
	EditorFuncs.set_ui_scale(ui_scales[index])
