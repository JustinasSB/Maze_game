shader_type spatial;

uniform sampler2D albedo;
uniform sampler2D normal;
uniform sampler2D roughness;
uniform float scale;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//COLOR = texture(albedo, UV);
	vec4 tex = texture(albedo, UV*150.);
	vec3 rog = 
	ALBEDO = tex.rgb;
	NORMAL = texture(normal, UV*150.).rgb;
	//NORMAL_MAP = texture(normal, UV*60.).rgb;
	ROUGHNESS = texture(roughness, UV*150.).r;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
