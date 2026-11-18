shader_type spatial;
render_mode cull_disabled;

varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),u.x),
		mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),u.x),u.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	vec2 q = UV * 2.0 - 1.0;
	float edge = length(q);
	float broad = noise(p*2.4);
	float fine = noise(p*29.0);
	float angle = atan(q.y, q.x);
	float scallop = sin(angle*5.0+1.4)*0.025+sin(angle*9.0)*0.018;
	float boundary = 0.84 + (broad-0.5)*0.23 + (fine-0.5)*0.10 + scallop;
	// A cutout fringe keeps the soil visible between tiny leaves at the edge.
	ALPHA = smoothstep(boundary+0.045, boundary-0.045, edge);
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	vec3 green = mix(vec3(0.075,0.17,0.022),vec3(0.21,0.30,0.045),noise(p*5.7));
	green = mix(green,vec3(0.32,0.31,0.075),step(0.77,fine)*0.35);
	ALBEDO = green * (0.82+0.32*fine);
	ROUGHNESS = 1.0;
}
