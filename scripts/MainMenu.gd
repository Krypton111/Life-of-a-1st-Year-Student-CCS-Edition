extends Control

const OPENING_SCENE := "res://scenes/main_level_scenes/cutscenes/opening_cutscene.tscn"
const GOLD := Color("#E6AD63")
const PALE_GOLD := Color("#FFE1A8")
const CREAM := Color("#FFF0D8")
const MUTED := Color("#D8BEA1")
const PANEL := Color(0.15, 0.095, 0.065, 0.96)
const SCHOOL_ASSETS := "res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/"
const MC_ASSET := "res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png"

var pause_menu: CanvasLayer
var quit_dialog: PanelContainer
var quit_button: Button
var cancel_quit_button: Button
var menu_buttons: Array[Button] = []

var profile_dimmer: ColorRect
var profile_dialog: PanelContainer
var profile_name_input: LineEdit
var profile_name_error: Label
var profile_name_step: VBoxContainer
var profile_gender_step: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	build_menu()
	build_character_art()
	build_profile_setup()
	pause_menu = get_node("PauseMenu") as CanvasLayer
	if pause_menu != null:
		pause_menu.set("main_menu_mode", true)
	queue_redraw()


func _draw() -> void:
	# A composed campus vista at golden hour: layered sky, distant tree line,
	# a recognizable university facade, and a walkway that leads into the scene.
	var w := size.x
	var h := size.y

	# Smooth, restrained sunset gradient built from broad horizontal bands.
	var sky_top := Color("#493448")
	var sky_mid := Color("#A85F55")
	var sky_horizon := Color("#E4A36B")
	for band in range(48):
		var t := float(band) / 47.0
		var band_color: Color
		if t < 0.58:
			band_color = sky_top.lerp(sky_mid, t / 0.58)
		else:
			band_color = sky_mid.lerp(sky_horizon, (t - 0.58) / 0.42)
		var band_y := h * 0.61 * t
		var next_y := h * 0.61 * float(band + 1) / 48.0
		draw_rect(Rect2(0, band_y, w, next_y - band_y + 1.0), band_color)

	# A warm sun sits low behind the campus, not competing with the menu.
	draw_circle(Vector2(w * 0.78, h * 0.29), h * 0.115, Color("#F6C27D", 0.10))
	draw_circle(Vector2(w * 0.78, h * 0.29), h * 0.078, Color("#F6C27D", 0.17))
	draw_circle(Vector2(w * 0.78, h * 0.29), h * 0.048, Color("#FFD99A"))

	# A few carefully spaced, quiet evening stars.
	var stars := [
		Vector2(w * 0.48, h * 0.12), Vector2(w * 0.58, h * 0.20),
		Vector2(w * 0.68, h * 0.10), Vector2(w * 0.89, h * 0.13),
		Vector2(w * 0.94, h * 0.25), Vector2(w * 0.54, h * 0.30)
	]
	for i in range(stars.size()):
		var star_size := 3.0 if i % 2 == 0 else 2.0
		draw_rect(Rect2(stars[i], Vector2(star_size, star_size)), Color("#FFE8BE", 0.72 if i % 2 == 0 else 0.42))

	draw_rect(Rect2(0, h * 0.61, w, h * 0.39), Color("#59634A"))

	# Distant campus roofs create a clear horizon line behind the main hall.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.56), Vector2(0, h * 0.49),
		Vector2(w * 0.07, h * 0.49), Vector2(w * 0.10, h * 0.45),
		Vector2(w * 0.13, h * 0.49), Vector2(w * 0.25, h * 0.49),
		Vector2(w * 0.28, h * 0.53), Vector2(w * 0.40, h * 0.53),
		Vector2(w * 0.44, h * 0.48), Vector2(w * 0.50, h * 0.53),
		Vector2(w * 0.57, h * 0.53), Vector2(w * 0.57, h * 0.61),
		Vector2(0, h * 0.61)
	]), Color("#624453"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.83, h * 0.56), Vector2(w * 0.86, h * 0.50),
		Vector2(w * 0.90, h * 0.50), Vector2(w * 0.93, h * 0.46),
		Vector2(w * 0.97, h * 0.50), Vector2(w, h * 0.50),
		Vector2(w, h * 0.62), Vector2(w * 0.83, h * 0.62)
	]), Color("#624453"))

	# The university hall is symmetrical and architectural: wings, cornice,
	# central pediment, evenly spaced windows, and a warmly lit entrance.
	var hall_left := w * 0.565
	var hall_top := h * 0.355
	var hall_width := w * 0.355
	var hall_bottom := h * 0.705
	draw_rect(Rect2(hall_left, hall_top + h * 0.065, hall_width, hall_bottom - hall_top - h * 0.065), Color("#503447"))
	draw_rect(Rect2(hall_left - 14, hall_top + h * 0.045, hall_width + 28, h * 0.035), Color("#D18B5D"))
	draw_rect(Rect2(hall_left + hall_width * 0.39, hall_top - h * 0.005, hall_width * 0.22, h * 0.105), Color("#704653"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(hall_left + hall_width * 0.34, hall_top + h * 0.015),
		Vector2(hall_left + hall_width * 0.50, hall_top - h * 0.085),
		Vector2(hall_left + hall_width * 0.66, hall_top + h * 0.015)
	]), Color("#F0B873"))
	draw_rect(Rect2(hall_left + hall_width * 0.475, hall_top + h * 0.018, hall_width * 0.05, h * 0.034), Color("#FFE0A3"))
	draw_rect(Rect2(hall_left + hall_width * 0.485, hall_top + h * 0.012, hall_width * 0.03, h * 0.012), Color("#FFF0D0"))

	# Long, aligned window bays make the building feel like a real school.
	for row in range(3):
		for col in range(9):
			var wx := hall_left + 22 + float(col) * (hall_width - 44) / 9.0
			var wy := hall_top + h * 0.105 + float(row) * h * 0.067
			var window_color := Color("#F8C879") if (row + col) % 4 != 0 else Color("#A76C61")
			draw_rect(Rect2(wx, wy, 20, 31), Color("#3E2D3A"))
			draw_rect(Rect2(wx + 3, wy + 3, 14, 25), window_color)
			draw_rect(Rect2(wx + 9, wy + 3, 2, 25), Color("#76504B", 0.9))
			draw_rect(Rect2(wx + 3, wy + 14, 14, 2), Color("#76504B", 0.9))

	# Broad front steps and a central entrance anchor the perspective.
	var entrance_x := hall_left + hall_width * 0.43
	var entrance_w := hall_width * 0.14
	draw_rect(Rect2(entrance_x - 10, h * 0.625, entrance_w + 20, h * 0.08), Color("#3B2934"))
	draw_rect(Rect2(entrance_x - 18, h * 0.682, entrance_w + 36, h * 0.018), Color("#D49A68"))
	draw_rect(Rect2(entrance_x, h * 0.58, entrance_w, h * 0.125), Color("#302632"))
	draw_rect(Rect2(entrance_x + 7, h * 0.592, entrance_w - 14, h * 0.113), Color("#E6AA6A"))
	draw_rect(Rect2(entrance_x + entrance_w * 0.48, h * 0.592, 3, h * 0.113), Color("#6A4143"))

	# Campus lawn and a central stone path with perspective edges.
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.43, h), Vector2(w * 0.58, h * 0.705),
		Vector2(w * 0.79, h * 0.705), Vector2(w, h)
	]), Color("#A47A5A"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.49, h), Vector2(w * 0.615, h * 0.72),
		Vector2(w * 0.755, h * 0.72), Vector2(w * 0.90, h)
	]), Color("#B58B68"))

	# The path's restrained paving seams reinforce depth instead of adding clutter.
	for i in range(1, 7):
		var t := float(i) / 7.0
		var seam_y := lerpf(h * 0.735, h * 0.985, t)
		var left_x := lerpf(w * 0.605, w * 0.445, t)
		var right_x := lerpf(w * 0.765, w * 0.98, t)
		draw_line(Vector2(left_x, seam_y), Vector2(right_x, seam_y), Color("#775846", 0.55), 2.0)

	# Framing trees are placed at the lawn edges, leaving the hall and cast visible.
	for tree in [
		Vector2(w * 0.10, h * 0.60), Vector2(w * 0.22, h * 0.625),
		Vector2(w * 0.91, h * 0.605), Vector2(w * 0.98, h * 0.62)
	]:
		var trunk_w := 16.0
		draw_rect(Rect2(tree.x - trunk_w * 0.5, tree.y - 3, trunk_w, h * 0.17), Color("#49342D"))
		draw_rect(Rect2(tree.x - 45, tree.y - 78, 90, 54), Color("#384A42"))
		draw_rect(Rect2(tree.x - 32, tree.y - 105, 64, 47), Color("#405448"))
		draw_rect(Rect2(tree.x - 18, tree.y - 122, 36, 30), Color("#4B6050"))
		draw_rect(Rect2(tree.x - 32, tree.y - 63, 20, 13), Color("#617052", 0.8))
		draw_rect(Rect2(tree.x + 12, tree.y - 91, 18, 13), Color("#617052", 0.8))

	# Low garden borders give the foreground a finished, campus-quad feel.
	draw_rect(Rect2(0, h * 0.88, w * 0.22, h * 0.035), Color("#3C4637"))
	draw_rect(Rect2(w * 0.84, h * 0.88, w * 0.16, h * 0.035), Color("#3C4637"))
	for x in [w * 0.025, w * 0.065, w * 0.105, w * 0.145, w * 0.185, w * 0.865, w * 0.905, w * 0.945, w * 0.985]:
		draw_rect(Rect2(x, h * 0.855, 20, 18), Color("#839064"))
		draw_rect(Rect2(x + 5, h * 0.84, 10, 18), Color("#A1A66F"))

	# A subtle vignette and fine inset frame tie the illustration together.
	draw_rect(Rect2(0, 0, w, h * 0.045), Color("#2B2130", 0.20))
	draw_rect(Rect2(0, h * 0.955, w, h * 0.045), Color("#2B2130", 0.28))
	draw_line(Vector2(24, 24), Vector2(w - 24, 24), Color(GOLD, 0.58), 2.0)
	draw_line(Vector2(24, h - 24), Vector2(w - 24, h - 24), Color(GOLD, 0.58), 2.0)
	draw_line(Vector2(24, 24), Vector2(24, h - 24), Color(GOLD, 0.58), 2.0)
	draw_line(Vector2(w - 24, 24), Vector2(w - 24, h - 24), Color(GOLD, 0.58), 2.0)


