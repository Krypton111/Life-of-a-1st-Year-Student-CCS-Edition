extends CanvasLayer

const PANEL_SIZE := Vector2(360.0, 430.0)
const BUTTON_SIZE := Vector2(280.0, 46.0)
const SLOT_PANEL_SIZE := Vector2(620.0, 500.0)
const SLOT_BUTTON_SIZE := Vector2(270.0, 64.0)
const ACHIEVEMENT_PANEL_SIZE := Vector2(760.0, 620.0)
const SETTINGS_PANEL_SIZE := Vector2(560.0, 620.0)
const CONTROLS_PANEL_SIZE := Vector2(560.0, 520.0)
const REBIND_ACTIONS := ["move_up", "move_left", "move_down", "move_right", "interact", "toggle_quest_tracker"]
const REBIND_LABELS := {"move_up": "Move Up", "move_left": "Move Left", "move_down": "Move Down", "move_right": "Move Right", "interact": "Interact", "toggle_quest_tracker": "Toggle Quest Tracker"}

const SETTINGS_CONFIG_PATH := "user://settings.cfg"
const BRIGHTNESS_SHADER_PATH := "res://GAME ASSETS_/Misc/Menus/brightness.gdshader"

var overlay: ColorRect
var pause_panel: PanelContainer
var confirm_panel: PanelContainer
var slot_panel: PanelContainer
var achievement_panel: PanelContainer
var achievement_scroll: ScrollContainer
var achievement_list: VBoxContainer
var achievement_close_button: Button
var settings_panel: PanelContainer
var credits_screen: Control
var credits_close_button: Button
var showing_credits_menu: bool = false
var controls_panel: PanelContainer
var controls_button: Button
var controls_close_button: Button
var rebind_buttons: Dictionary = {}
var awaiting_rebind_action: String = ""

var resume_button: Button
var save_game_button: Button
var load_game_button: Button
var achievements_button: Button
var settings_button: Button
var credits_button: Button
var main_menu_button: Button

var quit_yes_button: Button
var quit_no_button: Button

var slot_title: Label
var slot_grid: GridContainer
var slot_cancel_button: Button
var slot_mode: String = ""

var volume_slider: HSlider
var brightness_slider: HSlider
var volume_value_label: Label
var brightness_value_label: Label
var quest_pointer_toggle: CheckButton
var all_achievements_toggle: CheckButton
var settings_close_button: Button
var brightness_overlay: ColorRect
var brightness_shader_material: ShaderMaterial = null

var master_bus_index: int = -1

var main_menu_mode: bool = false
var is_paused := false
var showing_quit_confirmation := false
var showing_slot_menu := false
var showing_achievement_menu := false
var showing_settings_menu := false

var cursor_mode_before_pause: Input.MouseMode = Input.MOUSE_MODE_HIDDEN
var paused_node_process_modes: Array = []
var paused_audio_players: Array[Node] = []
var paused_audio_player_states: Array[bool] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	master_bus_index = AudioServer.get_bus_index("Master")

	build_brightness_overlay()
	build_ui()
	load_settings()

	hide_menu()


# ============================================================
# BRIGHTNESS OVERLAY (SHADER-BASED)
# ============================================================
# A full-screen ColorRect using the brightness shader. The shader reads
# SCREEN_TEXTURE and multiplies it by a brightness factor, so values below
# 1.0 darken the screen and values above 1.0 brighten it. This sits on a
# CanvasLayer above everything else so it affects the whole viewport.
func build_brightness_overlay() -> void:
	var shader: Shader = null

	if ResourceLoader.exists(BRIGHTNESS_SHADER_PATH):
		shader = load(BRIGHTNESS_SHADER_PATH)
	else:
		push_warning(
			"PauseMenu: brightness shader not found at "
			+ BRIGHTNESS_SHADER_PATH
		)

	brightness_overlay = ColorRect.new()
	brightness_overlay.name = "BrightnessOverlay"
	brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brightness_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if shader != null:
		brightness_shader_material = ShaderMaterial.new()
		brightness_shader_material.shader = shader
		brightness_shader_material.set_shader_parameter("brightness", 1.0)
		brightness_overlay.material = brightness_shader_material

	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "BrightnessOverlayLayer"
	overlay_layer.layer = 1000
	add_child(overlay_layer)
	overlay_layer.add_child(brightness_overlay)


# ============================================================
# UI BUILD
# ============================================================

func build_ui() -> void:
	overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.16, 0.095, 0.055, 0.76)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-180, -215)
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
	title.add_theme_color_override("font_color", Color("#FFE1A8"))
	title.custom_minimum_size.y = 42
	box.add_child(title)

	resume_button = make_button("Resume")
	resume_button.pressed.connect(resume_game)
	box.add_child(resume_button)

	save_game_button = make_button("Save Game")
	save_game_button.pressed.connect(open_save_slots)
	box.add_child(save_game_button)

	load_game_button = make_button("Load Game")
	load_game_button.pressed.connect(open_load_slots)
	box.add_child(load_game_button)

	achievements_button = make_button("Achievements")
	achievements_button.pressed.connect(achievements_dud)
	box.add_child(achievements_button)

	settings_button = make_button("Settings")
	settings_button.pressed.connect(open_settings)
	box.add_child(settings_button)

	credits_button = make_button("Credits")
	credits_button.pressed.connect(credits_dud)
	box.add_child(credits_button)

	main_menu_button = make_button("Back to Main Menu")
	main_menu_button.pressed.connect(show_quit_confirmation)
	box.add_child(main_menu_button)

	build_confirmation_ui()
	build_slot_ui()
	build_achievement_ui()
	build_settings_ui()
	build_controls_ui()
	build_credits_ui()


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
	title.text = "Return to Main Menu?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#F4C982"))
	box.add_child(title)

	var message := Label.new()
	message.text = "Return to the main menu?\nUnsaved progress may be lost."
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


