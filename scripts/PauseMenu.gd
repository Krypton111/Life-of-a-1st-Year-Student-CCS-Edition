extends CanvasLayer

const PANEL_SIZE := Vector2(360.0, 430.0)
const BUTTON_SIZE := Vector2(280.0, 46.0)
const SLOT_PANEL_SIZE := Vector2(620.0, 500.0)
const SLOT_BUTTON_SIZE := Vector2(270.0, 64.0)
const ACHIEVEMENT_PANEL_SIZE := Vector2(760.0, 620.0)
const SETTINGS_PANEL_SIZE := Vector2(560.0, 520.0)

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
var settings_close_button: Button
var brightness_overlay: ColorRect
var brightness_shader_material: ShaderMaterial = null

var master_bus_index: int = -1

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
	overlay.color = Color(0.12, 0.075, 0.045, 0.70)
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
	title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
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
	hint.add_theme_color_override("font_color", Color(0.80, 0.74, 0.64))
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
	settings_panel.position = Vector2(-280, -230)
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
	volume_label.add_theme_color_override("font_color", Color(0.91, 0.82, 0.67))
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
		Color(1.0, 0.91, 0.67)
	)
	quest_pointer_toggle.toggled.connect(on_quest_pointer_toggled)
	quest_pointer_row.add_child(quest_pointer_toggle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	box.add_child(spacer)

	settings_close_button = make_button("Close")
	settings_close_button.custom_minimum_size = Vector2(240, 44)
	settings_close_button.pressed.connect(close_settings)
	box.add_child(settings_close_button)

	settings_panel.visible = false


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

	config.save(SETTINGS_CONFIG_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(SETTINGS_CONFIG_PATH)

	var volume_value: float = 100.0
	var brightness_value: float = 100.0
	var quest_pointer_enabled: bool = true

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

	if is_instance_valid(GameManager):
		GameManager.set(
			"quest_pointer_enabled",
			quest_pointer_enabled
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

	update_quest_pointer_toggle()

	settings_close_button.grab_focus()


func close_settings() -> void:
	showing_settings_menu = false
	settings_panel.visible = false

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
	for achievement in achievements:
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


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
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
	pass


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
	get_tree().paused = false
	get_tree().quit()


func hide_menu() -> void:
	overlay.visible = false
	pause_panel.visible = false
	confirm_panel.visible = false
	slot_panel.visible = false
	achievement_panel.visible = false
	settings_panel.visible = false

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
