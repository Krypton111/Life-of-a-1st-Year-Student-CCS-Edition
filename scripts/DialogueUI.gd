extends Control

@export var typing_speed: float = 0.035
@export var character_slide_duration: float = 0.6
@export var dialogue_box_slide_duration: float = 0.5

@export var portrait_size_multiplier: float = 0.45

@export var speaker_scale: float = 1.06
@export var nonspeaker_scale: float = 0.95

@export var speaker_offset_y: float = -15.0
@export var nonspeaker_offset_y: float = 5.0

@export var highlight_duration: float = 0.2
@export var input_cooldown: float = 0.20

@export var bully_portrait_transition_duration: float = 0.35


var dialogue_data: Array = []
var current_line := 0

var is_typing := false
var is_entering := false
var is_advancing := false
var dialogue_ended := false
var input_enabled := false

var typing_id := 0
var last_input_time := -1.0
var ignore_input_until := 0

var left_base_position: Vector2
var right_base_position: Vector2
var dialogue_box_base_position: Vector2
var continue_prompt_base_position: Vector2

var left_base_scale: Vector2
var right_base_scale: Vector2

var multi_dialogue_active := false
var speaker_portraits: Dictionary = {}
var player_dialogue_texture: Texture2D
var current_bully_speaker := ""
var is_switching_bully := false


@onready var left_character: TextureRect = $LeftCharacter
@onready var right_character: TextureRect = $RightCharacter

@onready var dialogue_box: Control = $DialogueBox
@onready var speaker_name: Label = $DialogueBox/SpeakerName
@onready var dialogue_text: Label = $DialogueBox/DialogueText

@onready var continue_prompt: Label = $ContinuePrompt

var skip_all_button: Button
var skip_confirmation_panel: PanelContainer
var skip_confirmation_check: CheckButton
var skip_confirmation_yes: Button
var skip_confirmation_no: Button
var skip_dialogue_without_confirmation := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Apply the warm brown dialogue styling without requiring a scene rebuild.
	apply_cozy_dialogue_style()

	visible = false
	input_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	continue_prompt.visible = true

	create_skip_all_button()

	dialogue_box.visible = false
	if skip_all_button != null:
		skip_all_button.visible = false
	left_character.visible = false
	right_character.visible = false

	left_base_position = left_character.position
	right_base_position = right_character.position
	dialogue_box_base_position = dialogue_box.position
	continue_prompt_base_position = continue_prompt.position

	left_base_scale = left_character.scale
	right_base_scale = right_character.scale


func create_skip_all_button() -> void:
	if skip_all_button != null:
		return

	skip_all_button = Button.new()
	skip_all_button.name = "SkipAllButton"
	skip_all_button.text = "Skip All"
	skip_all_button.custom_minimum_size = Vector2(120.0, 38.0)
	skip_all_button.size = Vector2(120.0, 38.0)
	skip_all_button.position = Vector2(
		dialogue_box.size.x - 132.0,
		12.0
	)
	skip_all_button.focus_mode = Control.FOCUS_NONE
	skip_all_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_all_button.process_mode = Node.PROCESS_MODE_ALWAYS
	skip_all_button.z_index = 20

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#5A3A28")
	normal_style.border_color = Color("#B9824A")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#7A5035")
	hover_style.border_color = Color("#D8A15D")
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color("#3A281E")
	pressed_style.border_color = Color("#D8A15D")
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(8)

	skip_all_button.add_theme_stylebox_override("normal", normal_style)
	skip_all_button.add_theme_stylebox_override("hover", hover_style)
	skip_all_button.add_theme_stylebox_override("pressed", pressed_style)
	skip_all_button.add_theme_color_override("font_color", Color("#F6E7D2"))
	skip_all_button.add_theme_color_override("font_hover_color", Color("#FFF1D6"))
	skip_all_button.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))
	skip_all_button.add_theme_font_size_override("font_size", 14)

	skip_all_button.pressed.connect(request_skip_all)
	dialogue_box.add_child(skip_all_button)

	create_skip_confirmation_popup()


