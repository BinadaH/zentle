extends Node

var world_pos: Vector2 = Vector2()
var screen_pos: Vector2 = Vector2()
var mouse_relative: Vector2 = Vector2()
var snapped_world_relative: Vector2 = Vector2()
var pressure: float = 1

var mouse_down: bool = false
var middle_down: bool = false
var camera: EditorCamera

var ctrl_pressed: bool = false
var shift_pressed: bool = false

var current_color: Color = Color.WHITE
var current_size: float = 10
var current_text_size: int = 50	
var curr_eraser_size: int = 10

var main: Main
var draw_ui: Node2D
var draw_line: Control

var spatial_grid = {}

var SPATIAL_GRID_SIZE = 100

var can_use_shortcuts = true
var quick_tools_opened = false

func main_ready(main: Main):
	self.main = main
	
func _ready():
	EditorOptions.connect("theme_changed", func(col): draw_ui.queue_redraw())
