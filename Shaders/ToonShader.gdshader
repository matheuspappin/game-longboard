// Shader estilo Ghibli/Gouache — sem outline, 2 steps de sombra com cor quente/fria
// Baseado na análise dos vídeos de referência (Instagram reels DXg7mnUiWbp e DdXoI8ZJlNe)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform bool use_texture = false;

// Sombra em 2 steps (estilo anime Ghibli)
uniform float shadow_threshold_1 : hint_range(0.0, 1.0) = 0.5;   // step 1 (sombra leve)
uniform float shadow_threshold_2 : hint_range(0.0, 1.0) = 0.15;  // step 2 (sombra escura)
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.04;

// Cores das sombras — tons frios/azulados como nos vídeos
uniform vec4 shadow_color_1 : source_color = vec4(0.55, 0.62, 0.82, 1.0);  // sombra leve (azulado)
uniform vec4 shadow_color_2 : source_color = vec4(0.28, 0.32, 0.55, 1.0);  // sombra escura (violeta)

// Rim light (contorno luminoso nas bordas — visível nos vídeos)
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 rim_color : source_color = vec4(0.85, 0.90, 1.0, 1.0);

void fragment() {
	vec4 base;
	if (use_texture) {
		base = texture(texture_albedo, UV) * albedo;
	} else {
		base = albedo;
	}
	ALBEDO = base.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.0;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	
	// Step 1: sombra leve
	float s1 = smoothstep(shadow_threshold_1 - shadow_softness, shadow_threshold_1 + shadow_softness, NdotL);
	// Step 2: sombra escura
	float s2 = smoothstep(shadow_threshold_2 - shadow_softness, shadow_threshold_2 + shadow_softness, NdotL);
	
	// Combina os dois steps
	vec3 lit = ALBEDO;
	lit = mix(ALBEDO * shadow_color_2.rgb, lit, s2);
	lit = mix(ALBEDO * shadow_color_1.rgb, lit, s1);
	
	// Rim light (contorno brilhante nas bordas — efeito Ghibli)
	float rim = 1.0 - dot(VIEW, NORMAL);
	rim = pow(rim, 3.0) * rim_strength;
	lit += rim_color.rgb * rim * ATTENUATION;
	
	DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR;
}