func create_skip_confirmation_popup() -> void:
	skip_confirmation_panel = PanelContainer.new()
	skip_confirmation_panel.name = "SkipConfirmationPanel"
	skip_confirmation_panel.set_anchors_preset(Control.PRESET_CENTER)
	skip_confirmation_panel.position = Vector2(-260.0, -155.0)
	skip_confirmation_panel.size = Vector2(520.0, 310.0)
	skip_confirmation_panel.visible = false
	skip_confirmation_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_confirmation_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	skip_confirmation_panel.z_index = 100

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#3A281E")
	panel_style.border_color = Color("#B9824A")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	panel_style.shadow_size = 16
	skip_confirmation_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(skip_confirmation_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	skip_confirmation_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Skip Dialogue?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#D8A15D"))
	box.add_child(title)

	var message := Label.new()
	message.text = "Are you sure you want to skip this dialogue?\nYou will miss out on important story lines."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(0.0, 68.0)
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color("#F6E7D2"))
	box.add_child(message)

	skip_confirmation_check = CheckButton.new()
	skip_confirmation_check.text = "Don't remind me again"
	skip_confirmation_check.focus_mode = Control.FOCUS_NONE
	skip_confirmation_check.add_theme_font_size_override("font_size", 15)
	skip_confirmation_check.add_theme_color_override("font_color", Color("#CFAF8C"))
	skip_confirmation_check.add_theme_color_override("font_hover_color", Color("#F6E7D2"))
	box.add_child(skip_confirmation_check)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	skip_confirmation_yes = Button.new()
	skip_confirmation_yes.text = "Yes, Skip"
	skip_confirmation_yes.custom_minimum_size = Vector2(130.0, 42.0)
	skip_confirmation_yes.focus_mode = Control.FOCUS_ALL
	style_skip_confirmation_button(skip_confirmation_yes)
	skip_confirmation_yes.pressed.connect(confirm_skip_all)
	buttons.add_child(skip_confirmation_yes)

	skip_confirmation_no = Button.new()
	skip_confirmation_no.text = "No"
	skip_confirmation_no.custom_minimum_size = Vector2(130.0, 42.0)
	skip_confirmation_no.focus_mode = Control.FOCUS_ALL
	style_skip_confirmation_button(skip_confirmation_no)
	skip_confirmation_no.pressed.connect(cancel_skip_all)
	buttons.add_child(skip_confirmation_no)


func style_skip_confirmation_button(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#5A3A28")
	normal_style.border_color = Color("#B9824A")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#7A5035")
	hover_style.border_color = Color("#D8A15D")
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color("#3A281E")
	pressed_style.border_color = Color("#D8A15D")
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(8)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color("#F6E7D2"))
	button.add_theme_color_override("font_hover_color", Color("#FFF1D6"))
	button.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))


func request_skip_all() -> void:
	if dialogue_ended:
		return

	if skip_dialogue_without_confirmation:
		perform_skip_all()
		return

	# Keep the dialogue active behind the confirmation popup.
	input_enabled = false
	skip_confirmation_check.button_pressed = false
	skip_confirmation_panel.visible = true
	skip_confirmation_yes.grab_focus()


func confirm_skip_all() -> void:
	if skip_confirmation_check.button_pressed:
		skip_dialogue_without_confirmation = true

	skip_confirmation_panel.visible = false
	perform_skip_all()


func cancel_skip_all() -> void:
	skip_confirmation_panel.visible = false
	input_enabled = true


func perform_skip_all() -> void:
	if dialogue_ended:
		return

	# One confirmation click ends the entire current dialogue immediately,
	# regardless of typing, entrance animation, or portrait transitions.
	typing_id += 1
	is_typing = false
	is_entering = false
	is_switching_bully = false
	input_enabled = false
	end_dialogue()


func apply_cozy_dialogue_style() -> void:

	if dialogue_box == null:
		return

	var background := dialogue_box.get_node_or_null(
		"CozyDialogueBackground"
	) as Panel

	if background == null:

		background = Panel.new()
		background.name = "CozyDialogueBackground"
		background.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.z_index = -10
		dialogue_box.add_child(background)

	var accent_bar := dialogue_box.get_node_or_null(
		"CozyDialogueAccent"
	) as ColorRect

	if accent_bar == null:

		accent_bar = ColorRect.new()
		accent_bar.name = "CozyDialogueAccent"
		accent_bar.position = Vector2(0.0, 0.0)
		accent_bar.size = Vector2(dialogue_box.size.x, 6.0)
		accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dialogue_box.add_child(accent_bar)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#3A281E")
	panel_style.border_color = Color("#B9824A")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.44)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0.0, 5.0)
	panel_style.anti_aliasing = true

	background.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	accent_bar.color = Color("#D8A15D")

	speaker_name.add_theme_font_size_override("font_size", 20)
	speaker_name.add_theme_color_override(
		"font_color",
		Color("#D8A15D")
	)
	speaker_name.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.36)
	)
	speaker_name.add_theme_constant_override("shadow_offset_x", 1)
	speaker_name.add_theme_constant_override("shadow_offset_y", 2)

	dialogue_text.add_theme_font_size_override("font_size", 18)
	dialogue_text.add_theme_color_override(
		"font_color",
		Color("#F6E7D2")
	)

	continue_prompt.add_theme_font_size_override("font_size", 13)
	continue_prompt.add_theme_color_override(
		"font_color",
		Color("#CFAF8C")
	)

	dialogue_box.move_child(background, 0)
	dialogue_box.move_child(accent_bar, 1)