func build_menu() -> void:
	var left_panel := PanelContainer.new()
	left_panel.name = "MenuPanel"
	left_panel.position = Vector2(105, 76)
	left_panel.size = Vector2(635, 925)
	left_panel.add_theme_stylebox_override("panel", make_panel_style())
	add_child(left_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 30)
	left_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	margin.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "A CAMPUS LIFE ADVENTURE"
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", GOLD)
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "LIFE OF A\n1ST YEAR STUDENT"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_constant_override("line_spacing", -4)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size = Vector2(0, 120)
	content.add_child(title)

	var edition_row := HBoxContainer.new()
	edition_row.add_theme_constant_override("separation", 12)
	content.add_child(edition_row)
	var edition_rule := ColorRect.new()
	edition_rule.custom_minimum_size = Vector2(36, 3)
	edition_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edition_rule.color = GOLD
	edition_row.add_child(edition_rule)
	var edition := Label.new()
	edition.text = "CCS EDITION"
	edition.add_theme_font_size_override("font_size", 18)
	edition.add_theme_color_override("font_color", PALE_GOLD)
	edition.add_theme_constant_override("letter_spacing", 4)
	edition_row.add_child(edition)

	var description := Label.new()
	description.text = "New semester. New faces.\nYour story starts here."
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", MUTED)
	description.add_theme_constant_override("line_spacing", 4)
	content.add_child(description)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	content.add_child(spacer)

	var start_button := make_menu_button("01", "START GAME", true)
	start_button.pressed.connect(start_game)
	content.add_child(start_button)
	menu_buttons.append(start_button)

	var load_button := make_menu_button("02", "LOAD GAME")
	load_button.pressed.connect(open_load_menu)
	content.add_child(load_button)
	menu_buttons.append(load_button)

	var settings_button := make_menu_button("03", "SETTINGS")
	settings_button.pressed.connect(open_settings_menu)
	content.add_child(settings_button)
	menu_buttons.append(settings_button)

	var credits_button := make_menu_button("04", "CREDITS")
	credits_button.pressed.connect(credits_dud)
	content.add_child(credits_button)
	menu_buttons.append(credits_button)

	quit_button = make_menu_button("05", "QUIT")
	quit_button.pressed.connect(show_quit_confirmation)
	content.add_child(quit_button)
	menu_buttons.append(quit_button)

	var footer_gap := Control.new()
	footer_gap.custom_minimum_size.y = 4
	content.add_child(footer_gap)

	var footer := Label.new()
	footer.text = "ADVANCE GAME DESIGN  •  50054"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("#C4A783"))
	footer.add_theme_constant_override("letter_spacing", 2)
	content.add_child(footer)

	build_quit_dialog()


