
shader_type canvas_item;
uniform float time_speed : hint_range(0.1, 5.0) = 1.5;
uniform vec4 color1 : source_color = vec4(0.1, 0.5, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.8, 1.0, 0.8);
uniform float swirl_intensity : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    float time = TIME * time_speed;
    
    float swirl = sin(angle * swirl_intensity + time * 2.0 + dist * 5.0) * 0.5 + 0.5;
    float pulse = sin(TIME * 1.2) * 0.2 + 0.8;
    
    vec4 col = mix(color1, color2, swirl);
    col.a *= (1.0 - dist * 1.2) * pulse;
    col.a = clamp(col.a, 0.0, 1.0);
    
    // Glow
    float glow = 1.0 - dist * 0.8;
    col.rgb += glow * 0.5 * color1.rgb;
    
    COLOR = col;
}
