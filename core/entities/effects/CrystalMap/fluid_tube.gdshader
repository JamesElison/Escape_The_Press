
shader_type canvas_item;
uniform float flow_speed : hint_range(0.1, 5.0) = 1.0;
uniform vec4 fluid_color : source_color = vec4(0.0, 0.6, 1.0, 0.9);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.2;

void fragment() {
    vec2 uv = UV;
    float t = TIME * flow_speed;
    
    // Flowing liquid
    float flow = sin(uv.y * 12.0 - t * 4.0 + uv.x * 3.0) * 0.5 + 0.5;
    float flow2 = sin(uv.y * 8.0 - t * 3.0) * 0.5 + 0.5;
    
    float mask = uv.x * (1.0 - uv.x) * 4.0; // center mask for tube
    vec4 col = fluid_color;
    col.a *= (flow * 0.6 + flow2 * 0.4) * mask;
    col.rgb += glow_intensity * flow * 0.3;
    
    COLOR = col;
}
