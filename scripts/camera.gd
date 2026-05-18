extends Camera2D
class_name EditorCamera

signal has_moved(pos: Vector2)
signal has_zoomed(zoom: float)

var m_rel = Vector2()
var new_pos = Vector2()
var target_zoom = 1

var move = false
var moving = false
var zooming = false

const CAM_SPEED = 15
const CAM_SMOOTHNESS = 10
const ZOOM_SENSITIVITY = 1.1

var cam_vel = Vector2()
var target_vel = Vector2()
func _unhandled_input(event):
	if EditorFuncs.line_manager.current_line: return
	
	if event is InputEventMouseMotion:
		if (EditorData.middle_down) || (EditorTools.is_current(EditorTools.TOOLS.HAND) && EditorData.mouse_down):
			position -= EditorData.mouse_relative / zoom.x
			emit_signal("has_moved", position)
			
	elif event is InputEventMouseButton:
		# Prevent zooming when quicktools panel is opened
		if !EditorData.quick_tools_opened:
			
			# Handle zoom
			if EditorOptions.options[EditorOptions.OPTIONS.CTRL_TO_ZOOM] == event.ctrl_pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					z_slider.value = snapped(clamp(z_slider.value * ZOOM_SENSITIVITY, MIN_CAM_ZOOM, MAX_CAM_ZOOM), 0.001)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					z_slider.value = snapped(clamp(z_slider.value / ZOOM_SENSITIVITY, MIN_CAM_ZOOM, MAX_CAM_ZOOM), 0.001)
			
			# Handle scroll
			elif event.pressed:
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP:
						if event.shift_pressed:
							target_vel.x += -mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
						else:
							target_vel.y += -mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
					MOUSE_BUTTON_WHEEL_DOWN:
						if event.shift_pressed:
							target_vel.x += mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
						else:
							target_vel.y += mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
					MOUSE_BUTTON_WHEEL_LEFT:
						target_vel.x += -mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
					MOUSE_BUTTON_WHEEL_RIGHT:
						target_vel.x += mouse_wheel_pan_modifier(event.factor) * CAM_SPEED / target_zoom
	
	# Handle touchpad two finger zoom
	if event is InputEventKey:
		if event.pressed && event.ctrl_pressed:
			if event.keycode == KEY_KP_ADD:
				z_slider.value = min(MAX_CAM_ZOOM, z_slider.value + 0.1)
			elif event.keycode == KEY_KP_SUBTRACT:
				z_slider.value = max(MIN_CAM_ZOOM, z_slider.value - 0.1)
				
func mouse_wheel_pan_modifier(x):
	return x

const MIN_CAM_ZOOM = 0.15
const MAX_CAM_ZOOM = 1
func _ready() -> void:
	target_zoom = 1
	zoom = Vector2(target_zoom, target_zoom)
	z_slider.value  = target_zoom
	
	emit_signal("has_moved", position)
	emit_signal("has_zoomed", zoom.x)

func _process(delta: float) -> void:
	cam_vel = cam_vel.lerp(target_vel, delta * CAM_SMOOTHNESS)
	if cam_vel.length_squared() > 0.01:
		EditorFuncs.request_high_performance(0)
		position += cam_vel
		moving = true
		emit_signal("has_moved", position)
	elif moving:
		EditorFuncs.release_high_performance(0)
		moving = false
		
	target_vel = target_vel.lerp(Vector2.ZERO, 0.5)
	if target_vel.length_squared() < 0.01:
		target_vel = Vector2.ZERO
		
	if abs(zoom.x - target_zoom) > 0.001:
		var new_zoom = lerp(zoom.x, float(target_zoom), delta * CAM_SMOOTHNESS)
		EditorFuncs.request_high_performance(0)
		set_zoom_to(new_zoom)
		zooming = true
	elif zooming:
		EditorFuncs.release_high_performance(0)
		set_zoom_to(target_zoom)
		zooming = false

@export var z_slider: VSlider
func set_zoom_to(val):
	val = max(min(MAX_CAM_ZOOM, val), MIN_CAM_ZOOM)
	zoom = Vector2(val, val)
	emit_signal("has_zoomed", zoom.x)

func _on_v_slider_value_changed(value: float) -> void:
	if !EditorFuncs.line_manager.current_line:
		target_zoom = max(MIN_CAM_ZOOM, min(MAX_CAM_ZOOM, value))
	else:
		z_slider.value = target_zoom
	
func reset():
	z_slider.value = 1
	position = Vector2.ZERO
	emit_signal("has_moved", position)

func move_to(pos):
	position = pos
	emit_signal("has_moved", position)
func zoom_to(val):
	val = max(min(MAX_CAM_ZOOM, val), MIN_CAM_ZOOM)
	z_slider.value = val
