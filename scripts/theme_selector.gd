extends MarginContainer

@onready var themes_btn_container = $ThemeSelector/themes
func _ready():
	EditorOptions.connect("config_loaded", func():
		for theme in EditorOptions.all_themes:
			var btn = Button.new()
			btn.text = get_theme_name(theme)
			btn.connect("pressed", func(): 
				EditorOptions.load_theme(theme)
			)
			themes_btn_container.add_child(btn)
		)

func get_theme_name(theme: String):
	var theme_name = theme.lstrip("theme")
	theme_name = " ".join(theme_name.split("_")).trim_prefix(" ").capitalize()
	return theme_name
	
func _on_line_edit_text_changed(new_text):
	for btn in themes_btn_container.get_children():
		btn.visible = !new_text || btn.text.contains(new_text)

@onready var line_edit : LineEdit = $ThemeSelector/LineEdit
func on_visible():
	line_edit.grab_focus()