func build_slot_ui() -> void:
	slot_panel = PanelContainer.new()
	slot_panel.name = "SaveSlotPanel"
	slot_panel.set_anchors_preset(Control.PRESET_CENTER)
	slot_panel.position = Vector2(-310, -250)
	slot_panel.size = SLOT_PANEL_SIZE
	slot_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(slot_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	slot_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	slot_title = Label.new()
	slot_title.text = "SELECT SAVE SLOT"
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title.add_theme_font_size_override("font_size", 26)
	slot_title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	box.add_child(slot_title)

	var hint := Label.new()
	hint.text = "Choose one of 10 independent save files."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("#D8BEA1"))
	box.add_child(hint)

	slot_grid = GridContainer.new()
	slot_grid.columns = 2
	slot_grid.add_theme_constant_override("h_separation", 12)
	slot_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(slot_grid)

	for slot in range(1, 11):
		var button := make_button("Slot %02d" % slot)
		button.custom_minimum_size = SLOT_BUTTON_SIZE
		button.name = "Slot%02dButton" % slot
		button.pressed.connect(select_slot.bind(slot))
		slot_grid.add_child(button)

	slot_cancel_button = make_button("Cancel")
	slot_cancel_button.custom_minimum_size = Vector2(280, 42)
	slot_cancel_button.pressed.connect(close_slot_menu)
	box.add_child(slot_cancel_button)


func build_achievement_ui() -> void:
	achievement_panel = PanelContainer.new()
	achievement_panel.name = "AchievementPanel"
	achievement_panel.set_anchors_preset(Control.PRESET_CENTER)
	achievement_panel.position = Vector2(-380, -310)
	achievement_panel.size = ACHIEVEMENT_PANEL_SIZE
	achievement_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(achievement_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	achievement_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.name = "AchievementTitle"
	title.text = "ACHIEVEMENTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "AchievementSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.74, 0.64))
	box.add_child(subtitle)

	achievement_scroll = ScrollContainer.new()
	achievement_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	achievement_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(achievement_scroll)

	achievement_list = VBoxContainer.new()
	achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievement_list.add_theme_constant_override("separation", 8)
	achievement_scroll.add_child(achievement_list)

	achievement_close_button = make_button("Close")
	achievement_close_button.custom_minimum_size = Vector2(240, 44)
	achievement_close_button.pressed.connect(close_achievements)
	box.add_child(achievement_close_button)

	achievement_panel.visible = false


