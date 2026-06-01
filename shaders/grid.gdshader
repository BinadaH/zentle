shader_type canvas_item;

// Set by the background node
uniform float square_size = 50.0;
uniform float grid_weight = 1.0;
uniform vec3 grid_col = vec3(0.5, 0.5, 0.5);
uniform vec3 background_col = vec3(0.2, 0.2, 0.2);
uniform vec2 viewport_size;
uniform vec2 camera_position;
uniform float camera_zoom = 1.0;

void fragment() {
    vec2 screen_centered = (SCREEN_UV - 0.5) * viewport_size;
    vec2 world_pos = (screen_centered / camera_zoom) + camera_position;
    vec2 grid_pos = mod(world_pos, vec2(square_size));
    float target_thickness = max(grid_weight / pow(camera_zoom, 0.5), 0.05);
    vec2 blur = fwidth(world_pos);
    vec2 lines = smoothstep(target_thickness + blur, target_thickness - blur, grid_pos) 
               + smoothstep(square_size - target_thickness - blur, square_size - target_thickness + blur, grid_pos);
    float mask = clamp(lines.x + lines.y, 0.0, 1.0);
    
	COLOR = vec4(mix(background_col, grid_col, mask), 1.0);
}