func start_dialogue(
	data: Array,
	left_texture: Texture2D,
	right_texture: Texture2D,
	multi_mode: bool = false,
	multi_portraits: Dictionary = {},
	multi_player_texture: Texture2D = null
) -> void:

	# "Don't remind me again" applies only to this dialogue set.
	skip_dialogue_without_confirmation = false

	dialogue_data = data
	current_line = 0

	is_typing = false
	is_entering = true
	is_advancing = false
	dialogue_ended = false
	input_enabled = false

	typing_id += 1

	last_input_time = Time.get_ticks_msec() / 1000.0
	ignore_input_until = Time.get_ticks_msec() + 500

	multi_dialogue_active = multi_mode
	speaker_portraits = multi_portraits.duplicate()

	if multi_player_texture != null:
		player_dialogue_texture = multi_player_texture
	else:
		player_dialogue_texture = left_texture

	# The PLAYER is always on the LEFT.
	# The NPC is always on the RIGHT.
	if multi_dialogue_active:
		left_character.texture = player_dialogue_texture
		right_character.texture = right_texture
	else:
		left_character.texture = right_texture
		right_character.texture = left_texture

	left_character.position = left_base_position
	right_character.position = right_base_position

	left_character.scale = left_base_scale
	right_character.scale = right_base_scale

	left_character.modulate = Color.WHITE
	right_character.modulate = Color.WHITE

	left_character.visible = true
	right_character.visible = true
	dialogue_box.visible = true

	if skip_all_button != null:
		skip_all_button.visible = true
	if skip_confirmation_panel != null:
		skip_confirmation_panel.visible = false

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var final_x := dialogue_box_base_position.x

	var viewport_height := get_viewport_rect().size.y
	var box_height := dialogue_box.size.y
	var bottom_margin := 40.0

	var final_y := viewport_height - box_height - bottom_margin

	var box_final_position := Vector2(
		final_x,
		final_y
	)

	left_character.position = Vector2(
		-left_character.size.x - 50.0,
		left_base_position.y
	)

	right_character.position = Vector2(
		get_viewport_rect().size.x + 50.0,
		right_base_position.y
	)

	dialogue_box.position = Vector2(
		final_x,
		final_y + box_height + 50.0
	)

	continue_prompt.position = Vector2(
		continue_prompt_base_position.x,
		continue_prompt_base_position.y + dialogue_box.position.y - dialogue_box_base_position.y
	)

	await play_entrance_animation(
		left_base_position,
		right_base_position,
		box_final_position
	)

	if dialogue_ended:
		return

	await get_tree().create_timer(0.15, false).timeout

	if dialogue_ended:
		return

	is_entering = false
	input_enabled = true

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await show_line()


func start_multi_dialogue(
	data: Array,
	portraits: Dictionary,
	player_texture: Texture2D
) -> void:

	var first_bully_texture: Texture2D = null
	var first_bully_speaker := ""

	for line in data:
		var speaker: String = str(line["speaker"])

		if speaker != "Player" and portraits.has(speaker):
			first_bully_speaker = speaker
			first_bully_texture = portraits[speaker]
			break

	# A multi-dialogue can also be a player-only monologue. In that case,
	# there is no NPC portrait to find, so fall back to the normal dialogue path.
	if first_bully_texture == null:
		start_dialogue(
			data,
			player_texture,
			player_texture,
			false,
			{},
			player_texture
		)
		return

	current_bully_speaker = first_bully_speaker
	is_switching_bully = false

	multi_dialogue_active = true
	speaker_portraits = portraits.duplicate()
	player_dialogue_texture = player_texture

	start_dialogue(
		data,
		player_texture,
		first_bully_texture,
		true,
		portraits,
		player_texture
	)