func build_settings_ui() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-280, -310)
	settings_panel.size = SETTINGS_PANEL_SIZE
	settings_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	settings_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	title.custom_minimum_size.y = 42
	box.add_child(title)

	# ---------- VOLUME ----------
	var volume_row := VBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 6)
	box.add_child(volume_row)

	var volume_header := HBoxContainer.new()
	volume_row.add_child(volume_header)

	var volume_label := Label.new()
	volume_label.text = "Volume"
	volume_label.add_theme_font_size_override("font_size", 18)
	volume_label.add_theme_color_override("font_color", Color("#F6E7D2"))
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_header.add_child(volume_label)

	volume_value_label = Label.new()
	volume_value_label.text = "100%"
	volume_value_label.add_theme_font_size_override("font_size", 16)
	volume_value_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_header.add_child(volume_value_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = 100.0
	volume_slider.custom_minimum_size = Vector2(0.0, 28.0)
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.value_changed.connect(on_volume_changed)
	volume_row.add_child(volume_slider)

	# ---------- BRIGHTNESS ----------
	var brightness_row := VBoxContainer.new()
	brightness_row.add_theme_constant_override("separation", 6)
	box.add_child(brightness_row)

	var brightness_header := HBoxContainer.new()
	brightness_row.add_child(brightness_header)

	var brightness_label := Label.new()
	brightness_label.text = "Brightness"
	brightness_label.add_theme_font_size_override("font_size", 18)
	brightness_label.add_theme_color_override("font_color", Color(0.91, 0.82, 0.67))
	brightness_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brightness_header.add_child(brightness_label)

	brightness_value_label = Label.new()
	brightness_value_label.text = "100%"
	brightness_value_label.add_theme_font_size_override("font_size", 16)
	brightness_value_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	brightness_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	brightness_header.add_child(brightness_value_label)

	brightness_slider = HSlider.new()
	brightness_slider.min_value = 30.0
	brightness_slider.max_value = 150.0
	brightness_slider.step = 1.0
	brightness_slider.value = 100.0
	brightness_slider.custom_minimum_size = Vector2(0.0, 28.0)
	brightness_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brightness_slider.value_changed.connect(on_brightness_changed)
	brightness_row.add_child(brightness_slider)

	# ---------- QUEST POINTER ----------
	var quest_pointer_row := HBoxContainer.new()
	quest_pointer_row.add_theme_constant_override("separation", 12)
	quest_pointer_row.custom_minimum_size = Vector2(0.0, 42.0)
	box.add_child(quest_pointer_row)

	var quest_pointer_label := Label.new()
	quest_pointer_label.text = "Quest Pointer"
	quest_pointer_label.add_theme_font_size_override("font_size", 18)
	quest_pointer_label.add_theme_color_override(
		"font_color",
		Color(0.91, 0.82, 0.67)
	)
	quest_pointer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_pointer_row.add_child(quest_pointer_label)

	quest_pointer_toggle = CheckButton.new()
	quest_pointer_toggle.text = "ON"
	quest_pointer_toggle.button_pressed = true
	quest_pointer_toggle.focus_mode = Control.FOCUS_ALL
	quest_pointer_toggle.add_theme_font_size_override("font_size", 16)
	quest_pointer_toggle.add_theme_color_override(
		"font_color",
		Color(0.96, 0.87, 0.68)
	)
	quest_pointer_toggle.add_theme_color_override(
		"font_hover_color",
		Color("#FFE1A8")
	)
	quest_pointer_toggle.toggled.connect(on_quest_pointer_toggled)
	quest_pointer_row.add_child(quest_pointer_toggle)

	# ---------- ALL ACHIEVEMENTS (TESTING) ----------
	var all_achievements_row := HBoxContainer.new()
	all_achievements_row.add_theme_constant_override("separation", 12)
	all_achievements_row.custom_minimum_size = Vector2(0.0, 42.0)
	box.add_child(all_achievements_row)

	var all_achievements_label := Label.new()
	all_achievements_label.text = "Enable All Achievements"
	all_achievements_label.add_theme_font_size_override("font_size", 16)
	all_achievements_label.add_theme_color_override("font_color", Color(0.91, 0.82, 0.67))
	all_achievements_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_achievements_row.add_child(all_achievements_label)

	all_achievements_toggle = CheckButton.new()
	all_achievements_toggle.text = "ON" if is_instance_valid(AchievementManager) and AchievementManager.are_all_achievements_enabled() else "OFF"
	all_achievements_toggle.button_pressed = is_instance_valid(AchievementManager) and AchievementManager.are_all_achievements_enabled()
	all_achievements_toggle.focus_mode = Control.FOCUS_ALL
	all_achievements_toggle.add_theme_font_size_override("font_size", 16)
	all_achievements_toggle.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	all_achievements_toggle.add_theme_color_override("font_hover_color", Color("#FFE1A8"))
	all_achievements_toggle.toggled.connect(on_all_achievements_toggled)
	all_achievements_row.add_child(all_achievements_toggle)

	var all_achievements_hint := Label.new()
	all_achievements_hint.text = "Testing option. Turning it off restores your previous achievements."
	all_achievements_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	all_achievements_hint.add_theme_font_size_override("font_size", 12)
	all_achievements_hint.add_theme_color_override("font_color", Color("#D8BEA1"))
	box.add_child(all_achievements_hint)

	controls_button = make_button("Controls")
	controls_button.custom_minimum_size = Vector2(240, 44)
	controls_button.pressed.connect(open_controls)
	box.add_child(controls_button)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	box.add_child(spacer)

	settings_close_button = make_button("Close")
	settings_close_button.custom_minimum_size = Vector2(240, 44)
	settings_close_button.pressed.connect(close_settings)
	box.add_child(settings_close_button)

	settings_panel.visible = false


func build_controls_ui() -> void:
	controls_panel = PanelContainer.new()
	controls_panel.name = "ControlsPanel"
	controls_panel.set_anchors_preset(Control.PRESET_CENTER)
	controls_panel.position = Vector2(-280, -260)
	controls_panel.size = CONTROLS_PANEL_SIZE
	controls_panel.add_theme_stylebox_override("panel", make_panel_style())
	overlay.add_child(controls_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	controls_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "CUSTOMIZE CONTROLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	title.custom_minimum_size.y = 38
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Select a key, then press the key you want to assign."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("#F6E7D2"))
	box.add_child(hint)

	for action in REBIND_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size.y = 42
		box.add_child(row)

		var label := Label.new()
		label.text = REBIND_LABELS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#F6E7D2"))
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)

		var key_button := make_button(get_action_key_label(action))
		key_button.custom_minimum_size = Vector2(150, 38)
		key_button.pressed.connect(_begin_rebind.bind(action))
		row.add_child(key_button)
		rebind_buttons[action] = key_button

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	box.add_child(button_row)

	var reset_button := make_button("Reset Defaults")
	reset_button.custom_minimum_size = Vector2(180, 42)
	reset_button.pressed.connect(reset_controls)
	button_row.add_child(reset_button)

	controls_close_button = make_button("Back to Settings")
	controls_close_button.custom_minimum_size = Vector2(220, 42)
	controls_close_button.pressed.connect(close_controls)
	box.add_child(controls_close_button)
	controls_panel.visible = false


func get_action_key_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "Unassigned"


func refresh_control_key_labels() -> void:
	for action in REBIND_ACTIONS:
		if rebind_buttons.has(action) and is_instance_valid(rebind_buttons[action]):
			(rebind_buttons[action] as Button).text = get_action_key_label(action)


func _begin_rebind(action: String) -> void:
	awaiting_rebind_action = action
	for key in rebind_buttons:
		var button := rebind_buttons[key] as Button
		button.text = "Press a key..." if key == action else get_action_key_label(key)


func _input(event: InputEvent) -> void:
	if awaiting_rebind_action.is_empty() or not controls_panel.visible:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_ESCAPE:
			awaiting_rebind_action = ""
			refresh_control_key_labels()
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_BACKSPACE or key_event.keycode == KEY_DELETE:
			awaiting_rebind_action = ""
			refresh_control_key_labels()
			get_viewport().set_input_as_handled()
			return
		var physical_key := key_event.physical_keycode
		if physical_key == 0:
			physical_key = key_event.keycode
		if physical_key == 0:
			return
		var action := awaiting_rebind_action
		var new_event := InputEventKey.new()
		new_event.physical_keycode = physical_key
		new_event.keycode = key_event.keycode
		new_event.unicode = key_event.unicode
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, new_event)
		awaiting_rebind_action = ""
		refresh_control_key_labels()
		save_settings()
		get_viewport().set_input_as_handled()


