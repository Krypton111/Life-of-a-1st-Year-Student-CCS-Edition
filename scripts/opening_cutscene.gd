extends Control


# =========================================
# SETTINGS
# =========================================

@export var typing_speed: float = 0.035
@export var panel_fade_duration: float = 0.6
@export var page_fade_duration: float = 0.8
@export var opening_fade_duration: float = 1.5


# =========================================
# STATE
# =========================================

var current_panel := 0

var is_typing := false
var typing_id := 0

var changing_page := false
var panel_animating := false


# =========================================
# NODE REFERENCES
# =========================================

@onready var continue_text = $ContinueText
@onready var next_button = $NextButton


# =========================================
# ALL 24 PANELS
# =========================================

var panels = [

	# =========================================
	# CUTSCENE 1
	# =========================================

	{
		"image": "op1_p1",
		"text": "Back then,
		life was simple."
	},

	{
		"image": "op1_p2",
		"text": "School was mostly about
		classes, friends, and trying
		to get through the day."
	},

	{
		"image": "op1_p3",
		"text": "Some days were stressful.
		Others were just fun."
	},

	{
		"image": "op1_p4",
		"text": "You got this!"
	},

	{
		"image": "op1_p5",
		"text": "There were exams, deadlines,
		sleepless nights, and moments when
		I wondered if I would make it."
	},

	{
		"image": "op1_p6",
		"text": "But somehow, those ordinary days
		became some of my favorite memories."
	},


	# =========================================
	# CUTSCENE 2
	# =========================================

	{
		"image": "op2_p1",
		"text": "When I got home,
		things were
		always quieter."
	},

	{
		"image": "op2_p2",
		"text": "Mom and Dad were almost
		always still at work."
	},

	{
		"image": "op2_p3",
		"text": "They worked long hours
		to provide for us."
	},

	{
		"image": "op2_p4",
		"text": "Most nights,
		I just study."
	},

	{
		"image": "op2_p5",
		"text": "Our conversations became
		small pieces of paper left
		on the table."
	},

	{
		"image": "op2_p6",
		"text": "They weren’t always there...
		but I knew they were doing
		everything they could for me."
	},


	# =========================================
	# CUTSCENE 3
	# =========================================

	{
		"image": "op3_p1",
		"text": "Then suddenly,
		the last days
		of Senior High
		School arrived."
	},

	{
		"image": "op3_p2",
		"text": " "
	},

	{
		"image": "op3_p3",
		"text": "The classroom that
		once felt ordinary
		suddenly felt like a place
		I didn’t want to leave."
	},

	{
		"image": "op3_p4",
		"text": "And then, just
		like that, Senior
		High School
		was over."
	},

	{
		"image": "op3_p5",
		"text": " "
	},

	{
		"image": "op3_p6",
		"text": "One chapter had ended.
		Now I had to figure out
		what came next."
	},


	# =========================================
	# CUTSCENE 4
	# =========================================

	{
		"image": "op4_p1",
		"text": "For the first time, I had
		no idea what tomorrow
		would look like."
	},

	{
		"image": "op4_p2",
		"text": "There were so many
		things I could become."
	},

	{
		"image": "op4_p3",
		"text": "I didn’t know exactly
		where life would take me."
	},

	{
		"image": "op4_p4",
		"text": "But I knew I
		wanted a future I
		could be proud of."
	},

	{
		"image": "op4_p5",
		"text": "A new place. New people.
		New challenges."
	},

	{
		"image": "op4_p6",
		"text": "This was it. The beginning
		of my college life."
	}
]


# =========================================
# READY
# =========================================

func _ready():

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	next_button.pressed.connect(_on_next_pressed)

	# Hide all panels and dialogue
	for i in range(1, 25):

		var cutscene_number = int((i - 1) / 6) + 1
		var panel_number = int((i - 1) % 6) + 1

		var panel_name = "op" + str(cutscene_number) + "_p" + str(panel_number)
		var dialogue_name = "DialogueText" + str(i)

		var panel_node = get_node_or_null(panel_name)
		var dialogue_node = get_node_or_null(dialogue_name)

		if panel_node:
			panel_node.visible = false
			panel_node.modulate.a = 1.0

		if dialogue_node:
			dialogue_node.visible = false
			dialogue_node.modulate.a = 1.0
			dialogue_node.text = ""

	# Keep Click to Continue visible
	continue_text.visible = true

	# Fade the entire opening in
	await FadeManager.fade_in(opening_fade_duration)

	# Show first panel
	show_panel()


