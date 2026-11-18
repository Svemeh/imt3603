shader_type spatial;

uniform bool grass_verge = false;
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
	vec2 p=world_position.xz;
	vec2 cell=floor(p*17.0),f=fract(p*17.0);
	float nearest=2.0;
	vec2 pebble_id=cell;
	for(int x=-1;x<=1;x++) {
		for(int y=-1;y<=1;y++) {
			vec2 offset=vec2(float(x),float(y));
			vec2 id=cell+offset;
			vec2 point=offset+vec2(hash(id),hash(id+vec2(41.7,29.3)));
			float d=length(point-f);
			if(d<nearest) { nearest=d; pebble_id=id; }
		}
	}
	float broad=noise(p*1.7);
	float grain=noise(p*115.0);
	vec3 dust=mix(vec3(0.34,0.32,0.27),vec3(0.48,0.45,0.38),broad);
	vec3 stone=mix(vec3(0.29,0.285,0.255),vec3(0.61,0.58,0.50),hash(pebble_id+3.1));
	float pebbles=1.0-smoothstep(0.17,0.34,nearest);
	vec3 gravel=mix(dust,stone,pebbles*0.65)*(0.94+0.10*grain);
	// Pale compacted wheel traces run north with the truck, without hard borders.
	float tracks=exp(-pow((p.x-26.85)*4.0,2.0))+exp(-pow((p.x-28.23)*4.0,2.0));
	gravel=mix(gravel,vec3(0.48,0.455,0.395),tracks*0.12);
	if(grass_verge) {
		float edge=0.23+(noise(p*3.2)-0.5)*0.16;
		float cover=1.0-smoothstep(edge-0.04,edge+0.04,UV.x);
		vec3 green=mix(vec3(0.09,0.17,0.025),vec3(0.24,0.29,0.055),noise(p*24.0));
		gravel=mix(gravel,green,cover);
	}
	ALBEDO=gravel;
	ROUGHNESS=0.97;
	SPECULAR=0.12;
}