func reset_controls() -> void:
	var defaults := {
		"move_up": KEY_W,
		"move_left": KEY_A,
		"move_down": KEY_S,
		"move_right": KEY_D,
		"interact": KEY_F,
		"toggle_quest_tracker": KEY_C
	}
	for action in REBIND_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = defaults[action]
		key_event.keycode = defaults[action]
		InputMap.action_add_event(action, key_event)
	awaiting_rebind_action = ""
	refresh_control_key_labels()
	save_settings()


func open_controls() -> void:
	showing_settings_menu = true
	awaiting_rebind_action = ""
	settings_panel.visible = false
	controls_panel.visible = true
	refresh_control_key_labels()
	controls_close_button.grab_focus()


func close_controls() -> void:
	awaiting_rebind_action = ""
	controls_panel.visible = false
	settings_panel.visible = true
	settings_close_button.grab_focus()


# ============================================================
# SETTINGS — VOLUME
# ============================================================

func on_volume_changed(value: float) -> void:
	if volume_value_label != null:
		volume_value_label.text = "%d%%" % int(round(value))

	if master_bus_index < 0:
		master_bus_index = AudioServer.get_bus_index("Master")

	if master_bus_index < 0:
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		AudioServer.set_bus_volume_db(
			master_bus_index,
			linear_to_db(value / 100.0)
		)

	save_settings()


# ============================================================
# SETTINGS — BRIGHTNESS (SHADER-BASED)
# ============================================================
# value 30..150 maps to shader brightness 0.30..1.50
# 100 = 1.0 = no change
# <100 = darker
# >100 = brighter
func on_brightness_changed(value: float) -> void:
	if brightness_value_label != null:
		brightness_value_label.text = "%d%%" % int(round(value))

	apply_brightness(value)
	save_settings()


func apply_brightness(value: float) -> void:
	if brightness_overlay == null:
		return

	var factor: float = value / 100.0

	if brightness_shader_material != null:
		brightness_shader_material.set_shader_parameter("brightness", factor)
		brightness_overlay.visible = true
	else:
		# Fallback: no shader loaded, so only darkening is possible via a
		# semi-transparent black overlay. Brightening above 100% won't work
		# in this path.
		var alpha: float = 0.0
		if value < 100.0:
			alpha = (100.0 - value) / 100.0 * 0.6
		brightness_overlay.color = Color(0.0, 0.0, 0.0, alpha)
		brightness_overlay.visible = alpha > 0.001


# ============================================================
# SETTINGS — PERSISTENCE
# ============================================================

# ============================================================
# SETTINGS — QUEST POINTER
# ============================================================

func on_quest_pointer_toggled(enabled: bool) -> void:
	if quest_pointer_toggle != null:
		quest_pointer_toggle.text = "ON" if enabled else "OFF"

	if is_instance_valid(GameManager):
		GameManager.set("quest_pointer_enabled", enabled)

	save_settings()


func on_all_achievements_toggled(enabled: bool) -> void:
	if is_instance_valid(AchievementManager):
		AchievementManager.set_all_achievements_enabled(enabled)

	if all_achievements_toggle != null:
		all_achievements_toggle.text = "ON" if enabled else "OFF"

	save_settings()
	refresh_achievement_list()


func update_quest_pointer_toggle() -> void:
	if quest_pointer_toggle == null:
		return

	var enabled: bool = true

	if is_instance_valid(GameManager):
		enabled = bool(
			GameManager.get("quest_pointer_enabled")
		)

	quest_pointer_toggle.set_pressed_no_signal(enabled)
	quest_pointer_toggle.text = "ON" if enabled else "OFF"


# ============================================================
# SETTINGS — PERSISTENCE
# ============================================================

