shader_type canvas_item;
 
// Permite capturar o que está desenhado atrás do ColorRect na tela
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Parâmetros editáveis no Inspetor da Godot
uniform vec4 water_color : source_color = vec4(0.05, 0.25, 0.45, 0.4); // Tom azulado profundo
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;                 // Velocidade da ondulação
uniform float wave_frequency : hint_range(1.0, 50.0) = 20.0;           // Quantidade de ondas
uniform float wave_amplitude : hint_range(0.001, 0.05) = 0.008;        // Intensidade da distorção

void fragment() {
	// Cria o movimento baseado no tempo do jogo
	vec2 uv = SCREEN_UV;
	
	// Distorce as coordenadas UV simulando a refração da água
	uv.x += sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
	uv.y += cos(uv.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
	
	// Pega a cor real da tela já distorcida
	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	
	// Mescla a cor da tela com a cor da água subaquática
	COLOR = mix(screen_color, water_color, water_color.a);
}