func play_entrance_animation(
	left_final: Vector2,
	right_final: Vector2,
	box_final: Vector2
) -> void:

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		left_character,
		"position",
		left_final,
		character_slide_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		right_character,
		"position",
		right_final,
		character_slide_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		dialogue_box,
		"position",
		box_final,
		dialogue_box_slide_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	var continue_prompt_final := Vector2(
		continue_prompt_base_position.x,
		continue_prompt_base_position.y + box_final.y - dialogue_box_base_position.y
	)

	tween.tween_property(
		continue_prompt,
		"position",
		continue_prompt_final,
		dialogue_box_slide_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished


func show_line() -> void:

	if dialogue_ended:
		return

	if current_line >= dialogue_data.size():
		end_dialogue()
		return

	var line = dialogue_data[current_line]

	var speaker: String = str(line["speaker"])
	var text: String = str(line["text"])

	# Make the actual in-game characters face one another whenever a dialogue line begins.
	if DialogueManager.has_method("face_dialogue_participants"):
		DialogueManager.face_dialogue_participants(speaker)

	if multi_dialogue_active:
		await handle_multi_portrait_change(speaker)

	if dialogue_ended:
		return

	# Change the speaker name only after the portrait transition finishes.
	# This prevents the name from showing the next speaker while the previous
	# character is still leaving the dialogue screen.
	speaker_name.text = speaker

	update_character_highlight(speaker)

	start_typing(text)


func handle_multi_portrait_change(speaker: String) -> void:

	if speaker == "Player":
		return

	if not speaker_portraits.has(speaker):
		return

	if speaker == current_bully_speaker:
		return

	is_switching_bully = true
	input_enabled = false

	var exit_position := Vector2(
		get_viewport_rect().size.x + 50.0,
		right_base_position.y
	)

	var enter_position := Vector2(
		get_viewport_rect().size.x + 50.0,
		right_base_position.y
	)

	right_character.position = right_base_position

	var exit_tween := create_tween()

	exit_tween.set_trans(Tween.TRANS_QUAD)
	exit_tween.set_ease(Tween.EASE_IN)

	exit_tween.tween_property(
		right_character,
		"position",
		exit_position,
		bully_portrait_transition_duration
	)

	await exit_tween.finished

	if dialogue_ended:
		return

	right_character.texture = speaker_portraits[speaker]

	right_character.position = enter_position
	right_character.scale = right_base_scale
	right_character.modulate = Color.WHITE
	right_character.visible = true

	var enter_tween := create_tween()

	enter_tween.set_trans(Tween.TRANS_QUAD)
	enter_tween.set_ease(Tween.EASE_OUT)

	enter_tween.tween_property(
		right_character,
		"position",
		right_base_position,
		bully_portrait_transition_duration
	)

	await enter_tween.finished

	current_bully_speaker = speaker
	is_switching_bully = false
	input_enabled = true


func update_multi_character_portrait(speaker: String) -> void:

	# Player is always the LEFT portrait.
	if speaker == "Player":

		if player_dialogue_texture != null:
			left_character.texture = player_dialogue_texture

		return

	# Bullies are always the RIGHT portrait.
	if speaker_portraits.has(speaker):

		var texture: Texture2D = speaker_portraits[speaker]

		if texture != null:
			right_character.texture = texture


func update_character_highlight(speaker: String) -> void:

	var player_is_speaking := speaker == "Player"

	var left_target_position: Vector2
	var right_target_position: Vector2

	var left_target_scale: Vector2
	var right_target_scale: Vector2

	var left_target_modulate: Color
	var right_target_modulate: Color

	if player_is_speaking:

		left_target_position = left_base_position + Vector2(
			0,
			speaker_offset_y
		)

		right_target_position = right_base_position + Vector2(
			0,
			nonspeaker_offset_y
		)

		left_target_scale = left_base_scale * speaker_scale
		right_target_scale = right_base_scale * nonspeaker_scale

		left_target_modulate = Color.WHITE

		right_target_modulate = Color(
			0.4,
			0.4,
			0.4,
			1.0
		)

	else:

		left_target_position = left_base_position + Vector2(
			0,
			nonspeaker_offset_y
		)

		right_target_position = right_base_position + Vector2(
			0,
			speaker_offset_y
		)

		left_target_scale = left_base_scale * nonspeaker_scale
		right_target_scale = right_base_scale * speaker_scale

		left_target_modulate = Color(
			0.4,
			0.4,
			0.4,
			1.0
		)

		right_target_modulate = Color.WHITE

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		left_character,
		"position",
		left_target_position,
		highlight_duration
	)

	tween.tween_property(
		left_character,
		"scale",
		left_target_scale,
		highlight_duration
	)

	tween.tween_property(
		left_character,
		"modulate",
		left_target_modulate,
		highlight_duration
	)

	tween.tween_property(
		right_character,
		"position",
		right_target_position,
		highlight_duration
	)

	tween.tween_property(
		right_character,
		"scale",
		right_target_scale,
		highlight_duration
	)

	tween.tween_property(
		right_character,
		"modulate",
		right_target_modulate,
		highlight_duration
	)