func save_settings() -> void:
	var config := ConfigFile.new()

	if volume_slider != null:
		config.set_value("audio", "volume", volume_slider.value)

	if brightness_slider != null:
		config.set_value("video", "brightness", brightness_slider.value)

	if quest_pointer_toggle != null:
		config.set_value(
			"gameplay",
			"quest_pointer_enabled",
			quest_pointer_toggle.button_pressed
		)

	if all_achievements_toggle != null:
		config.set_value(
			"gameplay",
			"all_achievements_enabled",
			all_achievements_toggle.button_pressed
		)
		config.set_value(
			"gameplay",
			"achievement_snapshot",
			AchievementManager.achievements_before_override.duplicate(true)
			if is_instance_valid(AchievementManager)
			else {}
		)

	for action in REBIND_ACTIONS:
		var key_code := 0
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var key_event := event as InputEventKey
				key_code = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
				break
		config.set_value("controls", action, key_code)

	config.save(SETTINGS_CONFIG_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(SETTINGS_CONFIG_PATH)

	var volume_value: float = 100.0
	var brightness_value: float = 100.0
	var quest_pointer_enabled: bool = true
	var all_achievements_enabled: bool = false
	var achievement_snapshot: Dictionary = {}
	var has_achievement_snapshot: bool = false
	var saved_controls: Dictionary = {}

	if error == OK:
		volume_value = float(
			config.get_value("audio", "volume", 100.0)
		)
		brightness_value = float(
			config.get_value("video", "brightness", 100.0)
		)
		quest_pointer_enabled = bool(
			config.get_value(
				"gameplay",
				"quest_pointer_enabled",
				true
			)
		)
		all_achievements_enabled = bool(
			config.get_value("gameplay", "all_achievements_enabled", false)
		)
		has_achievement_snapshot = config.has_section_key("gameplay", "achievement_snapshot")
		var stored_snapshot: Variant = config.get_value("gameplay", "achievement_snapshot", {})
		if stored_snapshot is Dictionary:
			achievement_snapshot = stored_snapshot.duplicate(true)
		for action in REBIND_ACTIONS:
			saved_controls[action] = int(config.get_value("controls", action, 0))

	if not InputMap.has_action("toggle_quest_tracker"):
		InputMap.add_action("toggle_quest_tracker")
	if InputMap.action_get_events("toggle_quest_tracker").is_empty():
		var default_tracker_key := InputEventKey.new()
		default_tracker_key.physical_keycode = KEY_C
		default_tracker_key.keycode = KEY_C
		InputMap.action_add_event("toggle_quest_tracker", default_tracker_key)
	for action in REBIND_ACTIONS:
		var saved_key := int(saved_controls.get(action, 0))
		if saved_key != 0:
			if not InputMap.has_action(action):
				InputMap.add_action(action)
			InputMap.action_erase_events(action)
			var key_event := InputEventKey.new()
			key_event.physical_keycode = saved_key
			key_event.keycode = saved_key
			InputMap.action_add_event(action, key_event)

	if is_instance_valid(GameManager):
		GameManager.set(
			"quest_pointer_enabled",
			quest_pointer_enabled
		)

	if is_instance_valid(AchievementManager):
		AchievementManager.set_all_achievements_enabled(
			all_achievements_enabled,
			achievement_snapshot,
			has_achievement_snapshot
		)

	if volume_slider != null:
		volume_slider.set_value_no_signal(volume_value)
		on_volume_changed(volume_value)

	if brightness_slider != null:
		brightness_slider.set_value_no_signal(brightness_value)
		on_brightness_changed(brightness_value)

	if quest_pointer_toggle != null:
		quest_pointer_toggle.set_pressed_no_signal(
			quest_pointer_enabled
		)
		quest_pointer_toggle.text = (
			"ON" if quest_pointer_enabled else "OFF"
		)

	if all_achievements_toggle != null:
		all_achievements_toggle.set_pressed_no_signal(all_achievements_enabled)
		all_achievements_toggle.text = "ON" if all_achievements_enabled else "OFF"

	refresh_control_key_labels()


# ============================================================
# SETTINGS — OPEN / CLOSE
# ============================================================

func open_settings() -> void:
	showing_settings_menu = true
	showing_slot_menu = false
	showing_achievement_menu = false
	pause_panel.visible = false
	confirm_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = true
	controls_panel.visible = false

	update_quest_pointer_toggle()

	settings_close_button.grab_focus()


func close_settings() -> void:
	showing_settings_menu = false
	settings_panel.visible = false
	if controls_panel != null:
		controls_panel.visible = false
	awaiting_rebind_action = ""

	if is_paused:
		pause_panel.visible = true
		settings_button.grab_focus()
	else:
		hide_menu()


# ============================================================
# ACHIEVEMENTS LIST
# ============================================================

func refresh_achievement_list() -> void:
	if achievement_list == null or not is_instance_valid(AchievementManager):
		return

	for child in achievement_list.get_children():
		child.queue_free()

	var achievements: Array[Dictionary] = AchievementManager.get_all_achievements()
	var current_category := ""

	for achievement in achievements:
		var category := str(achievement.get("category", "standard"))
		if category != current_category:
			current_category = category
			var section_title := Label.new()
			section_title.text = "SUPER SECRET ACHIVEMENTS" if category == "super_secret" else "ACHIEVEMENTS"
			section_title.add_theme_font_size_override("font_size", 21)
			section_title.add_theme_color_override(
				"font_color",
				Color("#F6D889") if category == "super_secret" else Color("#E8DCC8")
			)
			section_title.custom_minimum_size = Vector2(0, 34)
			achievement_list.add_child(section_title)

		var unlocked: bool = bool(achievement.get("unlocked", false))
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 70)
		row.add_theme_stylebox_override("panel", make_button_style(
			Color(0.34, 0.23, 0.15, 0.98) if unlocked else Color(0.20, 0.15, 0.11, 0.96)
		))
		achievement_list.add_child(row)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 16)
		row_margin.add_theme_constant_override("margin_right", 16)
		row_margin.add_theme_constant_override("margin_top", 9)
		row_margin.add_theme_constant_override("margin_bottom", 9)
		row.add_child(row_margin)

		var row_box := VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 2)
		row_margin.add_child(row_box)

		var title := Label.new()
		title.text = ("✓  " if unlocked else "□  ") + str(achievement.get("title", "Achievement"))
		title.add_theme_font_size_override("font_size", 17)
		title.add_theme_color_override("font_color", Color("#F6D889") if unlocked else Color("#9D9182"))
		row_box.add_child(title)

		var description := Label.new()
		description.text = str(achievement.get("description", "")) if unlocked else "Locked achievement"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 12)
		description.add_theme_color_override("font_color", Color("#E8DCC8") if unlocked else Color("#756B60"))
		row_box.add_child(description)

	var subtitle := achievement_panel.find_child("AchievementSubtitle", true, false) as Label
	if subtitle != null:
		subtitle.text = "%d / %d unlocked" % [AchievementManager.get_unlocked_count(), AchievementManager.get_total_count()]

