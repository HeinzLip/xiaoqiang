shader_type canvas_item;
uniform float ratio:hint_range(0.0, 0.5);
void fragment() {
	vec4 attaced_color = vec4(1, 0, 0, texture(TEXTURE, UV).a);
	COLOR = mix(texture(TEXTURE, UV), attaced_color, ratio);
	//COLOR = texture(TEXTURE, UV);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
