extends Node

var color_palette = [
	Color("#c9c1b1"), #light
	Color("#EB9486"), #orange
	Color("cc506bff"), #red
	Color("#B8B8F3"), #purple
	Color("#2274A5"), #
	Color("65b085ff"),
]

var background_col: Color = Color("#212121")
var grid_col: Color = Color("#2C2C2C")

enum UI {
	TEXT_MAIN, TEXT_DARK, TEXT_LIGHT,
	BG_DARK, BG_PANEL,
	PRIMARY, PRIMARY_HOVER, PRIMARY_PRESSED, PRIMARY_TRANSPARENT,
	ACCENT, SUCCESS, SUCCESS_BG, BTN_BG_NORMAL, BTN_BG_HOVER, BTN_BG_PRESSED,
	BTN_BORDER, BTN_BORDER_HOVER, BTN_TEXT, BTN_TEXT_HOVER, BTN_TEXT_DISABLED
}

var ui_palette = {
	
}

var color_names = [
	"main_text",
	"critical",
	"important",
	"quote",
	"meta",
	"success"
]

var current_theme = "theme"

func _ready():
	calc_ui_color_palette()
	EditorOptions.connect("theme_changed", update_ui_theme)



func calc_ui_color_palette():
	var base_txt = color_palette[0]
	var button_normal = color_palette[4]
	var success = color_palette[5]

	ui_palette[UI.TEXT_MAIN] = base_txt
	ui_palette[UI.TEXT_DARK] = base_txt.darkened(0.4)
	ui_palette[UI.TEXT_LIGHT] = base_txt.lightened(0.3)
	
	ui_palette[UI.BG_DARK] = base_txt.darkened(0.85)
	ui_palette[UI.BG_PANEL] = background_col.darkened(0.7)
	
	ui_palette[UI.PRIMARY] = button_normal
	ui_palette[UI.PRIMARY_HOVER] = button_normal.lightened(0.12)
	ui_palette[UI.PRIMARY_PRESSED] = button_normal.darkened(0.15)
	ui_palette[UI.PRIMARY_TRANSPARENT] = Color(button_normal.r, button_normal.g, button_normal.b, 0.2)
	
	ui_palette[UI.ACCENT] = color_palette[3] 
	
	ui_palette[UI.SUCCESS] = success
	ui_palette[UI.SUCCESS_BG] = success.darkened(0.6)
	
	var base_bg = grid_col
	var is_dark = base_bg.v < 0.5
	
	if is_dark:
		ui_palette[UI.BTN_BG_NORMAL] = background_col.lightened(0.1)
		ui_palette[UI.BTN_BG_HOVER] = background_col.lightened(0.18)
		ui_palette[UI.BTN_BG_PRESSED] = background_col.darkened(0.25)
		ui_palette[UI.BTN_BORDER] = base_bg.lightened(0.08)
		ui_palette[UI.BTN_TEXT] = base_txt.darkened(0.1)
		ui_palette[UI.BTN_TEXT_HOVER] = Color.WHITE
	else:
		ui_palette[UI.BTN_BG_NORMAL] = background_col.darkened(0.6)
		ui_palette[UI.BTN_BG_HOVER] = background_col.darkened(0.5)
		ui_palette[UI.BTN_BG_PRESSED] = background_col.darkened(0.65)
		ui_palette[UI.BTN_BORDER] = base_bg.darkened(0.15)
		ui_palette[UI.BTN_TEXT] = base_txt.lightened(0.8)
		ui_palette[UI.BTN_TEXT_HOVER] = base_txt.darkened(0.15)

func get_color_index(color: Color) -> int:
	return color_palette.find(color)


@onready var default_theme = ThemeDB.get_project_theme()
@onready var st_box_normal = default_theme.get_stylebox("normal", "Button")
@onready var st_box_pressed = default_theme.get_stylebox("pressed", "Button")
@onready var st_box_hover = default_theme.get_stylebox("hover", "Button")
@onready var st_box_panel = default_theme.get_stylebox("panel", "Panel")
@onready var st_box_check_box = default_theme.get_stylebox("hover", "CheckBox")
@onready var st_box_slider = default_theme.get_stylebox("grabber_area", "HSlider")
@onready var st_box_slider_hover = default_theme.get_stylebox("grabber_area_highlight", "HSlider")
@onready var st_line_slider = default_theme.get_stylebox("slider", "HSlider")
func update_ui_theme(_old_palette):
	st_box_normal.bg_color = ui_palette[UI.BTN_BG_NORMAL]
	st_box_hover.bg_color = ui_palette[UI.BTN_BG_HOVER]
	st_box_pressed.bg_color = ui_palette[UI.BTN_BG_PRESSED]
	
	st_box_panel.bg_color = ui_palette[UI.BG_PANEL]

	st_box_check_box.bg_color = ui_palette[UI.BTN_BG_HOVER]

	st_box_slider.bg_color = ui_palette[UI.PRIMARY]
	st_box_slider_hover.bg_color = ui_palette[UI.PRIMARY_HOVER]
	st_line_slider.color = ui_palette[UI.TEXT_LIGHT]