func open_achievements() -> void:
	if not is_instance_valid(AchievementManager):
		show_button_feedback(achievements_button, "Achievement Manager Missing")
		return

	showing_achievement_menu = true
	showing_slot_menu = false
	showing_settings_menu = false
	pause_panel.visible = false
	confirm_panel.visible = false
	slot_panel.visible = false
	settings_panel.visible = false
	achievement_panel.visible = true
	refresh_achievement_list()
	achievement_close_button.grab_focus()


func close_achievements() -> void:
	showing_achievement_menu = false
	achievement_panel.visible = false
	if is_paused:
		pause_panel.visible = true
		achievements_button.grab_focus()
	else:
		hide_menu()


# ============================================================
# SAVE / LOAD SLOTS
# ============================================================

func refresh_slot_buttons() -> void:
	if slot_grid == null:
		return

	for child in slot_grid.get_children():
		if not child is Button:
			continue

		var button: Button = child
		var slot: int = int(button.name.trim_prefix("Slot").trim_suffix("Button"))
		var info: Dictionary = SaveManager.get_slot_info(slot)
		var exists: bool = bool(info.get("exists", false))

		if exists:
			var saved_at: String = str(info.get("saved_at", ""))
			button.text = "SLOT %02d\n%s" % [slot, saved_at]
		else:
			button.text = "SLOT %02d\nEMPTY" % slot


func is_player_locked() -> bool:
	if is_instance_valid(DialogueManager):
		if bool(DialogueManager.get("is_active")):
			return true

	if not is_instance_valid(GameManager):
		return false

	if SaveManager.property_exists(GameManager, "player_controls_locked"):
		if bool(GameManager.get("player_controls_locked")):
			return true

	for property_name in [
		"tina_post_hallway_sequence_running",
		"returning_from_tina_dream"
	]:
		if SaveManager.property_exists(GameManager, property_name):
			if bool(GameManager.get(property_name)):
				return true

	return false


func update_save_button_lock_state() -> void:
	if save_game_button == null:
		return

	var locked := is_player_locked()
	save_game_button.disabled = locked
	save_game_button.tooltip_text = "Cannot save during dialogue or cutscene" if locked else ""


func open_save_slots() -> void:
	if not is_instance_valid(SaveManager):
		show_button_feedback(save_game_button, "Save Manager Missing")
		return

	if is_player_locked():
		show_button_feedback(save_game_button, "Cannot save right now")
		return

	slot_mode = "save"
	showing_slot_menu = true
	showing_settings_menu = false
	pause_panel.visible = false
	confirm_panel.visible = false
	settings_panel.visible = false
	slot_panel.visible = true
	slot_title.text = "SELECT SAVE SLOT"
	refresh_slot_buttons()

	var first_button := slot_grid.get_child(0) as Button
	if first_button != null:
		first_button.grab_focus()


func open_main_menu_load_slots() -> void:
	if not main_menu_mode:
		return
	overlay.visible = true
	pause_panel.visible = false
	open_load_slots()


func open_main_menu_settings() -> void:
	if not main_menu_mode:
		return
	overlay.visible = true
	pause_panel.visible = false
	open_settings()


func open_load_slots() -> void:
	if not is_instance_valid(SaveManager):
		show_button_feedback(load_game_button, "Save Manager Missing")
		return

	slot_mode = "load"
	showing_slot_menu = true
	showing_settings_menu = false
	pause_panel.visible = false
	confirm_panel.visible = false
	settings_panel.visible = false
	slot_panel.visible = true
	slot_title.text = "SELECT SAVE TO LOAD"
	refresh_slot_buttons()

	var first_button := slot_grid.get_child(0) as Button
	if first_button != null:
		first_button.grab_focus()


func select_slot(slot: int) -> void:
	if slot_mode == "save":
		save_to_slot(slot)
	elif slot_mode == "load":
		load_from_slot(slot)


