shader_type spatial;
render_mode cull_disabled;

varying vec3 world_position;

float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float grain=noise(world_position.xz*85.0);
	float wear=noise(world_position.xz*7.0);
	ALBEDO=COLOR.rgb*(0.86+0.18*wear+0.10*grain);
	ROUGHNESS=0.84+grain*0.12;
	SPECULAR=0.22;
}
