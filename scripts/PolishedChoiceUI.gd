extends CanvasLayer

class_name PolishedChoiceUI

# COZY CHOICE UI
# Drop this in as the replacement for the existing PolishedChoiceUI.gd.
# The public show_choice() function stays the same so existing callers do not need to change.


const PANEL_SIZE := Vector2(760.0, 430.0)
const PANEL_TOP := 252.0
const BUTTON_SIZE := Vector2(300.0, 74.0)

# Cozy brown palette.
const COCOA := Color("#3A281E")
const ESPRESSO := Color("#251913")
const WALNUT := Color("#5B3E2C")
const CARAMEL := Color("#B9824A")
const HONEY := Color("#D8A15D")
const CREAM := Color("#F6E7D2")
const MUTED_CREAM := Color("#D9C1A7")
const SOFT_BEIGE := Color("#E8D2B6")
const SAGE := Color("#A6B38B")

var root: Control
var overlay: ColorRect
var panel: Panel
var accent_bar: ColorRect
var eyebrow: Label
var title_label: Label
var divider: ColorRect
var description_label: Label
var yes_button: Button
var no_button: Button
var footer: Label
var timer_bar: ProgressBar
var timer_fill_style: StyleBoxFlat
var timer_background_style: StyleBoxFlat
var panel_style: StyleBoxFlat

var result := 0
var selected_button: Button = null


func _ready() -> void:

	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_choice(
	title: String,
	description: String,
	left_text: String,
	right_text: String,
	left_result: int = 1,
	right_result: int = 2,
	accent: Color = HONEY
) -> int:

	result = 0
	selected_button = null

	build_ui(title, description, left_text, right_text, left_result, right_result, accent)
	timer_bar.visible = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await get_tree().process_frame

	yes_button.grab_focus()
	selected_button = yes_button

	await play_enter_animation()

	while result == 0 and is_instance_valid(self):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await get_tree().process_frame

	if is_instance_valid(self):
		await play_exit_animation()

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	queue_free()

	return result



func show_timed_choice(
	title: String,
	description: String,
	left_text: String,
	right_text: String,
	timeout_seconds: float = 5.0,
	left_result: int = 1,
	right_result: int = 2,
	accent: Color = HONEY
) -> int:

	result = 0
	selected_button = null

	build_ui(
		title,
		description,
		left_text,
		right_text,
		left_result,
		right_result,
		accent
	)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await get_tree().process_frame

	yes_button.grab_focus()
	selected_button = yes_button

	await play_enter_animation()

	var remaining: float = timeout_seconds

	while result == 0 and is_instance_valid(self) and remaining > 0.0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await get_tree().process_frame
		remaining -= get_process_delta_time()

		if is_instance_valid(timer_bar):
			var ratio: float = 0.0
			if timeout_seconds > 0.0:
				ratio = remaining / timeout_seconds
			if ratio < 0.0:
				ratio = 0.0
			elif ratio > 1.0:
				ratio = 1.0
			timer_bar.value = ratio * 100.0

			if ratio > 0.5:
				var green: Color = Color("#68B56B")
				var orange: Color = Color("#E49A45")
				var blend_amount: float = (1.0 - ratio) / 0.5
				timer_fill_style.bg_color = green.lerp(orange, blend_amount)
			else:
				var orange: Color = Color("#E49A45")
				var red: Color = Color("#D94A45")
				var blend_amount: float = (0.5 - ratio) / 0.5
				timer_fill_style.bg_color = orange.lerp(red, blend_amount)

	if result == 0:
		result = right_result

	if is_instance_valid(self):
		await play_exit_animation()

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	queue_free()

	return result