func save_to_slot(slot: int) -> void:
	if is_player_locked():
		close_slot_menu()
		show_button_feedback(save_game_button, "Cannot save right now")
		return

	var success: bool = SaveManager.save_game(slot)

	if success:
		close_slot_menu()
		show_button_feedback(save_game_button, "Saved to Slot %02d" % slot)
	else:
		show_button_feedback(slot_grid.get_child(slot - 1) as Button, "Save Failed")


func load_from_slot(slot: int) -> void:
	if not SaveManager.has_save(slot):
		show_button_feedback(slot_grid.get_child(slot - 1) as Button, "EMPTY SLOT")
		return

	hide_menu()

	is_paused = false
	showing_quit_confirmation = false
	showing_slot_menu = false
	showing_achievement_menu = false
	showing_settings_menu = false

	get_tree().paused = false
	Input.mouse_mode = cursor_mode_before_pause

	var success: bool = await SaveManager.load_game(slot)

	if success:
		force_unlock_player_after_load()
	elif main_menu_mode:
		open_main_menu_load_slots()
		show_button_feedback(load_game_button, "Load Failed")
	else:
		pause_game()
		show_button_feedback(load_game_button, "Load Failed")


func force_unlock_player_after_load() -> void:
	if not is_instance_valid(GameManager):
		return

	for property_name in [
		"player_controls_locked",
		"tina_post_hallway_sequence_started",
		"tina_post_hallway_sequence_running",
		"returning_from_tina_dream"
	]:
		if SaveManager.property_exists(GameManager, property_name):
			GameManager.set(property_name, false)

	resume_game_audio()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func close_slot_menu() -> void:
	showing_slot_menu = false
	slot_mode = ""
	slot_panel.visible = false

	if is_paused:
		pause_panel.visible = true
		resume_button.grab_focus()
	else:
		hide_menu()


# ============================================================
# BUTTON / PANEL STYLING
# ============================================================

func make_button(text_value: String) -> Button:
	var button := Button.new()

	button.text = text_value
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.91, 0.82, 0.67))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.67))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

	button.add_theme_stylebox_override("normal", make_button_style(Color(0.23, 0.14, 0.09, 0.98)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.43, 0.27, 0.16, 0.99)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.15, 0.085, 0.05, 1.0)))

	return button


func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.125, 0.08, 0.99)
	style.border_color = Color("#C99555")
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
	style.border_color = Color("#94623D")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo):
		return
	if showing_credits_menu:
		close_credits()
		get_viewport().set_input_as_handled()
		return
	if awaiting_rebind_action != "":
		awaiting_rebind_action = ""
		refresh_control_key_labels()
		get_viewport().set_input_as_handled()
		return
	if controls_panel != null and controls_panel.visible:
		close_controls()
		get_viewport().set_input_as_handled()
		return

	if main_menu_mode:
		if showing_settings_menu:
			close_settings()
			get_viewport().set_input_as_handled()
		elif showing_slot_menu:
			close_slot_menu()
			get_viewport().set_input_as_handled()
		return

	if showing_settings_menu:
		close_settings()
	elif showing_slot_menu:
		close_slot_menu()
	elif showing_achievement_menu:
		close_achievements()
	elif showing_quit_confirmation:
		cancel_quit()
	elif is_paused:
		resume_game()
	else:
		pause_game()

	get_viewport().set_input_as_handled()


# ============================================================
# PAUSE / RESUME
# ============================================================

func pause_game() -> void:
	if is_paused:
		return

	cursor_mode_before_pause = Input.mouse_mode
	is_paused = true
	showing_quit_confirmation = false
	showing_slot_menu = false
	showing_achievement_menu = false
	showing_settings_menu = false

	overlay.visible = true
	pause_panel.visible = true
	confirm_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false

	update_save_button_lock_state()

	get_tree().paused = true
	pause_game_audio()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	showing_quit_confirmation = false
	showing_slot_menu = false
	showing_settings_menu = false

	if save_game_button != null:
		save_game_button.disabled = false
		save_game_button.tooltip_text = ""

	resume_game_audio()
	get_tree().paused = false
	Input.mouse_mode = cursor_mode_before_pause
	hide_menu()


func pause_game_audio() -> void:
	paused_audio_players.clear()
	paused_audio_player_states.clear()

	var root := get_tree().root
	if root == null:
		return

	collect_and_pause_audio_players(root)


