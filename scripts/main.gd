extends Node2D
class_name Main

@onready var canvas = $canvas
@onready var camera = $camera
@onready var background = $background

func _ready():
	EditorData.main_ready(self)
	EditorData.camera = camera
	
	camera.connect("has_moved", background.update_material_position)
	camera.connect("has_zoomed", background.update_material_zoom)
	
	camera.connect("has_moved", EditorFuncs.cam_zoomed)
	camera.connect("has_zoomed", EditorFuncs.cam_moved)
	
	get_tree().root.connect("size_changed", func(): 
		background.update_material_position(EditorData.camera.position)
		background.update_material_zoom(EditorData.camera.zoom.x)
	)
	
	EditorData.draw_ui = $draw_ui
	EditorFiles.set_animation_player($AnimationPlayer)
	
	EditorFuncs.animations = $AnimationPlayer
	$canvas_main/MarginContainer.visible = false
	
	# TODO use OS.low_processor_usage_mode 
	# and RenderingServer.render_loop_enabled when idle
	Engine.max_fps = 120

func _unhandled_input(event):
	EditorInputs.handle_input(event)