func build_character_art() -> void:
	# Back row: smaller, slightly softened silhouettes establish depth.
	# These are added first so the foreground cast naturally overlaps them.
	add_character(SCHOOL_ASSETS + "Profs/Charles/Charles.png", Vector2(450, 290), Vector2(235, 490), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Profs/Joyz/Joyz.png", Vector2(670, 255), Vector2(225, 490), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Bullies/Joe/Joe.png", Vector2(1035, 290), Vector2(225, 485), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Tina/tina.png", Vector2(1250, 280), Vector2(230, 495), 0, 0.78)

	# Front row: a staggered friend group, with the player character as the
	# visual anchor. Slight overlaps make the group feel gathered, not lined up.
	add_character(SCHOOL_ASSETS + "Friends/Nathaly/Nathaly.png", Vector2(450, 440), Vector2(275, 545), 2)
	add_character(SCHOOL_ASSETS + "Friends/Janssen/Janssen.png", Vector2(580, 465), Vector2(260, 520), 2)
	add_character(MC_ASSET, Vector2(725, 365), Vector2(315, 660), 3)
	add_character(SCHOOL_ASSETS + "Friends/Kairi/Kairi.png", Vector2(920, 435), Vector2(270, 550), 2)
	add_character(SCHOOL_ASSETS + "Friends/Kerwin/Kerwin.png", Vector2(1125, 445), Vector2(265, 540), 2)

	var character_caption := Label.new()
	character_caption.text = ""
	character_caption.position = Vector2(760, 930)
	character_caption.size = Vector2(930, 32)
	character_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_caption.add_theme_font_size_override("font_size", 15)
	character_caption.add_theme_color_override("font_color", PALE_GOLD)
	character_caption.add_theme_constant_override("letter_spacing", 2)
	character_caption.z_index = 5
	add_child(character_caption)


func add_character(path: String, at: Vector2, dimensions: Vector2, z_layer: int = 1, opacity: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Main menu character artwork not found: " + path)
		return
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Main menu character artwork could not be loaded: " + path)
		return

	var character := TextureRect.new()
	character.name = "CharacterArt_" + path.get_file().get_basename()
	character.texture = texture
	character.position = at
	character.size = dimensions
	character.z_index = z_layer
	character.modulate = Color(1.0, 1.0, 1.0, opacity)
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(character)


func make_menu_button(number: String, label_text: String, is_primary: bool = false) -> Button:
	var button := Button.new()
	button.text = number + "     " + label_text
	button.custom_minimum_size = Vector2(0, 59)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("#fff3d5"))
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_focus_color", CREAM)
	var normal := make_button_style(Color("#5A3A28") if is_primary else Color("#3A281E"))
	var hover := make_button_style(Color("#755039") if is_primary else Color("#6B4931"))
	var pressed := make_button_style(Color("#2B1C14"))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", make_button_style(Color("#815839")))
	return button


func make_button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#B9824A")
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.set_corner_radius_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(0.75, 0.57, 0.32, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func start_game() -> void:
	open_profile_setup()


func build_profile_setup() -> void:
	profile_dimmer = ColorRect.new()
	profile_dimmer.name = "PlayerSetupDimmer"
	profile_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_dimmer.color = Color(0.035, 0.02, 0.015, 0.9)
	profile_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_dimmer.visible = false
	profile_dimmer.z_index = 100
	add_child(profile_dimmer)

	profile_dialog = PanelContainer.new()
	profile_dialog.name = "PlayerSetupDialog"
	profile_dialog.set_anchors_preset(Control.PRESET_CENTER)
	profile_dialog.position = Vector2(-550, -390)
	profile_dialog.size = Vector2(1100, 780)
	profile_dialog.add_theme_stylebox_override("panel", make_profile_panel_style())
	profile_dimmer.add_child(profile_dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 30)
	profile_dialog.add_child(margin)

	var steps := VBoxContainer.new()
	steps.name = "ProfileSteps"
	steps.add_theme_constant_override("separation", 20)
	margin.add_child(steps)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 12)
	steps.add_child(top_row)

	var left_rule := ColorRect.new()
	left_rule.custom_minimum_size = Vector2(44, 2)
	left_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_rule.color = GOLD
	top_row.add_child(left_rule)

	var eyebrow := Label.new()
	eyebrow.text = "YOUR FIRST-YEAR ADVENTURE"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", GOLD)
	eyebrow.add_theme_constant_override("letter_spacing", 3)
	top_row.add_child(eyebrow)

	var right_rule := ColorRect.new()
	right_rule.custom_minimum_size = Vector2(44, 2)
	right_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_rule.color = GOLD
	top_row.add_child(right_rule)

	profile_name_step = VBoxContainer.new()
	profile_name_step.name = "NameStep"
	profile_name_step.add_theme_constant_override("separation", 17)
	profile_name_step.size_flags_vertical = Control.SIZE_EXPAND_FILL
	steps.add_child(profile_name_step)

	var name_title := Label.new()
	name_title.text = "FIRST, WHAT'S YOUR NAME?"
	name_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_title.add_theme_font_size_override("font_size", 38)
	name_title.add_theme_color_override("font_color", CREAM)
	profile_name_step.add_child(name_title)

	var name_hint := Label.new()
	name_hint.text = "This is how your classmates will know you. Choose the name you want on your story."
	name_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_hint.add_theme_font_size_override("font_size", 17)
	name_hint.add_theme_color_override("font_color", MUTED)
	profile_name_step.add_child(name_hint)

	var name_spacer := Control.new()
	name_spacer.custom_minimum_size.y = 8
	profile_name_step.add_child(name_spacer)

	var name_label := Label.new()
	name_label.text = "PLAYER NAME"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", PALE_GOLD)
	name_label.add_theme_constant_override("letter_spacing", 2)
	profile_name_step.add_child(name_label)

	profile_name_input = LineEdit.new()
	profile_name_input.name = "PlayerNameInput"
	profile_name_input.placeholder_text = "Type your name here..."
	profile_name_input.custom_minimum_size = Vector2(0, 66)
	profile_name_input.max_length = 12
	profile_name_input.clear_button_enabled = true
	profile_name_input.add_theme_font_size_override("font_size", 24)
	profile_name_input.add_theme_color_override("font_color", CREAM)
	profile_name_input.add_theme_color_override("font_placeholder_color", Color("#B59A7C"))
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color("#2B1C14")
	input_style.border_color = Color("#B9824A")
	input_style.set_border_width_all(2)
	input_style.set_corner_radius_all(5)
	input_style.content_margin_left = 18
	input_style.content_margin_right = 18
	input_style.content_margin_top = 10
	input_style.content_margin_bottom = 10
	profile_name_input.add_theme_stylebox_override("normal", input_style)
	profile_name_input.add_theme_stylebox_override("focus", make_focused_input_style())
	profile_name_input.text_submitted.connect(_on_profile_name_submitted)
	profile_name_step.add_child(profile_name_input)

	profile_name_error = Label.new()
	profile_name_error.text = "Your story needs a name first — enter one to continue."
	profile_name_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_name_error.add_theme_font_size_override("font_size", 15)
	profile_name_error.add_theme_color_override("font_color", Color("#E6A078"))
	profile_name_error.visible = false
	profile_name_step.add_child(profile_name_error)

	var name_button_spacer := Control.new()
	name_button_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_name_step.add_child(name_button_spacer)

	var name_buttons := HBoxContainer.new()
	name_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	name_buttons.add_theme_constant_override("separation", 18)
	profile_name_step.add_child(name_buttons)

	var cancel_button := make_menu_button("×", "CANCEL")
	cancel_button.custom_minimum_size = Vector2(220, 58)
	cancel_button.pressed.connect(close_profile_setup)
	name_buttons.add_child(cancel_button)

	var continue_button := make_menu_button("→", "LET'S GO", true)
	continue_button.custom_minimum_size = Vector2(260, 58)
	continue_button.pressed.connect(continue_from_name)
	name_buttons.add_child(continue_button)

	profile_gender_step = VBoxContainer.new()
	profile_gender_step.name = "GenderStep"
	profile_gender_step.add_theme_constant_override("separation", 14)
	profile_gender_step.visible = false
	profile_gender_step.size_flags_vertical = Control.SIZE_EXPAND_FILL
	steps.add_child(profile_gender_step)

	var gender_title := Label.new()
	gender_title.text = "PICK YOUR PLAYER CHARACTER"
	gender_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gender_title.add_theme_font_size_override("font_size", 32)
	gender_title.add_theme_color_override("font_color", CREAM)
	profile_gender_step.add_child(gender_title)

	var gender_hint := Label.new()
	gender_hint.text = "Meet both versions of your main character. Choose the one you want to take into your first year."
	gender_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gender_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gender_hint.add_theme_font_size_override("font_size", 16)
	gender_hint.add_theme_color_override("font_color", MUTED)
	profile_gender_step.add_child(gender_hint)

	var character_cards := HBoxContainer.new()
	character_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_cards.add_theme_constant_override("separation", 24)
	profile_gender_step.add_child(character_cards)

	character_cards.add_child(make_character_preview_card(
		"MALE MC",
		"res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/8-bit Sprite Models/MC/male mc.png",
		"res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Male-MC.png",
		"male"
	))
	character_cards.add_child(make_character_preview_card(
		"FEMALE MC",
		"res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/8-bit Sprite Models/MC/female mc.png",
		"res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png",
		"female"
	))

	var gender_buttons := HBoxContainer.new()
	gender_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	gender_buttons.add_theme_constant_override("separation", 18)
	profile_gender_step.add_child(gender_buttons)

	var back_button := make_menu_button("←", "BACK TO NAME")
	back_button.custom_minimum_size = Vector2(240, 52)
	back_button.pressed.connect(show_name_step)
	gender_buttons.add_child(back_button)

	var gender_cancel_button := make_menu_button("×", "CANCEL")
	gender_cancel_button.custom_minimum_size = Vector2(200, 52)
	gender_cancel_button.pressed.connect(close_profile_setup)
	gender_buttons.add_child(gender_cancel_button)


func make_profile_panel_style() -> StyleBoxFlat:
	var style := make_panel_style()
	style.bg_color = Color("#281A13")
	style.border_color = Color("#D5A15E")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 12)
	return style


