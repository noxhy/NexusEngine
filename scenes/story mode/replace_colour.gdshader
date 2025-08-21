shader_type canvas_item;

// i think this could be better but it works for now
uniform vec3 u_replace : source_color;

uniform float u_tolerance_min : hint_range(0.0, 1.0, 0.01);

uniform float u_tolerance_max : hint_range(0.0, 1.0, 0.01);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	float b = max(max(COLOR.r,COLOR.g),COLOR.b);
	
	COLOR.rgb = mix(COLOR.rgb,u_replace,smoothstep(u_tolerance_min,u_tolerance_max,b));
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
