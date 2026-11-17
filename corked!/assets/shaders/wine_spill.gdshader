shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform vec4 wine_color : source_color = vec4(0.38, 0.02, 0.07, 1.0);
uniform vec4 edge_color : source_color = vec4(0.22, 0.0, 0.04, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float ang = atan(p.y, p.x);

	// Wobbly outline so it does not look like a perfect circle
	float wobble = noise(vec2(cos(ang), sin(ang)) * 2.5 + seed) * 0.25
				 + noise(p * 6.0 + seed) * 0.08;
	float edge = 0.62 + wobble;
	float puddle = 1.0 - smoothstep(edge - 0.03, edge, d);

	// Small splatter drops just outside the puddle
	float drops = step(0.8, noise(p * 7.0 + seed * 3.0))
				* (1.0 - smoothstep(edge, edge + 0.25, d)) * step(d, 0.95);

	float shape = max(puddle, drops);
	if (shape < 0.01) {
		discard;
	}

	float rim = smoothstep(edge - 0.18, edge, d);
	ALBEDO = mix(wine_color.rgb, edge_color.rgb, rim);
	ROUGHNESS = 0.05;
	SPECULAR = 0.9;
	ALPHA = shape * fade * 0.9;
}
