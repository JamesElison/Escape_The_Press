
shader_type canvas_item;
uniform float time_speed : hint_range(0.1, 5.0) = 0.8;
uniform vec4 inner_color : source_color = vec4(0.6, 0.2, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.1, 0.5, 1.0, 1.0);

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv) * 2.0;
    float angle = atan(uv.y, uv.x);
    float t = TIME * time_speed;
    
    float spiral = sin(angle * 5.0 + dist * 4.0 - t * 3.0) * 0.5 + 0.5;
    float spiral2 = sin(angle * 3.0 - dist * 6.0 + t * 2.0) * 0.5 + 0.5;
    
    vec4 col = mix(inner_color, outer_color, spiral);
    col = mix(col, vec4(1.0,1.0,1.0,1.0), spiral2 * 0.3);
    
    float edge = smoothstep(1.0, 0.0, dist);
    float core = 1.0 - smoothstep(0.0, 0.8, dist);
    
    col.a *= edge * (0.7 + core * 0.5);
    COLOR = col;
}
