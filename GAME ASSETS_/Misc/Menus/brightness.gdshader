shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec3 brightened = screen_color.rgb * brightness;
	COLOR = vec4(brightened, screen_color.a);
}