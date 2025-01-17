shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform vec4 albedo_alt : source_color;
uniform sampler2D texture_albedo_alt : source_color, filter_linear_mipmap, repeat_enable;


uniform float roughness : hint_range(0.0, 1.0);
uniform float roughness_alt : hint_range(0.0, 1.0);

uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_metallic_alt : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec4 metallic_texture_channel;
uniform vec4 metallic_texture_channel_alt;

uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_roughness_alt : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float specular_alt : hint_range(0.0, 1.0, 0.01);

uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform float metallic_alt : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal_alt : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);
uniform float normal_scale_alt : hint_range(-16.0, 16.0);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying vec3 vertex_local;
uniform vec3 object_size;
uniform sampler2D noise : source_color;
uniform float spread;
uniform float intensity;
uniform float height_offset;

uniform bool only_endFactor;

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;
    vertex_local = VERTEX; //(INV_VIEW_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0))).xyz;
}

void fragment() {
    vec2 base_uv = UV;
	
	vec3 heightOffset = vec3(0., height_offset, 0.);
    vec3 bottom_top = vertex_local + (object_size/2.) + heightOffset;
    vec3 normalized = bottom_top / object_size;
    float inversed = 1. - normalized.y;
    float endFactor = pow(inversed, intensity)*spread;
    endFactor = clamp(endFactor * texture(noise, UV).r + (endFactor/2.), 0, 1);

	if(!only_endFactor){
	    vec4 albedo_tex = texture(texture_albedo, base_uv);
	    vec4 albedo_tex_alt = texture(texture_albedo, base_uv);
	    ALBEDO = (albedo.rgb * albedo_tex.rgb * endFactor) + (albedo_alt.rgb * albedo_tex_alt.rgb * (1.-endFactor));

	    float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	    float metallic_tex_alt = dot(texture(texture_metallic_alt, base_uv), metallic_texture_channel_alt);
	    METALLIC = (metallic_tex * metallic * endFactor) + (metallic_tex_alt * metallic_alt * (1.-endFactor));
	    SPECULAR = specular * endFactor + specular * (1.-endFactor);

	    vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	    float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	    float roughness_tex_alt = dot(texture(texture_roughness_alt, base_uv), roughness_texture_channel);
	    ROUGHNESS = (roughness_tex * roughness * endFactor) + (roughness_tex * roughness * (1.-endFactor));

	    // Normal Map: Enabled
	    NORMAL_MAP = (texture(texture_normal, base_uv).rgb * endFactor) + (texture(texture_normal_alt, base_uv).rgb * (1.-endFactor));
	    NORMAL_MAP_DEPTH = normal_scale;
	}
	else {
		ALBEDO = vec3(base_uv, 1.0);
	}
}