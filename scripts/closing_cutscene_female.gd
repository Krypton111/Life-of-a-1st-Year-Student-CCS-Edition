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
var is_closing_cutscene := false

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
		"text": "The classroom that once
		felt ordinary suddenly felt like
		a place I didn’t want to leave."
	},

	{
		"image": "op3_p4",
		"text": "And then, just like
		that, Senior High
		School was over."
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
# OPENING VOICE-OVER NARRATION
# Key = zero-based panel index. Panels with no narration are intentionally omitted.
# "You got this!" (op1_p4) is intentionally excluded.
# =========================================
var narration_player: AudioStreamPlayer

# Independent narration volumes in decibels. Adjust these separately.
@export_range(-80.0, 24.0, 1.0) var female_narration_volume_db: float = 0.0

var female_narration_audio: Dictionary = {}
var closing_narration_batches: Array = [
	[
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 1/Image 1 - 1.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 1/Image 1 - 2.mp3"
	],
	[
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 2/Image 2 - 1.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 2/Image 2 - 2.mp3"
	],
	[
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 3/Image 3 - 1.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 3/Image 3 - 2.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 3/Image 3 - 3.mp3"
	],
	[
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/Image 4 - 1.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/image 4 - 2.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/Image 4 - 3.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/Image 4 - 4.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/Image 4 - 5.mp3",
		"res://GAME ASSETS_/Misc/NARRATION/CLOSING/FEMALE/IMAGE 4/Image 4 - 6 END.mp3"
	]
]
var closing_narration_batch_index := -1
var closing_narration_clip_index := 0

func load_female_narration_audio() -> void:
	# Female clips are numbered continuously across the four subfolders:
	# 1-6, 7-12, 13-18, and 19-24. Files are named simply "1.mp3",
	# "2.mp3", etc. Keep the existing panel-to-clip mapping.
	var clip_panels := {
		0: 1, 1: 2, 2: 3, 4: 4, 5: 5,
		6: 6, 7: 7, 8: 8, 9: 9, 10: 10, 11: 11,
		12: 12, 14: 13, 15: 14, 17: 15,
		18: 16, 19: 17, 20: 18, 21: 19, 22: 20, 23: 21
	}
	for panel_index in clip_panels:
		var clip_number: int = int(clip_panels[panel_index])
		# The repository's actual MP3 placement has three boundary files
		# in the next folder: 6 is under 7-12, 12 under 13-18,
		# and 16 under 19-24. Match the real asset locations explicitly.
		var folder := ""
		if clip_number <= 5:
			folder = "1-6"
		elif clip_number <= 11:
			folder = "7-12"
		elif clip_number <= 15:
			folder = "13-18"
		else:
			folder = "19-24"

		var clip_path := "res://GAME ASSETS_/Misc/NARRATION/INTRO/FEMALE/intro panels %s/%d.mp3" % [folder, clip_number]
		if not ResourceLoader.exists(clip_path):
			push_warning("Female narration file not found: " + clip_path)
			continue

		var stream := load(clip_path) as AudioStream
		if stream == null:
			push_warning("Female narration file could not be loaded as AudioStream: " + clip_path)
			continue

		female_narration_audio[panel_index] = stream


var narration_audio: Dictionary = female_narration_audio


# =========================================
# READY
# =========================================

func _ready():

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# This script is exclusively for the closing cutscene.
	is_closing_cutscene = true

	# Loop the cutscene background music continuously.
	# The scene already provides a BackgroundMusic AudioStreamPlayer.
	var background_music := get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	if background_music != null:
		if background_music.stream is AudioStreamMP3:
			(background_music.stream as AudioStreamMP3).loop = true
		if not background_music.playing:
			background_music.play()

	next_button.pressed.connect(_on_closing_next_pressed)

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

	# This script is dedicated to the female closing cutscene.
	load_female_narration_audio()
	narration_audio = female_narration_audio

	# Dedicated female narration player and independent volume setting.
	narration_player = AudioStreamPlayer.new()
	narration_player.name = "NarrationPlayer"
	narration_player.bus = "Master"
	narration_player.process_mode = Node.PROCESS_MODE_ALWAYS
	narration_player.volume_db = female_narration_volume_db
	add_child(narration_player)
	narration_player.finished.connect(_on_narration_clip_finished)

	# Keep Click to Continue visible
	continue_text.visible = true

	# Fade the entire closing cutscene in
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

	# Some cutscene scenes intentionally keep only the first six dialogue
	# labels. Missing labels should not stop the remaining panels from playing.
	var dialogue_node: Label = get_dialogue_node(current_panel)

	# Show current panel
	if panel_node == null:
		panel_animating = false
		push_warning("Cutscene panel is missing for index %d." % current_panel)
		return
	panel_node.visible = true
	panel_node.modulate.a = 0.0

	# Show dialogue only when this panel has a dialogue label.
	if dialogue_node != null:
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

	# Opening narration is panel-specific. Closing narration is grouped into
	# continuous six-panel batches, with each folder's clips played in order.
	if is_closing_cutscene:
		if current_panel % 6 == 0:
			start_closing_narration(int(current_panel / 6))
	elif narration_audio.has(current_panel):
		narration_player.stream = narration_audio[current_panel]
		narration_player.play()
	else:
		narration_player.stop()

	# Automatically advance through the six panels over the full narration duration.
	if is_closing_cutscene:
		_schedule_closing_auto_advance(current_panel)

	# Panels without a dialogue label simply display the artwork.
	if dialogue_node != null:
		type_text(dialogue_node, str(panel_data["text"]))
	else:
		is_typing = false
		continue_text.visible = true


# =========================================
# CLOSING CUTSCENE NARRATION (FEMALE)
# =========================================

func start_closing_narration(batch_index: int) -> void:
	if narration_player == null:
		return
	if batch_index < 0 or batch_index >= closing_narration_batches.size():
		return

	# Avoid restarting the same batch if the first panel is shown again.
	if closing_narration_batch_index == batch_index and narration_player.playing:
		return

	narration_player.stop()
	closing_narration_batch_index = batch_index
	closing_narration_clip_index = 0
	play_next_closing_narration_clip()


func play_next_closing_narration_clip() -> void:
	if not is_closing_cutscene or narration_player == null:
		return
	if closing_narration_batch_index < 0 or closing_narration_batch_index >= closing_narration_batches.size():
		return

	var clips: Array = closing_narration_batches[closing_narration_batch_index]
	if closing_narration_clip_index >= clips.size():
		return

	var clip_path: String = str(clips[closing_narration_clip_index])
	if not ResourceLoader.exists(clip_path):
		push_warning("Female closing narration file not found: " + clip_path)
		closing_narration_clip_index += 1
		play_next_closing_narration_clip()
		return

	var stream := load(clip_path) as AudioStream
	if stream == null:
		push_warning("Female closing narration could not be loaded as an AudioStream: " + clip_path)
		closing_narration_clip_index += 1
		play_next_closing_narration_clip()
		return

	narration_player.stop()
	narration_player.stream = stream
	narration_player.stream_paused = false
	narration_player.play()
	print("[Closing narration - female] Requested: ", clip_path,
		" | playing=", narration_player.playing,
		" | volume_db=", narration_player.volume_db,
		" | bus=", narration_player.bus)


func _on_narration_clip_finished() -> void:
	if not is_closing_cutscene:
		return
	# Do not continue into another batch if the player already moved on.
	if int(current_panel / 6) != closing_narration_batch_index:
		return
	closing_narration_clip_index += 1
	play_next_closing_narration_clip()


# =========================================
# GET PANEL NODE
# =========================================

func get_panel_node(index: int) -> Control:
	if index < 0 or index >= panels.size():
		return null

	var cutscene_number := int(index / 6) + 1
	var panel_number := int(index % 6) + 1
	var panel_name := "op%d_p%d" % [cutscene_number, panel_number]

	return get_node_or_null(panel_name) as Control


func get_dialogue_node(index: int) -> Label:
	if is_closing_cutscene:
		return null
	if index < 0 or index >= panels.size():
		return null

	return get_node_or_null("DialogueText%d" % (index + 1)) as Label


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

func _get_closing_batch_duration(batch_index: int) -> float:
	if batch_index < 0 or batch_index >= closing_narration_batches.size():
		return 0.0

	var total_duration := 0.0
	var clips: Array = closing_narration_batches[batch_index]
	for clip_path in clips:
		var path := str(clip_path)
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStream
		if stream != null:
			total_duration += stream.get_length()

	return total_duration


func _schedule_closing_auto_advance(panel_index: int) -> void:
	# The last image of each six-image batch must wait for a manual click.
	# This prevents the cutscene from automatically entering the next batch
	# while the player is skipping through the current batch.
	if panel_index % 6 == 5:
		return

	var batch_index := int(panel_index / 6)
	var batch_duration := _get_closing_batch_duration(batch_index)
	if batch_duration <= 0.0:
		return

	# Share the complete batch narration duration across its six images.
	# Account for the next image's fade-in so the sequence stays close to narration length.
	var panel_delay := maxf(0.1, (batch_duration / 6.0) - panel_fade_duration)
	_auto_advance_closing_panel_after_delay(panel_index, batch_index, panel_delay)


func _auto_advance_closing_panel_after_delay(panel_index: int, batch_index: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	# A manual click, scene exit, or another panel transition invalidates this timer.
	if not is_inside_tree() or not is_closing_cutscene:
		return
	if current_panel != panel_index or int(current_panel / 6) != batch_index:
		return
	if changing_page or panel_animating:
		return

	_on_closing_next_pressed()


func _on_closing_next_pressed() -> void:
	# Dedicated closing-cutscene controls: advance one image on each click.
	# There is no dialogue-typing phase in the closing cutscene.
	if changing_page or panel_animating:
		return

	current_panel += 1

	if current_panel >= panels.size():
		finish_closing_cutscene()
		return

	if current_panel % 6 == 0:
		if narration_player != null:
			narration_player.stop()
		closing_narration_batch_index = -1
		closing_narration_clip_index = 0
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

		var panel_node := get_panel_node(i)
		if panel_node != null:
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

		var dialogue_node := get_dialogue_node(i)
		if dialogue_node != null:
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

		var panel_node := get_panel_node(i)
		var dialogue_node := get_dialogue_node(i)

		if panel_node != null:
			panel_node.visible = false
			panel_node.modulate.a = 1.0

		if dialogue_node != null:
			dialogue_node.visible = false
			dialogue_node.modulate.a = 1.0

	# Allow new panel to start
	changing_page = false

	show_panel()


# =========================================
# FINISH OPENING
# =========================================

func finish_closing_cutscene() -> void:
	if narration_player != null:
		narration_player.stop()

	continue_text.visible = false
	next_button.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	await FadeManager.change_scene_with_fade("res://scenes/ui/MainMenu.tscn")
