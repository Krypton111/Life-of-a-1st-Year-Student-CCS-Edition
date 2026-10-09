extends Control

const OPENING_SCENE := "res://scenes/main_level_scenes/cutscenes/opening_cutscene.tscn"

const PANEL_COLOR := Color(0.10, 0.075, 0.06, 0.97)
const GOLD := Color(0.91, 0.78, 0.55)
const TEXT_COLOR := Color(0.96, 0.89, 0.77)

var pause_menu: CanvasLayer
var quit_dialog: PanelContainer
var quit_button: Button
var cancel_quit_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	build_menu()
	pause_menu = get_node("PauseMenu") as CanvasLayer
	if pause_menu != null:
		pause_menu.set("main_menu_mode", true)


func build_menu() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.055, 0.045, 0.04, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var left_accent := ColorRect.new()
	left_accent.position = Vector2(0, 0)
	left_accent.size = Vector2(12, 1080)
	left_accent.color = Color(0.70, 0.48, 0.27, 1.0)
	left_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(left_accent)

	var right_accent := ColorRect.new()
	right_accent.anchor_left = 1.0
	right_accent.anchor_right = 1.0
	right_accent.offset_left = -12
	right_accent.offset_right = 0
	right_accent.anchor_bottom = 1.0
	right_accent.color = Color(0.70, 0.48, 0.27, 1.0)
	right_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(right_accent)

	var content := VBoxContainer.new()
	content.name = "MenuContent"
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.position = Vector2(-190, -355)
	content.size = Vector2(380, 710)
	content.add_theme_constant_override("separation", 13)
	add_child(content)

	var title := Label.new()
	title.text = "LIFE OF A\n1ST YEAR STUDENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_font_size_override("font_size", 37)
	title.add_theme_color_override("font_color", GOLD)
	title.custom_minimum_size = Vector2(0, 112)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "CCS EDITION"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", TEXT_COLOR)
	content.add_child(subtitle)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(110, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.color = Color(0.70, 0.48, 0.27, 1.0)
	content.add_child(divider)

	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	content.add_child(gap)

	var start_button := make_menu_button("START GAME")
	start_button.pressed.connect(start_game)
	content.add_child(start_button)

	var load_button := make_menu_button("LOAD GAME")
	load_button.pressed.connect(open_load_menu)
	content.add_child(load_button)

	var settings_button := make_menu_button("SETTINGS")
	settings_button.pressed.connect(open_settings_menu)
	content.add_child(settings_button)

	var credits_button := make_menu_button("CREDITS")
	credits_button.pressed.connect(credits_dud)
	content.add_child(credits_button)

	quit_button = make_menu_button("QUIT")
	quit_button.pressed.connect(show_quit_confirmation)
	content.add_child(quit_button)

	var footer := Label.new()
	footer.text = "Advance Game Design (50054)"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.54, 0.46, 0.38))
	content.add_child(footer)

	build_quit_dialog()


func make_menu_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(360, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.72))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.15, 0.105, 0.075, 0.96)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.27, 0.18, 0.12, 1.0)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.09, 0.065, 0.05, 1.0)))
	return button


func make_button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.54, 0.38, 0.24, 1.0)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


func start_game() -> void:
	if is_instance_valid(FadeManager):
		await FadeManager.change_scene_with_fade(OPENING_SCENE)
	else:
		get_tree().change_scene_to_file(OPENING_SCENE)


func open_load_menu() -> void:
	if pause_menu != null and pause_menu.has_method("open_main_menu_load_slots"):
		pause_menu.call("open_main_menu_load_slots")


func open_settings_menu() -> void:
	if pause_menu != null and pause_menu.has_method("open_main_menu_settings"):
		pause_menu.call("open_main_menu_settings")


func credits_dud() -> void:
	pass


func build_quit_dialog() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "QuitDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.visible = false
	add_child(dimmer)

	quit_dialog = PanelContainer.new()
	quit_dialog.name = "QuitConfirmation"
	quit_dialog.set_anchors_preset(Control.PRESET_CENTER)
	quit_dialog.position = Vector2(-230, -135)
	quit_dialog.size = Vector2(460, 270)
	quit_dialog.add_theme_stylebox_override("panel", make_quit_panel_style())
	dimmer.add_child(quit_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	quit_dialog.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var title := Label.new()
	title.text = "QUIT GAME?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	box.add_child(title)

	var message := Label.new()
	message.text = "Are you sure you want to quit the game?"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", TEXT_COLOR)
	box.add_child(message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	var yes_button := make_menu_button("YES, QUIT")
	yes_button.custom_minimum_size = Vector2(170, 46)
	yes_button.pressed.connect(confirm_quit)
	buttons.add_child(yes_button)

	cancel_quit_button = make_menu_button("CANCEL")
	cancel_quit_button.custom_minimum_size = Vector2(170, 46)
	cancel_quit_button.pressed.connect(cancel_quit)
	buttons.add_child(cancel_quit_button)

	quit_dialog.set_meta("dimmer", dimmer)


func make_quit_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color(0.70, 0.48, 0.27, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func show_quit_confirmation() -> void:
	var dimmer := quit_dialog.get_meta("dimmer") as ColorRect
	dimmer.visible = true
	cancel_quit_button.grab_focus()


func cancel_quit() -> void:
	var dimmer := quit_dialog.get_meta("dimmer") as ColorRect
	dimmer.visible = false
	quit_button.grab_focus()


func confirm_quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		var dimmer := quit_dialog.get_meta("dimmer") as ColorRect
		if dimmer.visible:
			cancel_quit()
			get_viewport().set_input_as_handled()
