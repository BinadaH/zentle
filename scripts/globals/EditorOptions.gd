extends Node

signal theme_changed(old_palette)
signal config_loaded

var current_theme = ""

enum OPTIONS {
	SQ_SIZE,
	CTRL_TO_ZOOM,
	REALTIME_MOVE_SCALE,
	GRID_WEIGHT,
	SHAPE_RECOGNIZER_DELAY,
	UI_SCALE,
	SCRATCH_TO_ERASE,
	MAX_FPS
}

var options: Dictionary = {
	OPTIONS.SQ_SIZE: 100,
	OPTIONS.CTRL_TO_ZOOM: false,
	OPTIONS.REALTIME_MOVE_SCALE: true,
	OPTIONS.GRID_WEIGHT: 2,
	OPTIONS.SHAPE_RECOGNIZER_DELAY: 0.5,
	OPTIONS.UI_SCALE: 1,
	OPTIONS.SCRATCH_TO_ERASE: true,
	OPTIONS.MAX_FPS: 144
}

var string_options: Dictionary[OPTIONS, String] = {
	OPTIONS.SQ_SIZE: "sq_size",
	OPTIONS.CTRL_TO_ZOOM: "ctrl_to_zoom",
	OPTIONS.REALTIME_MOVE_SCALE: "realtime_move_scale",
	OPTIONS.GRID_WEIGHT: "grid_weight",
	OPTIONS.SHAPE_RECOGNIZER_DELAY: "shape_recognizer_delay",
	OPTIONS.UI_SCALE: "ui_scale",
	OPTIONS.MAX_FPS: "max_fps",
	OPTIONS.SCRATCH_TO_ERASE: "scratch_to_erase"
}

var shape_snap_tolerance = 0.5		#0.5 half a square
var shape_snap_dist = 20      		#dist before snapping

func set_and_save_editor_option(option: OPTIONS, value: Variant):
	options[option] = value
	config.set_value("editor", string_options[option], value)
	config.save(config_path)
	
	match option:
		OPTIONS.SQ_SIZE, OPTIONS.GRID_WEIGHT:
			EditorData.main.background.setup_grid_shader()
		OPTIONS.MAX_FPS:
			Engine.max_fps = value
	
func _ready():
	call_deferred("load_config_file")


var config: ConfigFile = ConfigFile.new()
var config_path = "user://settings.cfg"
func load_config_file():
	var err = config.load(config_path)
	if err != OK:
		save_default_settings()
		emit_signal("theme_changed", EditorColors.color_palette.duplicate())
		load_themes_from_settings()
		emit_signal("config_loaded")
		return
	
	for option in options.keys():
		options[option] = config.get_value("editor", string_options[option], options[option])
	
	load_themes_from_settings()
	
	var tmp_current_theme = config.get_value("editor", "current_theme", "theme_default")
	load_theme(tmp_current_theme)
	
	emit_signal("config_loaded")
	
	
var all_themes = {}
func load_themes_from_settings():
	for curr_theme_sec in config.get_sections():
		if curr_theme_sec.begins_with("theme"):
			var curr_theme_data = {
				"color_palette": []
			}
			for c in range(EditorColors.color_palette.size()):
				var key = EditorColors.color_names[c]
				curr_theme_data["color_palette"].append(Color(config.get_value(curr_theme_sec, key, EditorColors.color_palette[c])))
	
			curr_theme_data["background_col"] = Color(config.get_value(curr_theme_sec, "background_color", EditorColors.background_col))
			curr_theme_data["grid_col"] = Color(config.get_value(curr_theme_sec, "grid_color", EditorColors.grid_col))
			
			all_themes[curr_theme_sec] = curr_theme_data

func load_theme(theme: String):
	if !all_themes.has(theme):
		return
	
	if theme != current_theme:
		var old_palette = EditorColors.color_palette.duplicate()
		EditorColors.color_palette = all_themes[theme].get("color_palette", EditorColors.color_palette)
		EditorColors.background_col = all_themes[theme].get("background_col", EditorColors.background_col)
		EditorColors.grid_col = all_themes[theme].get("grid_col", EditorColors.grid_col)
		
		EditorColors.calc_ui_color_palette()
		EditorData.current_color = EditorColors.color_palette[0]
		
		current_theme = theme
		emit_signal("theme_changed", old_palette)
		config.set_value("editor", "current_theme", theme)
		config.save(config_path)

func save_default_settings():
	config.clear()
	for c in range(EditorColors.color_palette.size()):
		var key = EditorColors.color_names[c]
		config.set_value("theme_default", key, "#" + EditorColors.color_palette[c].to_html())
	
	config.set_value("theme_default", "background_color", "#" + EditorColors.background_col.to_html())
	config.set_value("theme_default", "grid_color", "#" + EditorColors.grid_col.to_html())
	
	var other_themes_to_save = {
		"theme_paper_soft": {
			"main_text":"#43403aff",
			"critical":"#c56b5bff",
			"important":"#a63d50ff",
			"quote":"#6b6badff",
			"meta":"#2a6286ff",
			"success":"#4a7c5fff",
			"background_color":"#e6e1d6ff",
			"grid_color":"#dcd7ccff"
		},
		"theme_gruvbox": {
			"main_text":"#ebdbb2ff",
			"critical":"#fb4934ff",
			"important":"#fabd2fff",
			"quote":"#83a598ff",
			"meta":"#d3869bff",
			"success":"#b8bb26ff",
			"background_color":"#282828ff",
			"grid_color":"#3c3836ff",
		},
		"theme_nord": {
			"main_text":"#d8dee9ff",
			"critical":"#bf616aff",
			"important":"#ebcb8bff",
			"quote":"#88c0d0ff",
			"meta":"#5e81acff",
			"success":"#a3be8cff",
			"background_color":"#2e3440ff",
			"grid_color":"#3b4252ff",
		}
	}
	
	for theme in other_themes_to_save:
		var theme_colors = other_themes_to_save[theme]
		for col_name in theme_colors:
			config.set_value(theme, col_name, theme_colors[col_name])
	
	
	for option in options.keys():
		config.set_value("editor", string_options[option], options[option])
	
	config.set_value("editor", "current_theme", "theme_default")
	
	config.save(config_path)
