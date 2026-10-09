extends Control

const OPENING_SCENE := "res://scenes/main_level_scenes/cutscenes/opening_cutscene.tscn"
const GOLD := Color("#E6AD63")
const PALE_GOLD := Color("#FFE1A8")
const CREAM := Color("#FFF0D8")
const MUTED := Color("#D8BEA1")
const PANEL := Color(0.15, 0.095, 0.065, 0.96)
const SCHOOL_ASSETS := "res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/"
const MC_ASSET := "res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png"
const MALE_MC_ASSET := "res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Male-MC.png"
const MENU_MUSIC_PATH := "res://GAME ASSETS_/Misc/Music/school hallway.mp3"

var pause_menu: CanvasLayer
var quit_dialog: PanelContainer
var quit_button: Button
var cancel_quit_button: Button
var menu_buttons: Array[Button] = []
var menu_music: AudioStreamPlayer
var button_click_player: AudioStreamPlayer

var profile_dimmer: ColorRect
var profile_dialog: PanelContainer
var profile_name_input: LineEdit
var profile_name_error: Label
var profile_name_step: VBoxContainer
var profile_gender_step: VBoxContainer

var character_dialogue_panel: PanelContainer
var character_dialogue_name: Label
var character_dialogue_text: Label
var character_dialogue_tween: Tween
var character_dialogue_indices: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	setup_menu_audio()
	build_menu()
	build_character_art()
	build_character_dialogue_ui()
	build_profile_setup()
	animate_menu_intro()
	pause_menu = get_node("PauseMenu") as CanvasLayer
	if pause_menu != null:
		pause_menu.set("main_menu_mode", true)
	queue_redraw()


func _draw() -> void:
	# Smooth cream gradient, rendered as one continuous shader-free blend.
	var w := size.x
	var h := size.y
	var top_color := Color("#FFF8E9")
	var middle_color := Color("#F5E8D2")
	var bottom_color := Color("#E7D2B5")

	# A fine per-pixel vertical blend avoids visible horizontal bands.
	for y in range(ceili(h)):
		var t := float(y) / maxf(h - 1.0, 1.0)
		var color: Color
		if t < 0.72:
			color = top_color.lerp(middle_color, t / 0.72)
		else:
			color = middle_color.lerp(bottom_color, (t - 0.72) / 0.28)
		draw_line(Vector2(0, y), Vector2(w, y), color, 1.0)

func setup_menu_audio() -> void:
	# Play the hallway ambience for as long as the main menu is open.
	menu_music = AudioStreamPlayer.new()
	menu_music.name = "MainMenuMusic"
	menu_music.volume_db = +2.0
	var music_stream := load(MENU_MUSIC_PATH) as AudioStreamMP3
	if music_stream != null:
		music_stream.loop = true
		menu_music.stream = music_stream
		add_child(menu_music)
		menu_music.play()
	else:
		push_warning("Main menu music could not be loaded: " + MENU_MUSIC_PATH)

	# A short, soft synthesized click avoids needing an extra sound asset.
	button_click_player = AudioStreamPlayer.new()
	button_click_player.name = "MenuButtonClick"
	button_click_player.volume_db = -8.0
	button_click_player.stream = make_button_click_sound()
	add_child(button_click_player)


func make_button_click_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.055
	var sample_count := int(sample_rate * duration)
	var pcm_data := PackedByteArray()
	pcm_data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / sample_rate
		var progress := t / duration
		var frequency := lerpf(1450.0, 720.0, progress)
		var envelope := exp(-t * 72.0)
		var sample := sin(TAU * frequency * t) * envelope * 0.22
		var pcm := int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm_data[i * 2] = pcm & 0xff
		pcm_data[i * 2 + 1] = (pcm >> 8) & 0xff

	var click := AudioStreamWAV.new()
	click.format = AudioStreamWAV.FORMAT_16_BITS
	click.mix_rate = sample_rate
	click.stereo = false
	click.data = pcm_data
	return click


