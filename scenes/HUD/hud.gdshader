shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;

uniform float grain_amount : hint_range(0.0, 0.5) = 0.5;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	float dist = distance(SCREEN_UV, vec2(0.5, 0.5));
	float vignette = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);

	float noise = random(SCREEN_UV + TIME) - 0.5;

	COLOR = screen_color;
	COLOR.rgb *= (1.0 - vignette * vignette_strength);
	COLOR.rgb += noise * grain_amount;
}