func collect_and_pause_audio_players(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	if node != self and is_ancestor_of(node):
		return

	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		var audio_player := node as Node

		if bool(audio_player.get("playing")):
			paused_audio_players.append(audio_player)
			paused_audio_player_states.append(
				bool(audio_player.get("stream_paused"))
			)
			audio_player.set("stream_paused", true)

	for child in node.get_children():
		collect_and_pause_audio_players(child)


func resume_game_audio() -> void:
	for index in range(paused_audio_players.size()):
		var audio_player := paused_audio_players[index]

		if not is_instance_valid(audio_player):
			continue

		if index < paused_audio_player_states.size():
			audio_player.set(
				"stream_paused",
				paused_audio_player_states[index]
			)

	paused_audio_players.clear()
	paused_audio_player_states.clear()


func show_button_feedback(button: Button, message: String) -> void:
	if button == null:
		return

	var original_text: String = button.text
	button.text = message
	button.disabled = true

	await get_tree().create_timer(1.25).timeout

	if is_instance_valid(button):
		button.text = original_text
		button.disabled = false
		if is_paused:
			button.grab_focus()


# ============================================================
# MISC BUTTON HANDLERS
# ============================================================

func achievements_dud() -> void:
	open_achievements()


func settings_dud() -> void:
	open_settings()


func credits_dud() -> void:
	open_credits()


func open_main_menu_credits() -> void:
	if not main_menu_mode:
		return
	open_credits()


func build_credits_ui() -> void:
	credits_screen = Control.new()
	credits_screen.name = "CreditsScreen"
	credits_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_screen.z_index = 200
	credits_screen.visible = false
	credits_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(credits_screen)

	var dimmer := ColorRect.new()
	dimmer.name = "CreditsBackdrop"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.035, 0.022, 0.018, 0.94)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_screen.add_child(dimmer)

	var card := PanelContainer.new()
	card.name = "CreditsCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-390, -330)
	card.size = Vector2(780, 660)
	card.add_theme_stylebox_override("panel", make_credits_card_style())
	credits_screen.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "LIFE OF A 1ST YEAR STUDENT  •  CCS EDITION"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color("#E6AD63"))
	eyebrow.add_theme_constant_override("letter_spacing", 3)
	content.add_child(eyebrow)

	var heading := Label.new()
	heading.text = "THE PEOPLE BEHIND THE GAME"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("#FFF0D8"))
	heading.add_theme_constant_override("letter_spacing", 1)
	content.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "A little story made with creativity, code, and care."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("#D8BEA1"))
	content.add_child(subtitle)

	var divider := HSeparator.new()
	divider.add_theme_color_override("color", Color("#C99555"))
	content.add_child(divider)

	_add_credit_member(content, "NATHALY S. CHAN", "GAME LEVEL DESIGNER  •  UI/UX DESIGNER")
	_add_credit_member(content, "ROSE JANSSEN M. RAFAEL", "GAME LEVEL DESIGNER  •  UI/UX DESIGNER")
	_add_credit_member(content, "KERWIN L. CONCEPCION", "GAME PROGRAMMER  •  UI/UX DESIGNER")
	_add_credit_member(content, "KAIRI BAUTISTA", "SPRITE MODEL DESIGNER  •  COVER ARTIST")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var thanks := Label.new()
	thanks.text = "✦  THANK YOU FOR PLAYING  ✦"
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override("font_size", 17)
	thanks.add_theme_color_override("font_color", Color("#FFE1A8"))
	thanks.add_theme_constant_override("letter_spacing", 2)
	content.add_child(thanks)

	credits_close_button = make_button("BACK")
	credits_close_button.custom_minimum_size = Vector2(180, 42)
	credits_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits_close_button.pressed.connect(close_credits)
	content.add_child(credits_close_button)


func _add_credit_member(parent: VBoxContainer, member_name: String, role: String) -> void:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 2)
	parent.add_child(entry)

	var name_label := Label.new()
	name_label.text = member_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color("#FFE1A8"))
	entry.add_child(name_label)

	var role_label := Label.new()
	role_label.text = role
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 12)
	role_label.add_theme_color_override("font_color", Color("#D8BEA1"))
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.add_child(role_label)


func make_credits_card_style() -> StyleBoxFlat:
	var style := make_panel_style()
	style.bg_color = Color(0.105, 0.062, 0.042, 0.99)
	style.border_color = Color("#E6AD63")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 8)
	return style


func open_credits() -> void:
	if credits_screen == null:
		return

	showing_credits_menu = true
	showing_settings_menu = false
	showing_slot_menu = false
	showing_achievement_menu = false
	showing_quit_confirmation = false

	pause_panel.visible = false
	confirm_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false
	if controls_panel != null:
		controls_panel.visible = false

	overlay.visible = true
	credits_screen.visible = true
	credits_close_button.grab_focus()


func close_credits() -> void:
	if not showing_credits_menu:
		return

	showing_credits_menu = false
	credits_screen.visible = false

	if main_menu_mode:
		overlay.visible = false
		pause_panel.visible = false
	else:
		overlay.visible = true
		pause_panel.visible = true
		credits_button.grab_focus()


func show_quit_confirmation() -> void:
	showing_quit_confirmation = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false
	showing_achievement_menu = false
	showing_settings_menu = false
	confirm_panel.visible = true
	quit_no_button.grab_focus()


func cancel_quit() -> void:
	showing_quit_confirmation = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	confirm_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false
	showing_settings_menu = false
	pause_panel.visible = true
	main_menu_button.grab_focus()


func confirm_quit() -> void:
	# This button returns to the main menu; it must not terminate the game.
	get_tree().paused = false
	GameManager.player_controls_locked = false
	resume_game_audio()

	if is_instance_valid(FadeManager):
		await FadeManager.change_scene_with_fade("res://scenes/ui/MainMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func hide_menu() -> void:
	overlay.visible = false
	pause_panel.visible = false
	confirm_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false
	if controls_panel != null:
		controls_panel.visible = false
	awaiting_rebind_action = ""

	if save_game_button != null:
		save_game_button.disabled = false
		save_game_button.tooltip_text = ""

	showing_quit_confirmation = false
	showing_slot_menu = false
	showing_achievement_menu = false
	showing_settings_menu = false
	slot_mode = ""

	# Audio references from a previous scene must not survive a scene load.
	paused_audio_players.clear()
	paused_audio_player_states.clear()
	paused_node_process_modes.clear()
