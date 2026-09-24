extends CanvasLayer

const PANEL_SIZE := Vector2(360.0, 330.0)
const BUTTON_SIZE := Vector2(280.0, 46.0)

var overlay: ColorRect
var pause_panel: PanelContainer
var confirm_panel: PanelContainer
var resume_button: Button
var settings_button: Button
var credits_button: Button
var main_menu_button: Button
var quit_yes_button: Button
var quit_no_button: Button

var is_paused := false
var showing_quit_confirmation := false
var cursor_mode_before_pause: Input.MouseMode = Input.MOUSE_MODE_HIDDEN
var paused_node_process_modes: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	build_ui()
	hide_menu()

func build_ui() -> void:
	overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.12, 0.075, 0.045, 0.70)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-180, -165)
	pause_panel.size = PANEL_SIZE
	pause_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	pause_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	title.custom_minimum_size.y = 42
	box.add_child(title)

	resume_button = make_button("Resume")
	resume_button.pressed.connect(resume_game)
	box.add_child(resume_button)

	settings_button = make_button("Settings")
	settings_button.pressed.connect(settings_dud)
	box.add_child(settings_button)

	credits_button = make_button("Credits")
	credits_button.pressed.connect(credits_dud)
	box.add_child(credits_button)

	main_menu_button = make_button("Back to Main Menu")
	main_menu_button.pressed.connect(show_quit_confirmation)
	box.add_child(main_menu_button)

	build_confirmation_ui()

func build_confirmation_ui() -> void:
	confirm_panel = PanelContainer.new()
	confirm_panel.name = "QuitConfirmation"
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.position = Vector2(-210, -125)
	confirm_panel.size = Vector2(420, 250)
	confirm_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	confirm_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Quit Game?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72))
	box.add_child(title)

	var message := Label.new()
	message.text = "Are you sure you want to quit?\nYour current progress may be lost."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 16)
	message.custom_minimum_size.y = 55
	box.add_child(message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	quit_yes_button = make_button("Yes")
	quit_yes_button.custom_minimum_size = Vector2(130, 44)
	quit_yes_button.pressed.connect(confirm_quit)
	buttons.add_child(quit_yes_button)

	quit_no_button = make_button("No")
	quit_no_button.custom_minimum_size = Vector2(130, 44)
	quit_no_button.pressed.connect(cancel_quit)
	buttons.add_child(quit_no_button)

func make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.91, 0.82, 0.67))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.67))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.31, 0.20, 0.13, 0.96)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.43, 0.29, 0.19, 0.98)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.23, 0.14, 0.09, 1.0)))
	return button

func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.16, 0.11, 0.98)
	style.border_color = Color(0.67, 0.50, 0.31, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.08, 0.045, 0.02, 0.70)
	style.shadow_size = 14
	return style

func make_button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.52, 0.37, 0.23, 1.0)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		if showing_quit_confirmation:
			cancel_quit()
		elif is_paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func pause_game() -> void:
	if is_paused:
		return
	cursor_mode_before_pause = Input.mouse_mode
	is_paused = true
	showing_quit_confirmation = false
	overlay.visible = true
	pause_panel.visible = true
	confirm_panel.visible = false
	get_tree().paused = true
	freeze_all_non_pause_nodes()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()

func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	showing_quit_confirmation = false
	restore_all_non_pause_nodes()
	get_tree().paused = false
	# Restore the cursor state that existed before the pause menu opened.
	Input.mouse_mode = cursor_mode_before_pause
	hide_menu()

func freeze_all_non_pause_nodes() -> void:
	paused_node_process_modes.clear()
	var root := get_tree().root
	if root == null:
		return

	# SceneTree.pause stops normal PAUSABLE nodes, but nodes explicitly configured
	# as ALWAYS can still process. Disable every non-pause node as an extra hard
	# freeze so movement, animations, scripted encounters, and UI logic cannot
	# continue while the pause menu is open.
	freeze_node_tree(root)


func freeze_node_tree(node: Node) -> void:
	if node != self and not is_ancestor_of(node):
		paused_node_process_modes.append([node, node.process_mode])
		node.process_mode = Node.PROCESS_MODE_DISABLED

	for child in node.get_children():
		freeze_node_tree(child)


func restore_all_non_pause_nodes() -> void:
	for entry in paused_node_process_modes:
		if entry.size() < 2:
			continue
		var node := entry[0] as Node
		if is_instance_valid(node):
			node.process_mode = entry[1]
	paused_node_process_modes.clear()

func show_quit_confirmation() -> void:
	showing_quit_confirmation = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_panel.visible = false
	confirm_panel.visible = true
	quit_no_button.grab_focus()

func cancel_quit() -> void:
	showing_quit_confirmation = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	confirm_panel.visible = false
	pause_panel.visible = true
	main_menu_button.grab_focus()

func confirm_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

func settings_dud() -> void:
	pass

func credits_dud() -> void:
	pass

func hide_menu() -> void:
	overlay.visible = false
	pause_panel.visible = false
	confirm_panel.visible = false
