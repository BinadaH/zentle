extends Node2D
class_name Main

@onready var canvas = $canvas
@onready var camera = $camera
@onready var background = $background
@export var ui: UIManager

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		EditorFiles.show_save_confirm_dialog(func(): get_tree().quit())

func _ready():
	get_tree().set_auto_accept_quit(false)
	EditorData.main_ready(self)
	EditorData.camera = camera
	EditorData.draw_line = ui.draw_line
	camera.connect("has_moved", background.update_material_position)
	camera.connect("has_zoomed", background.update_material_zoom)
	
	camera.connect("has_moved", EditorFuncs.cam_zoomed)
	camera.connect("has_zoomed", EditorFuncs.cam_moved)
	
	get_tree().root.connect("size_changed", func(): 
		background.update_material_position(EditorData.camera.position)
		background.update_material_zoom(EditorData.camera.zoom.x)
		EditorData.draw_line.clear_viewport(false)
	)
	
	EditorData.draw_ui = $draw_ui
	EditorFiles.set_animation_player($AnimationPlayer)
	
	EditorFuncs.animations = $AnimationPlayer
	
	$canvas_main/quick_controls_container.visible = false
	
	
	# Use low_processor_usage_mode when idling
	OS.low_processor_usage_mode = true
	OS.low_processor_usage_mode_sleep_usec = 45000
	EditorOptions.connect("config_loaded", func(): 
		Engine.max_fps = EditorOptions.options[EditorOptions.OPTIONS.MAX_FPS]
	)
	
	should_keep_rendering_on.append(ui.file_menu)

@onready var debug_info_label = $canvas_main/Control/debug_info
var time_since_last_render = 0
var frame_threshold = 1.5

# Nodes inside this array will keep rendering on when visible
var should_keep_rendering_on = []

func _process(delta):
	# If no active tasks are present (drawing, animations, ...)
	# turn off rendering
	if EditorFuncs.active_tasks > 0:
		RenderingServer.render_loop_enabled = true
		time_since_last_render = 0
	else:
		# Wait for a frame_threshold seconds before
		# turing redering off
		var keep_on = false
		for obj in should_keep_rendering_on:
			if obj.visible:
				keep_on = true
				break
		keep_on = keep_on || EditorFuncs.ui_manager.curr_conf_dialog != null
		
		if !keep_on:
			time_since_last_render += delta
			if time_since_last_render >= frame_threshold:
				RenderingServer.render_loop_enabled = false
	
	if !RenderingServer.render_loop_enabled: return

	var debug_info_text = ""
	debug_info_text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	debug_info_text += "Frame Time: " + str(Performance.get_monitor(Performance.TIME_PROCESS))
	
	debug_info_label.text = debug_info_text
	
func _input(event):
	# Turn rendering back on if any input is received
	RenderingServer.render_loop_enabled = true
	time_since_last_render = 0

func _unhandled_input(event):
	EditorInputs.handle_input(event)
