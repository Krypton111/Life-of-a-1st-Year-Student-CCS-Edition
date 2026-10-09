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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	build_menu()
	build_character_art()
	pause_menu = get_node("PauseMenu") as CanvasLayer
	if pause_menu != null:
		pause_menu.set("main_menu_mode", true)
	queue_redraw()


func _draw() -> void:
	# A twilight campus scene, drawn in crisp pixel-art-inspired layers.
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#4A3025"))
	draw_rect(Rect2(0, 0, w, h * 0.43), Color("#956344"))
	draw_rect(Rect2(0, h * 0.43, w, h * 0.22), Color("#B8794D"))
	draw_rect(Rect2(0, h * 0.65, w, h * 0.35), Color("#58664A"))

	# Distant dusk glow and moon.
	draw_circle(Vector2(w * 0.77, h * 0.22), h * 0.105, Color(0.93, 0.65, 0.39, 0.08))
	draw_circle(Vector2(w * 0.77, h * 0.22), h * 0.075, Color(0.96, 0.75, 0.50, 0.12))
	draw_circle(Vector2(w * 0.77, h * 0.22), h * 0.047, Color("#FFE2A3"))
	draw_circle(Vector2(w * 0.785, h * 0.205), h * 0.042, Color("#B8794D"))

	# Tiny stars / windows in the evening sky.
	for i in range(42):
		var px := fposmod(float(i * 173 + 71), w)
		var py := fposmod(float(i * 67 + 31), h * 0.46)
		var radius := 1.4 if i % 5 == 0 else 0.8
		draw_rect(Rect2(Vector2(px, py), Vector2(radius * 2.0, radius * 2.0)), Color(1.0, 0.86, 0.62, 0.72 if i % 5 == 0 else 0.35))

	# Campus building silhouettes.
	var far_buildings := [
		PackedVector2Array([Vector2(0, h * 0.54), Vector2(0, h * 0.43), Vector2(w * 0.08, h * 0.43), Vector2(w * 0.08, h * 0.54)]),
		PackedVector2Array([Vector2(w * 0.35, h * 0.56), Vector2(w * 0.35, h * 0.39), Vector2(w * 0.44, h * 0.39), Vector2(w * 0.44, h * 0.56)]),
		PackedVector2Array([Vector2(w * 0.86, h * 0.55), Vector2(w * 0.86, h * 0.40), Vector2(w, h * 0.40), Vector2(w, h * 0.55)])
	]
	for shape in far_buildings:
		draw_colored_polygon(shape, Color("#654735"))

	# Main university hall on the right side.
	var bx := w * 0.58
	var by := h * 0.38
	var bw := w * 0.34
	var bh := h * 0.34
	draw_rect(Rect2(bx, by + h * 0.06, bw, bh), Color("#4A3025"))
	draw_rect(Rect2(bx - 20, by + h * 0.04, bw + 40, h * 0.055), Color("#D99A55"))
	draw_rect(Rect2(bx + bw * 0.39, by - h * 0.035, bw * 0.22, h * 0.095), Color("#D99A55"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx + bw * 0.34, by - h * 0.035),
		Vector2(bx + bw * 0.5, by - h * 0.11),
		Vector2(bx + bw * 0.66, by - h * 0.035)
	]), Color("#F0C57A"))
	for row in range(3):
		for col in range(8):
			var wx := bx + 24 + col * (bw - 48) / 8.0
			var wy := by + h * 0.10 + row * h * 0.065
			draw_rect(Rect2(wx, wy, 18, 28), Color("#F2BC69", 0.8 if (row + col) % 3 != 0 else 0.28))
			draw_rect(Rect2(wx + 4, wy + 4, 10, 20), Color("#704B34"))

	# Foreground path, lawn, and a clean frame.
	draw_rect(Rect2(0, h * 0.83, w, h * 0.17), Color("#30231D"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.46, h), Vector2(w * 0.59, h * 0.83),
		Vector2(w * 0.82, h * 0.83), Vector2(w, h),
	]), Color("#6E5038"))
	draw_line(Vector2(24, 24), Vector2(w - 24, 24), Color(GOLD, 0.55), 2.0)
	draw_line(Vector2(24, h - 24), Vector2(w - 24, h - 24), Color(GOLD, 0.55), 2.0)
	draw_line(Vector2(24, 24), Vector2(24, h - 24), Color(GOLD, 0.55), 2.0)
	draw_line(Vector2(w - 24, 24), Vector2(w - 24, h - 24), Color(GOLD, 0.55), 2.0)


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
	add_character(SCHOOL_ASSETS + "Profs/Charles/Charles.png", Vector2(770, 330), Vector2(235, 490), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Profs/Joyz/Joyz.png", Vector2(1000, 295), Vector2(225, 490), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Bullies/Joe/Joe.png", Vector2(1370, 330), Vector2(225, 485), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Tina/tina.png", Vector2(1590, 320), Vector2(230, 495), 0, 0.78)

	# Front row: a staggered friend group, with the player character as the
	# visual anchor. Slight overlaps make the group feel gathered, not lined up.
	add_character(SCHOOL_ASSETS + "Friends/Nathaly/Nathaly.png", Vector2(765, 440), Vector2(275, 545), 2)
	add_character(SCHOOL_ASSETS + "Friends/Janssen/Janssen.png", Vector2(905, 465), Vector2(260, 520), 2)
	add_character(MC_ASSET, Vector2(1055, 365), Vector2(315, 660), 3)
	add_character(SCHOOL_ASSETS + "Friends/Kairi/Kairi.png", Vector2(1260, 435), Vector2(270, 550), 2)
	add_character(SCHOOL_ASSETS + "Friends/Kerwin/Kerwin.png", Vector2(1480, 445), Vector2(265, 540), 2)

	var character_caption := Label.new()
	character_caption.text = "YOUR PEOPLE. YOUR CHOICES. YOUR FIRST YEAR."
	character_caption.position = Vector2(830, 930)
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