# =========================================
# SHOW PANEL
# =========================================

func show_panel():

	# Prevent overlapping panel transitions
	if panel_animating:
		return

	panel_animating = true

	var panel_data = panels[current_panel]

	var panel_node = get_panel_node(current_panel)

	var dialogue_node = get_node(
		"DialogueText" + str(current_panel + 1)
	)

	# Show current panel
	panel_node.visible = true
	panel_node.modulate.a = 0.0

	# Show dialogue
	dialogue_node.visible = true
	dialogue_node.modulate.a = 1.0
	dialogue_node.text = ""

	continue_text.visible = true

	# Fade the panel in
	var tween = create_tween()

	tween.tween_property(
		panel_node,
		"modulate:a",
		1.0,
		panel_fade_duration
	)

	# Wait for fade to finish
	await tween.finished

	# Panel is now ready
	panel_animating = false

	# Start typing
	type_text(
		dialogue_node,
		panel_data["text"]
	)


# =========================================
# GET PANEL NODE
# =========================================

func get_panel_node(index: int) -> Control:

	var cutscene_number = int(index / 6) + 1
	var panel_number = int(index % 6) + 1

	var panel_name = (
		"op"
		+ str(cutscene_number)
		+ "_p"
		+ str(panel_number)
	)

	return get_node(panel_name)


# =========================================
# TYPEWRITER EFFECT
# =========================================

func type_text(label: Label, full_text: String):

	is_typing = true

	typing_id += 1

	var my_typing_id = typing_id

	label.text = ""

	for i in range(full_text.length()):

		# Stop this specific typing process
		# if another one has replaced it
		if my_typing_id != typing_id:
			return

		label.text = full_text.substr(
			0,
			i + 1
		)

		await get_tree().create_timer(
			typing_speed
		).timeout

	# Only this typing process can reach here
	if my_typing_id == typing_id:
		is_typing = false

		continue_text.visible = true


# =========================================
# NEXT BUTTON
# =========================================

func _on_next_pressed():

	# Ignore clicks while changing pages
	if changing_page:
		return

	# Ignore clicks while panel itself
	# is still fading in
	if panel_animating:
		return

	# If the text is still typing,
	# finish it completely.
	if is_typing:

		# Invalidate the current typing coroutine
		typing_id += 1

		var dialogue_node = get_node(
			"DialogueText" + str(current_panel + 1)
		)

		# IMPORTANT:
		# Set the FULL text immediately.
		dialogue_node.text = panels[current_panel]["text"]

		is_typing = false

		continue_text.visible = true

		return

	# Move to the next panel
	current_panel += 1

	# Check if all 24 panels are finished
	if current_panel >= panels.size():

		finish_opening()

		return

	# Every six panels = new cutscene page
	if current_panel % 6 == 0:

		change_page()

	else:

		show_panel()


# =========================================
# CHANGE SIX-PANEL PAGE
# =========================================

func change_page():

	if changing_page:
		return

	changing_page = true

	continue_text.visible = true

	var previous_page_start = current_panel - 6
	var previous_page_end = current_panel - 1

	var fade_tween = create_tween()

	# Fade out previous panels
	for i in range(
		previous_page_start,
		previous_page_end + 1
	):

		var panel_node = get_panel_node(i)

		fade_tween.parallel().tween_property(
			panel_node,
			"modulate:a",
			0.0,
			page_fade_duration
		)

	# Fade out previous dialogue
	for i in range(
		previous_page_start,
		previous_page_end + 1
	):

		var dialogue_node = get_node(
			"DialogueText" + str(i + 1)
		)

		fade_tween.parallel().tween_property(
			dialogue_node,
			"modulate:a",
			0.0,
			page_fade_duration
		)

	await fade_tween.finished

	# Hide previous page
	for i in range(
		previous_page_start,
		previous_page_end + 1
	):

		var panel_node = get_panel_node(i)

		var dialogue_node = get_node(
			"DialogueText" + str(i + 1)
		)

		panel_node.visible = false
		panel_node.modulate.a = 1.0

		dialogue_node.visible = false
		dialogue_node.modulate.a = 1.0

	# Allow new panel to start
	changing_page = false

	show_panel()


# =========================================
# FINISH OPENING
# =========================================

func finish_opening():

	continue_text.visible = false

	next_button.disabled = true

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Fade to black
	# Change to Cafe
	# Fade the Cafe in
	await FadeManager.change_scene_with_fade(
		"res://scenes/main_level_scenes/house_game_level.tscn"
	)