func start_typing(full_text: String) -> void:

	is_typing = true

	typing_id += 1

	var my_typing_id := typing_id

	dialogue_text.text = ""

	for i in range(full_text.length()):

		if my_typing_id != typing_id:
			return

		if dialogue_ended:
			return

		dialogue_text.text = full_text.substr(
			0,
			i + 1
		)

		await get_tree().create_timer(
			typing_speed,
			false
		).timeout

	if my_typing_id != typing_id:
		return

	if dialogue_ended:
		return

	is_typing = false


func _input(event) -> void:

	if dialogue_ended:
		return

	if not input_enabled:
		return

	if is_entering:
		return

	if is_switching_bully:
		return

	if Time.get_ticks_msec() < ignore_input_until:
		return

	var current_time := Time.get_ticks_msec() / 1000.0

	if last_input_time >= 0.0 and current_time - last_input_time < input_cooldown:
		return

	var activate := false

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				activate = true

	elif event is InputEventKey:

		if event.keycode == KEY_SPACE:
			if event.pressed and not event.echo:
				activate = true

	if not activate:
		return

	get_viewport().set_input_as_handled()

	last_input_time = current_time

	handle_dialogue_input()


func handle_dialogue_input() -> void:

	if dialogue_ended:
		return

	if is_switching_bully:
		return

	if is_typing:

		# SKIP THE TYPEWRITER EFFECT.
		typing_id += 1

		var line = dialogue_data[current_line]

		dialogue_text.text = str(
			line["text"]
		)

		is_typing = false

		return

	advance_to_next_line()


func advance_to_next_line() -> void:

	if dialogue_ended:
		return

	if is_advancing:
		return

	is_advancing = true

	current_line += 1

	if current_line >= dialogue_data.size():

		is_advancing = false

		end_dialogue()

		return

	await show_line()

	is_advancing = false


func end_dialogue() -> void:

	if dialogue_ended:
		return

	dialogue_ended = true

	is_typing = false
	is_entering = false
	is_advancing = false
	input_enabled = false
	is_switching_bully = false

	typing_id += 1

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	await play_exit_animation()

	visible = false

	dialogue_box.visible = false
	if skip_all_button != null:
		skip_all_button.visible = false
	if skip_confirmation_panel != null:
		skip_confirmation_panel.visible = false
	left_character.visible = false
	right_character.visible = false

	# RESET EVERYTHING FOR THE NEXT DIALOGUE.
	left_character.position = left_base_position
	right_character.position = right_base_position

	left_character.scale = left_base_scale
	right_character.scale = right_base_scale

	dialogue_box.position = dialogue_box_base_position
	continue_prompt.position = continue_prompt_base_position

	left_character.modulate = Color.WHITE
	right_character.modulate = Color.WHITE

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	multi_dialogue_active = false
	speaker_portraits.clear()
	player_dialogue_texture = null
	current_bully_speaker = ""
	is_switching_bully = false

	DialogueManager.end_dialogue()


func play_exit_animation() -> void:

	var left_end_position := Vector2(
		-left_character.size.x - 50.0,
		left_base_position.y
	)

	var right_end_position := Vector2(
		get_viewport_rect().size.x + 50.0,
		right_base_position.y
	)

	var box_end_position := Vector2(
		dialogue_box.position.x,
		dialogue_box.position.y + dialogue_box.size.y + 50.0
	)

	var continue_prompt_end_position := Vector2(
		continue_prompt_base_position.x,
		continue_prompt_base_position.y + box_end_position.y - dialogue_box_base_position.y
	)

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		left_character,
		"position",
		left_end_position,
		character_slide_duration
	)

	tween.tween_property(
		right_character,
		"position",
		right_end_position,
		character_slide_duration
	)

	tween.tween_property(
		dialogue_box,
		"position",
		box_end_position,
		dialogue_box_slide_duration
	)

	tween.tween_property(
		continue_prompt,
		"position",
		continue_prompt_end_position,
		dialogue_box_slide_duration
	)

	await tween.finished