func build_ui(
	title: String,
	description: String,
	left_text: String,
	right_text: String,
	left_result: int,
	right_result: int,
	accent: Color
) -> void:

	root = Control.new()
	root.name = "CozyChoiceRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	overlay = ColorRect.new()
	overlay.name = "WarmOverlay"
	overlay.color = Color(0.08, 0.05, 0.035, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	panel = Panel.new()
	panel.name = "ChoicePanel"
	panel.size = PANEL_SIZE
	panel.position = (
		get_viewport().get_visible_rect().size - PANEL_SIZE
	) / 2.0
	panel.position.y += 16.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(panel)

	panel_style = make_panel_style(
		COCOA,
		Color(accent.r, accent.g, accent.b, 0.95),
		3,
		22,
		22
	)
	panel.add_theme_stylebox_override("panel", panel_style)

	accent_bar = ColorRect.new()
	accent_bar.name = "AccentBar"
	accent_bar.position = Vector2(0.0, 0.0)
	accent_bar.size = Vector2(PANEL_SIZE.x, 8.0)
	accent_bar.color = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent_bar)

	# Warm decorative corner blocks make the panel feel less like a default Godot window.
	var corner_left := ColorRect.new()
	corner_left.position = Vector2(18.0, 28.0)
	corner_left.size = Vector2(6.0, 40.0)
	corner_left.color = Color(accent.r, accent.g, accent.b, 0.35)
	corner_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(corner_left)

	var corner_right := ColorRect.new()
	corner_right.position = Vector2(PANEL_SIZE.x - 24.0, 28.0)
	corner_right.size = Vector2(6.0, 40.0)
	corner_right.color = Color(accent.r, accent.g, accent.b, 0.35)
	corner_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(corner_right)

	eyebrow = Label.new()
	eyebrow.position = Vector2(42.0, 28.0)
	eyebrow.size = Vector2(PANEL_SIZE.x - 84.0, 24.0)
	eyebrow.text = "A MOMENT TO DECIDE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", accent)
	panel.add_child(eyebrow)

	title_label = Label.new()
	title_label.position = Vector2(42.0, 66.0)
	title_label.size = Vector2(PANEL_SIZE.x - 84.0, 58.0)
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", CREAM)
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.42))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(title_label)

	divider = ColorRect.new()
	divider.position = Vector2(78.0, 130.0)
	divider.size = Vector2(PANEL_SIZE.x - 156.0, 2.0)
	divider.color = Color(accent.r, accent.g, accent.b, 0.30)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	description_label = Label.new()
	description_label.position = Vector2(70.0, 150.0)
	description_label.size = Vector2(PANEL_SIZE.x - 140.0, 92.0)
	description_label.text = description
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.add_theme_font_size_override("font_size", 17)
	description_label.add_theme_color_override("font_color", MUTED_CREAM)
	panel.add_child(description_label)

	# Animated countdown bar used by timed choices.
	timer_bar = ProgressBar.new()
	timer_bar.name = "DecisionTimer"
	timer_bar.position = Vector2(70.0, 242.0)
	timer_bar.size = Vector2(PANEL_SIZE.x - 140.0, 12.0)
	timer_bar.min_value = 0.0
	timer_bar.max_value = 100.0
	timer_bar.value = 100.0
	timer_bar.show_percentage = false
	timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	timer_background_style = StyleBoxFlat.new()
	timer_background_style.bg_color = Color("#4A3528")
	timer_background_style.set_corner_radius_all(6)
	timer_background_style.border_color = Color(0.82, 0.70, 0.56, 0.20)
	timer_background_style.set_border_width_all(1)

	timer_fill_style = StyleBoxFlat.new()
	timer_fill_style.bg_color = Color("#68B56B")
	timer_fill_style.set_corner_radius_all(6)

	timer_bar.add_theme_stylebox_override("background", timer_background_style)
	timer_bar.add_theme_stylebox_override("fill", timer_fill_style)
	panel.add_child(timer_bar)

	yes_button = make_choice_button(
		left_text,
		Vector2(48.0, 270.0),
		left_result,
		accent,
		SAGE
	)

	no_button = make_choice_button(
		right_text,
		Vector2(PANEL_SIZE.x - 348.0, 270.0),
		right_result,
		accent,
		SOFT_BEIGE
	)

	footer = Label.new()
	footer.position = Vector2(42.0, 386.0)
	footer.size = Vector2(PANEL_SIZE.x - 84.0, 24.0)
	footer.text = "Use mouse or keyboard to choose"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.70, 0.58, 0.46, 1.0))
	panel.add_child(footer)


func make_choice_button(
	text_value: String,
	button_position: Vector2,
	button_result: int,
	accent: Color,
	base_tint: Color
) -> Button:

	var button := Button.new()
	button.position = button_position
	button.size = BUTTON_SIZE
	button.text = text_value
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)

	var normal := make_button_style(
		Color(
			base_tint.r * 0.78,
			base_tint.g * 0.78,
			base_tint.b * 0.78,
			1.0
		),
		Color(0.82, 0.70, 0.56, 0.24),
		1,
		14,
		6
	)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(
		min(normal.bg_color.r + 0.08, 1.0),
		min(normal.bg_color.g + 0.08, 1.0),
		min(normal.bg_color.b + 0.08, 1.0),
		1.0
	)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.92)
	hover.set_border_width_all(2)

	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(
		max(normal.bg_color.r - 0.05, 0.0),
		max(normal.bg_color.g - 0.05, 0.0),
		max(normal.bg_color.b - 0.05, 0.0),
		1.0
	)

	var focus := hover.duplicate() as StyleBoxFlat
	focus.shadow_color = Color(accent.r, accent.g, accent.b, 0.34)
	focus.shadow_size = 10

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)

	button.pressed.connect(func():
		result = button_result
	)

	button.focus_entered.connect(func():
		selected_button = button
	)

	panel.add_child(button)

	return button


func make_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_size: int
) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 7.0)
	style.anti_aliasing = true

	return style


func make_button_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int,
	shadow_size: int
) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 3.0)
	style.anti_aliasing = true

	return style


func play_enter_animation() -> void:

	if panel == null:
		return

	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		overlay,
		"modulate:a",
		1.0,
		0.18
	)

	tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.22
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.24
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished


func play_exit_animation() -> void:

	if panel == null or not is_instance_valid(panel):
		return

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		overlay,
		"modulate:a",
		0.0,
		0.16
	)

	tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.16
	)

	tween.tween_property(
		panel,
		"scale",
		Vector2(0.98, 0.98),
		0.16
	)

	await tween.finished