func _play_typewriter_sound() -> void:
	# Generate a tiny, muted mechanical tap so no extra asset is required.
	var sample_rate := 22050
	var duration := 0.025
	var sample_count := int(sample_rate * duration)
	var pcm_data := PackedByteArray()
	pcm_data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / sample_rate
		var envelope := exp(-t * 155.0)
		var noise := sin(TAU * 1730.0 * t) * 0.45 + sin(TAU * 2310.0 * t) * 0.25
		var sample := noise * envelope * 0.12
		var pcm := int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm_data[i * 2] = pcm & 0xff
		pcm_data[i * 2 + 1] = (pcm >> 8) & 0xff

	var type_sound := AudioStreamWAV.new()
	type_sound.format = AudioStreamWAV.FORMAT_16_BITS
	type_sound.mix_rate = sample_rate
	type_sound.stereo = false
	type_sound.data = pcm_data

	var player := AudioStreamPlayer.new()
	player.name = "TypewriterKeySound"
	player.stream = type_sound
	player.volume_db = -17.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _play_button_click() -> void:
	if is_instance_valid(button_click_player):
		button_click_player.stop()
		button_click_player.play()


func build_menu() -> void:
	var left_panel := PanelContainer.new()
	left_panel.name = "MenuPanel"
	left_panel.position = Vector2(105, 76)
	left_panel.size = Vector2(635, 925)
	left_panel.add_theme_stylebox_override("panel", make_panel_style())
	add_child(left_panel)
	left_panel.modulate.a = 0.0
	left_panel.position.y += 24
	var panel_tween := create_tween()
	panel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_tween.set_parallel(true)
	panel_tween.tween_property(left_panel, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(left_panel, "position:y", 76.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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
	add_character(SCHOOL_ASSETS + "Profs/Charles/Charles.png", Vector2(350, 220), Vector2(235, 490), 0, 0.78)
	add_character(SCHOOL_ASSETS + "Profs/Joyz/Joyz.png", Vector2(570, 115), Vector2(225, 490), 0, 0.72)
	add_character(SCHOOL_ASSETS + "Tina/tina.png", Vector2(1030, 190), Vector2(225, 485), 0, 0.83)
	add_character(SCHOOL_ASSETS + "Bullies/Joe/Joe.png", Vector2(1250, 210), Vector2(230, 495), 0, 0.7)

	add_character("res://GAME ASSETS_/Cafe (Sus! Marya & Hosep Cafe)/Character Sprites/32-bit Character Models/Gelo (Ex Lover or smth)/gelo.png", Vector2(820, 120), Vector2(225, 485), 0, 0.9)

	# Front row: a staggered friend group, with the player character as the
	# visual anchor. Slight overlaps make the group feel gathered, not lined up.
	add_character(SCHOOL_ASSETS + "Friends/Nathaly/Nathaly.png", Vector2(250, 440), Vector2(275, 545), 2)
	add_character(SCHOOL_ASSETS + "Friends/Janssen/Janssen.png", Vector2(420, 465), Vector2(260, 520), 2)
	# Keep both main characters side by side in the foreground.
	add_character(MALE_MC_ASSET, Vector2(870, 395), Vector2(285, 620), 4)
	add_character(MC_ASSET, Vector2(625, 365), Vector2(315, 660), 3)
	add_character(SCHOOL_ASSETS + "Friends/Kairi/Kairi.png", Vector2(1300, 435), Vector2(270, 550), 2)
	add_character(SCHOOL_ASSETS + "Friends/Kerwin/Kerwin.png", Vector2(1135, 445), Vector2(265, 540), 2)

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

	var character := TextureButton.new()
	character.name = "CharacterArt_" + path.get_file().get_basename()
	character.texture_normal = texture
	character.position = at
	character.size = dimensions
	character.z_index = z_layer
	character.modulate = Color(1.0, 1.0, 1.0, opacity)
	character.ignore_texture_size = true
	character.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_STOP
	character.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Only opaque sprite pixels receive clicks, so transparent parts don't block menu buttons.
	var click_mask := BitMap.new()
	click_mask.create_from_image_alpha(texture.get_image())
	character.texture_click_mask = click_mask
	character.set_meta("dialogue_key", path.get_file().get_basename().to_lower())
	character.gui_input.connect(_on_character_gui_input.bind(character))
	add_child(character)
	# Characters softly fade in and float by a few pixels for a calm, living menu.
	var final_position := character.position
	character.position.y += 18
	character.modulate.a = 0.0
	var entrance := create_tween()
	entrance.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrance.set_parallel(true)
	entrance.tween_property(character, "position", final_position, 0.85 + float(z_layer) * 0.07).set_delay(float(get_child_count() % 7) * 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_property(character, "modulate:a", opacity, 0.75).set_delay(float(get_child_count() % 7) * 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var float_tween := create_tween()
	float_tween.set_loops()
	float_tween.tween_property(character, "position:y", final_position.y - 4.0, 2.4 + float(z_layer) * 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(character, "position:y", final_position.y + 3.0, 2.4 + float(z_layer) * 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func build_character_dialogue_ui() -> void:
	# A compact dialogue card appears over the artwork without covering the menu buttons.
	character_dialogue_panel = PanelContainer.new()
	character_dialogue_panel.name = "CharacterDialogue"
	character_dialogue_panel.position = Vector2(790, 850)
	character_dialogue_panel.size = Vector2(900, 132)
	character_dialogue_panel.z_index = 80
	character_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_dialogue_panel.modulate.a = 0.0
	character_dialogue_panel.visible = false
	character_dialogue_panel.add_theme_stylebox_override("panel", make_dialogue_panel_style())
	add_child(character_dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	character_dialogue_panel.add_child(margin)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 6)
	margin.add_child(dialogue_box)

	character_dialogue_name = Label.new()
	character_dialogue_name.add_theme_font_size_override("font_size", 16)
	character_dialogue_name.add_theme_color_override("font_color", PALE_GOLD)
	character_dialogue_name.add_theme_constant_override("letter_spacing", 2)
	dialogue_box.add_child(character_dialogue_name)

	character_dialogue_text = Label.new()
	character_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_dialogue_text.add_theme_font_size_override("font_size", 18)
	character_dialogue_text.add_theme_color_override("font_color", CREAM)
	character_dialogue_text.custom_minimum_size = Vector2(0, 54)
	dialogue_box.add_child(character_dialogue_text)


func make_dialogue_panel_style() -> StyleBoxFlat:
	var style := make_panel_style()
	style.bg_color = Color(0.13, 0.075, 0.045, 0.97)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 5)
	return style


func _on_character_gui_input(event: InputEvent, character: TextureButton) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var dialogue_key: String = str(character.get_meta("dialogue_key", ""))
	var dialogue := get_character_dialogue(dialogue_key)
	if dialogue.is_empty():
		return

	var next_index := int(character_dialogue_indices.get(dialogue_key, 0))
	var lines: Array = dialogue.get("lines", [])
	if lines.is_empty():
		return
	character_dialogue_indices[dialogue_key] = (next_index + 1) % lines.size()

	show_character_dialogue(str(dialogue.get("name", "Classmate")), str(lines[next_index]))
	character.accept_event()


func get_character_dialogue(dialogue_key: String) -> Dictionary:
	# Each character has their own voice; clicking them again cycles through their lines.
	var dialogue: Dictionary = {
		"charles": {
			"name": "SIR CHARLES",
			"lines": [
				"Discrete Mathematics rewards careful thinking. Guessing is not a strategy.",
				"Show your work, check your logic, and do not fear a difficult problem."
			]
		},
		"joyz": {
			"name": "MISS JOYZ",
			"lines": [
				"Hello, future developer! Remember: every bug is a chance to learn.",
				"Don't just make the code run. Understand why it works!"
			]
		},
		"tina": {
			"name": "TINA",
			"lines": [
				"Oh—hi. I hope this school year gives us a chance to start fresh.",
				"I'm still getting used to everything here... but I think I'll be okay."
			]
		},
		"joe": {
			"name": "JOE",
			"lines": [
				"Heh. Think you can keep up with me? We'll see about that.",
				"Relax, I'm only teasing. ...Mostly."
			]
		},
		"gelo": {
			"name": "GELO",
			"lines": [
				"Funny how one campus can make the past feel close again, huh?",
				"Some things are easier to leave unsaid. For now, anyway."
			]
		},
		"nathaly": {
			"name": "NATHALY",
			"lines": [
				"If first year gets overwhelming, remember you don't have to do it alone!",
				"New friends, new memories, and probably a few all-nighters. We've got this!"
			]
		},
		"janssen": {
			"name": "JANSSEN",
			"lines": [
				"Group project tip: bring snacks. Suddenly everybody becomes cooperative.",
				"I came for the degree. I stayed because the group chat is unhinged."
			]
		},
		"kairi": {
			"name": "KAIRI",
			"lines": [
				"Hi! Have you explored the campus yet? There's always something happening.",
				"Come on, let's make this school year one worth remembering!"
			]
		},
		"kerwin": {
			"name": "KERWIN",
			"lines": [
				"One more feature, one more bug. That's the developer life!",
				"If it works on my machine, that means we're halfway there... right?"
			]
		},
		"male-mc": {
			"name": "PLAYER",
			"lines": [
				"New semester. New faces. Let's see what this year has in store.",
				"Okay, deep breath. First year starts now."
			]
		},
		"female-mc": {
			"name": "PLAYER",
			"lines": [
				"New semester. New faces. Let's see what this year has in store.",
				"Okay, deep breath. First year starts now."
			]
		}
	}
	return dialogue.get(dialogue_key, {})


func show_character_dialogue(speaker: String, line: String) -> void:
	if not is_instance_valid(character_dialogue_panel):
		return

	if character_dialogue_tween and character_dialogue_tween.is_running():
		character_dialogue_tween.kill()

	character_dialogue_name.text = speaker
	character_dialogue_text.text = line
	character_dialogue_panel.visible = true
	character_dialogue_panel.modulate.a = 0.0
	character_dialogue_panel.scale = Vector2(0.97, 0.97)
	character_dialogue_panel.pivot_offset = character_dialogue_panel.size / 2.0

	character_dialogue_tween = create_tween()
	character_dialogue_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	character_dialogue_tween.set_parallel(true)
	character_dialogue_tween.tween_property(character_dialogue_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	character_dialogue_tween.tween_property(character_dialogue_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	character_dialogue_tween.set_parallel(false)
	character_dialogue_tween.tween_interval(3.0)
	character_dialogue_tween.tween_property(character_dialogue_panel, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	character_dialogue_tween.tween_callback(func(): character_dialogue_panel.visible = false)


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
	button.pivot_offset = Vector2(0, 29.5)
	button.mouse_entered.connect(_animate_button_hover.bind(button, true))
	button.mouse_exited.connect(_animate_button_hover.bind(button, false))
	button.pressed.connect(_play_button_click)
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


func animate_menu_intro() -> void:
	# Stagger the menu controls so the interface settles in after the artwork.
	for i in range(menu_buttons.size()):
		var button := menu_buttons[i]
		var final_position := button.position
		button.position.x -= 18
		button.modulate.a = 0.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(button, "position:x", final_position.x, 0.42).set_delay(0.22 + i * 0.075).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 1.0, 0.38).set_delay(0.22 + i * 0.075)

func _animate_button_hover(button: Button, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.025, 1.025) if hovered else Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color("#FFF0D8") if hovered else Color.WHITE, 0.16)

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
	profile_name_input.gui_input.connect(_on_player_name_gui_input)
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
	profile_dimmer.modulate.a = 0.0
	profile_dialog.scale = Vector2(0.96, 0.96)
	profile_dialog.pivot_offset = profile_dialog.size / 2.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(profile_dimmer, "modulate:a", 1.0, 0.22)
	tween.tween_property(profile_dialog, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	profile_name_input.grab_focus()


func close_profile_setup() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(profile_dimmer, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func(): profile_dimmer.visible = false)
	if not menu_buttons.is_empty():
		menu_buttons[0].grab_focus()


func show_name_step() -> void:
	profile_name_step.visible = true
	profile_gender_step.visible = false
	profile_name_error.visible = false
	profile_name_input.grab_focus()


func _on_player_name_gui_input(event: InputEvent) -> void:
	# Play a quiet typewriter tick for typed characters and deletion keys.
	# Ignore key-repeat events, shortcuts, and keys that do not edit the name.
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.ctrl_pressed or key_event.alt_pressed or key_event.meta_pressed:
		return
	if key_event.keycode in [KEY_BACKSPACE, KEY_DELETE]:
		_play_typewriter_sound()
		return
	if key_event.unicode > 0 and key_event.keycode not in [KEY_ENTER, KEY_KP_ENTER, KEY_TAB]:
		_play_typewriter_sound()


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
	dimmer.modulate.a = 0.0
	quit_dialog.scale = Vector2(0.94, 0.94)
	quit_dialog.pivot_offset = quit_dialog.size / 2.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.18)
	tween.tween_property(quit_dialog, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cancel_quit_button.grab_focus()


func cancel_quit() -> void:
	var dimmer := quit_dialog.get_meta("dimmer") as ColorRect
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dimmer, "modulate:a", 0.0, 0.14)
	tween.tween_callback(func(): dimmer.visible = false)
	quit_button.grab_focus()


func confirm_quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		var dimmer := quit_dialog.get_meta("dimmer") as ColorRect
		if dimmer.visible:
			cancel_quit()
			get_viewport().set_input_as_handled()