func make_focused_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#352218")
	style.border_color = PALE_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func make_character_preview_card(title_text: String, sprite_sheet_path: String, portrait_path: String, chosen_gender: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#3A271D")
	card_style.border_color = Color("#94673F")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	var card_content := VBoxContainer.new()
	card_content.alignment = BoxContainer.ALIGNMENT_CENTER
	card_content.add_theme_constant_override("separation", 8)
	card.add_child(card_content)

	var character_title := Label.new()
	character_title.text = title_text
	character_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_title.add_theme_font_size_override("font_size", 24)
	character_title.add_theme_color_override("font_color", PALE_GOLD)
	character_title.add_theme_constant_override("letter_spacing", 2)
	card_content.add_child(character_title)

	var art_row := HBoxContainer.new()
	art_row.alignment = BoxContainer.ALIGNMENT_CENTER
	art_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_row.add_theme_constant_override("separation", 10)
	card_content.add_child(art_row)

	var pixel_column := VBoxContainer.new()
	pixel_column.alignment = BoxContainer.ALIGNMENT_CENTER
	pixel_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pixel_column.add_theme_constant_override("separation", 4)
	art_row.add_child(pixel_column)

	var pixel_label := Label.new()
	pixel_label.text = "IN-GAME SPRITE"
	pixel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pixel_label.add_theme_font_size_override("font_size", 11)
	pixel_label.add_theme_color_override("font_color", MUTED)
	pixel_column.add_child(pixel_label)

	var pixel_frame := PanelContainer.new()
	pixel_frame.custom_minimum_size = Vector2(120, 145)
	pixel_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pixel_style := StyleBoxFlat.new()
	pixel_style.bg_color = Color("#241811")
	pixel_style.border_color = Color("#775337")
	pixel_style.set_border_width_all(1)
	pixel_style.set_corner_radius_all(4)
	pixel_frame.add_theme_stylebox_override("panel", pixel_style)
	pixel_column.add_child(pixel_frame)

	var pixel_margin := CenterContainer.new()
	pixel_frame.add_child(pixel_margin)
	var pixel_sprite := TextureRect.new()
	pixel_sprite.custom_minimum_size = Vector2(92, 112)
	pixel_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pixel_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pixel_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite_sheet := load(sprite_sheet_path) as Texture2D
	if sprite_sheet != null:
		var idle_frame := AtlasTexture.new()
		idle_frame.atlas = sprite_sheet
		idle_frame.region = Rect2(0, 0, 64, 64)
		pixel_sprite.texture = idle_frame
	pixel_margin.add_child(pixel_sprite)

	var portrait_column := VBoxContainer.new()
	portrait_column.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_column.add_theme_constant_override("separation", 4)
	art_row.add_child(portrait_column)

	var portrait_label := Label.new()
	portrait_label.text = "32-BIT CHARACTER ART"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.add_theme_font_size_override("font_size", 11)
	portrait_label.add_theme_color_override("font_color", MUTED)
	portrait_column.add_child(portrait_label)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(190, 240)
	portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#241811")
	portrait_style.border_color = Color("#775337")
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(4)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	portrait_column.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(170, 220)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
	else:
		push_warning("32-bit player artwork not found: " + portrait_path)
	portrait_frame.add_child(portrait)

	var select_button := make_menu_button("✦", "PLAY AS " + title_text, chosen_gender == "female")
	select_button.custom_minimum_size = Vector2(0, 54)
	select_button.pressed.connect(choose_player_gender.bind(chosen_gender))
	card_content.add_child(select_button)
	return card

func open_profile_setup() -> void:
	profile_name_input.text = ""
	profile_name_error.visible = false
	show_name_step()
	profile_dimmer.visible = true
	profile_name_input.grab_focus()


func close_profile_setup() -> void:
	profile_dimmer.visible = false
	if not menu_buttons.is_empty():
		menu_buttons[0].grab_focus()


func show_name_step() -> void:
	profile_name_step.visible = true
	profile_gender_step.visible = false
	profile_name_error.visible = false
	profile_name_input.grab_focus()


func _on_profile_name_submitted(_submitted: String) -> void:
	continue_from_name()


func continue_from_name() -> void:
	var chosen_name := profile_name_input.text.strip_edges()
	if chosen_name.is_empty():
		profile_name_error.visible = true
		profile_name_input.grab_focus()
		return
	PlayerSetup.player_name = chosen_name
	profile_name_step.visible = false
	profile_gender_step.visible = true
	# Avoid relying on nested child indices; the character cards handle their own selection.


func choose_player_gender(chosen_gender: String) -> void:
	PlayerSetup.player_gender = chosen_gender
	profile_dimmer.visible = false
	begin_opening_cutscene()


func begin_opening_cutscene() -> void:
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
	dimmer.color = Color(0.0, 0.0, 0.0, 0.78)
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
	message.add_theme_color_override("font_color", CREAM)
	box.add_child(message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	var yes_button := make_menu_button("!", "YES, QUIT")
	yes_button.custom_minimum_size = Vector2(170, 46)
	yes_button.pressed.connect(confirm_quit)
	buttons.add_child(yes_button)

	cancel_quit_button = make_menu_button("×", "CANCEL")
	cancel_quit_button.custom_minimum_size = Vector2(170, 46)
	cancel_quit_button.pressed.connect(cancel_quit)
	buttons.add_child(cancel_quit_button)

	quit_dialog.set_meta("dimmer", dimmer)


func make_quit_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
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
