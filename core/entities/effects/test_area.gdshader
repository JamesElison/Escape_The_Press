shader_type canvas_item;

// Cores da neblina fria (Azul claro/Branco gélido)
uniform vec4 fog_color : source_color = vec4(0.8, 0.9, 1.0, 0.4);
uniform float speed : hint_range(0.0, 2.0) = 0.15;
uniform float density : hint_range(0.0, 1.0) = 0.5;

// Função de ruído psuedo-aleatório
float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(56.7823, 11.2382))) * 43758.5453);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM (Fractional Brownian Motion) para criar camadas suaves de neblina
float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 0.5;

	for (int i = 0; i < 4; i++) {
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 coord = UV * 4.0;
	
	// Move a neblina na diagonal continuamente
	vec2 motion = vec2(TIME * speed, TIME * speed * 0.5);
	
	float n = fbm(coord + motion);
	
	// Aplica densidade e opacidade
	float alpha = clamp(n * density, 0.0, 1.0);
	
	COLOR = vec4(fog_color.rgb, fog_color.a * alpha);
}
