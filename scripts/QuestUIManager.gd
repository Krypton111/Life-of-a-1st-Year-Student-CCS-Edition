extends CanvasLayer

# QUEST UI MANAGER
# This script creates one reusable quest tracker that stays on screen across scenes.
# Add this script as an Autoload named QuestUIManager.
# The existing per-scene QuestUI nodes are hidden automatically so they do not overlap.

const COCOA := Color("#3A281E")
const ESPRESSO := Color("#251913")
const WALNUT := Color("#5B3E2C")
const CARAMEL := Color("#B9824A")
const HONEY := Color("#D8A15D")
const CREAM := Color("#F6E7D2")
const MUTED_CREAM := Color("#D9C1A7")
const LOCKED := Color("#806956")
const CROSSED := Color("#8C7365")
const SAGE := Color("#A6B38B")

const PANEL_WIDTH: float = 390.0
const PANEL_MAX_HEIGHT: float = 610.0
const PANEL_MIN_HEIGHT: float = 360.0
const PANEL_RIGHT_MARGIN: float = 28.0
const PANEL_TOP_MARGIN: float = 18.0

var panel: Panel = null
var title_label: Label = null
var eyebrow_label: Label = null
var progress_label: Label = null
var scroll: ScrollContainer = null
var content: VBoxContainer = null
var root_control: Control = null

var parent_call_completed: bool = false
var baon_completed: bool = false
var friends_choice: int = 0
var bully_choice: int = 0
var bully_event_started: bool = false

var last_scene_path: String = ""
var last_state_signature: String = ""
var refresh_accumulator: float = 0.0

# Quest tracker animation state.
var panel_tween: Tween = null
var panel_hidden: bool = false
var cutscene_active: bool = false

const PANEL_SLIDE_DURATION: float = 0.40
const PANEL_SLIDE_EXTRA: float = 24.0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_ui()
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("refresh_ui")

func _process(delta: float) -> void:
	refresh_accumulator += delta
	if refresh_accumulator < 0.15:
		return
	refresh_accumulator = 0.0
	hide_legacy_quest_ui()
	refresh_ui()
	update_panel_visibility()

func build_ui() -> void:
	root_control = Control.new()
	root_control.name = "QuestUIRoot"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root_control)

	panel = Panel.new()
	panel.name = "QuestPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(COCOA.r, COCOA.g, COCOA.b, 0.97)
	panel_style.border_color = CARAMEL
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.44)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0.0, 6.0)
	panel_style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", panel_style)

	var accent := ColorRect.new()
	accent.name = "QuestAccent"
	accent.color = HONEY
	accent.position = Vector2.ZERO
	accent.size = Vector2(PANEL_WIDTH, 7.0)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent)

	eyebrow_label = Label.new()
	eyebrow_label.name = "Eyebrow"
	eyebrow_label.text = "TODAY'S OBJECTIVES"
	eyebrow_label.position = Vector2(20.0, 18.0)
	eyebrow_label.size = Vector2(PANEL_WIDTH - 40.0, 22.0)
	eyebrow_label.add_theme_font_size_override("font_size", 12)
	eyebrow_label.add_theme_color_override("font_color", HONEY)
	eyebrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(eyebrow_label)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "QUESTS"
	title_label.position = Vector2(20.0, 40.0)
	title_label.size = Vector2(PANEL_WIDTH - 40.0, 34.0)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", CREAM)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_label)

	progress_label = Label.new()
	progress_label.name = "Progress"
	progress_label.position = Vector2(20.0, 78.0)
	progress_label.size = Vector2(PANEL_WIDTH - 40.0, 22.0)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", MUTED_CREAM)
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(progress_label)

	var divider := ColorRect.new()
	divider.name = "HeaderDivider"
	divider.position = Vector2(20.0, 103.0)
	divider.size = Vector2(PANEL_WIDTH - 40.0, 2.0)
	divider.color = Color(HONEY.r, HONEY.g, HONEY.b, 0.28)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	scroll = ScrollContainer.new()
	scroll.name = "QuestScroll"
	scroll.position = Vector2(18.0, 114.0)
	scroll.size = Vector2(PANEL_WIDTH - 36.0, 400.0)
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.name = "QuestContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)

func _on_scene_changed() -> void:
	await get_tree().process_frame
	# Reset the tracker position whenever a new scene loads so it cannot remain
	# stuck off-screen because the previous scene ended during a locked state.
	if panel_tween != null and panel_tween.is_valid():
		panel_tween.kill()
	panel_hidden = false
	last_scene_path = ""
	last_state_signature = ""
	hide_legacy_quest_ui()
	refresh_ui()

func get_current_scene_path() -> String:
	var current := get_tree().current_scene
	if current == null:
		return ""
	return str(current.scene_file_path).to_lower()

func get_scene_kind(scene_path: String) -> String:
	if scene_path.contains("house_game_level") or scene_path.contains("house"):
		return "house"
	if scene_path.contains("bookstore"):
		return "bookstore"
	if scene_path.contains("comlab_challenge"):
		return "comlab_challenge"
	if scene_path.contains("maclab_challenge"):
		return "maclab_challenge"
	if scene_path.contains("lecture_room_challenge") or scene_path.contains("lecture_challenge"):
		return "lecture_challenge"
	if scene_path.contains("school"):
		return "school"
	if scene_path.contains("cafe"):
		return "cafe"
	return "default"

func refresh_ui() -> void:
	if panel == null or content == null:
		return
	var scene_path := get_current_scene_path()
	if scene_path == "":
		panel.visible = false
		return
	position_panel()
	hide_legacy_quest_ui()
	update_panel_visibility()
	var kind := get_scene_kind(scene_path)
	var signature := build_state_signature(kind)
	if scene_path == last_scene_path and signature == last_state_signature:
		return
	last_scene_path = scene_path
	last_state_signature = signature
	clear_content()
	panel.visible = true
	# Always restore the tracker when entering a normal gameplay scene.
	if not is_dialogue_active() and not cutscene_active:
		panel_hidden = false
		position_panel()
	match kind:
		"house":
			eyebrow_label.text = "MORNING ROUTINE"
			title_label.text = "GET READY FOR SCHOOL"
			progress_label.text = get_house_progress_text()
			build_house_quests()
		"bookstore":
			eyebrow_label.text = "TODAY'S SHOPPING LIST"
			title_label.text = "BOOKSTORE QUEST"
			progress_label.text = get_bookstore_progress_text()
			build_bookstore_quests()
		"school", "comlab_challenge", "maclab_challenge", "lecture_challenge":
			eyebrow_label.text = "TODAY'S SCHOOL OBJECTIVES"
			title_label.text = "SCHOOL DAY"
			progress_label.text = get_school_progress_text()
			build_school_quests()
		"cafe":
			eyebrow_label.text = "LATE DAY"
			title_label.text = "KEEP GOING"
			progress_label.text = "KEEP MOVING"
			build_cafe_quests()
		_:
			eyebrow_label.text = "TODAY'S OBJECTIVES"
			title_label.text = "QUESTS"
			progress_label.text = "CURRENT OBJECTIVE"
			build_default_quests()

func clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

func add_section_header(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", HONEY)
	label.custom_minimum_size = Vector2(0.0, 28.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

func add_quest(text_value: String, state: String = "active", indent: int = 0) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(0.0, 28.0)
	label.add_theme_font_size_override("normal_font_size", 15)
	label.add_theme_color_override("default_color", CREAM)
	var prefix := "☐ "
	var body := text_value
	var body_color := "#F6E7D2"
	match state:
		"done":
			prefix = "☑ "
			body_color = "#A6B38B"
		"crossed":
			prefix = "✕ "
			body = "[s]" + body + "[/s]"
			body_color = "#8C7365"
		"locked":
			prefix = "▣ "
			body_color = "#806956"
	var spaces := ""
	for i in range(indent):
		spaces += "    "
	label.text = spaces + "[color=" + body_color + "]" + prefix + body + "[/color]"
	content.add_child(label)

func build_house_quests() -> void:
	add_section_header("REQUIRED")

	var ready_state := "done" if parent_call_completed else "active"
	add_quest("Get Ready for School", ready_state)
	add_quest("Finish the morning call", ready_state, 1)

	# The baon is locked until the parent call is finished.
	var baon_state := "done" if baon_completed else ("locked" if not parent_call_completed else "active")
	add_quest("Get Your Baon", baon_state)

func build_school_quests() -> void:
	add_section_header("REQUIRED")

	var com_done: bool = bool(GameManager.get("quiz_completed"))
	var mac_done: bool = bool(GameManager.get("maclab_challenge_completed"))
	var lec_done: bool = bool(GameManager.get("lecture_challenge_completed"))

	var com_state := "done" if com_done else "active"
	var mac_state := "done" if mac_done else ("active" if com_done else "locked")
	var lec_state := "done" if lec_done else ("active" if mac_done else "locked")

	add_quest("Attend class at COMLAB 202", com_state)
	add_quest("Complete Programming Challenge", "done" if com_done else "active", 1)

	add_quest("Attend class at MAC LAB", mac_state)
	add_quest("Complete Digital Art Challenge", "done" if mac_done else ("active" if com_done else "locked"), 1)

	add_quest("Attend class at LECTURE ROOM", lec_state)
	add_quest("Complete Discrete Mathematics Challenge", "done" if lec_done else ("active" if mac_done else "locked"), 1)

	add_section_header("OPTIONAL")

	if friends_choice == 1:
		add_quest("Make Friends", "done")
	elif friends_choice == 2:
		add_quest("Make Friends", "crossed")
	else:
		add_quest("Make Friends", "active")

	if bully_event_started or bully_choice != 0:
		if bully_choice == 1:
			add_quest("Make Enemies", "crossed")
			add_quest("Play Along", "done")
		elif bully_choice == 2:
			add_quest("Make Enemies", "done")
			add_quest("Play Along", "crossed")
		else:
			add_quest("Make Enemies", "active")
			add_quest("Play Along", "active")

func build_bookstore_quests() -> void:
	add_section_header("REQUIRED ITEMS")
	add_quest("Yellow Pad Paper", "done" if bool(GameManager.get("bookstore_yellow_pad")) else "active")
	var pens: int = int(GameManager.get("bookstore_ballpens"))
	add_quest("Ballpens    %d/3" % min(pens, 3), "done" if pens >= 3 else "active")
	add_quest("Correction Tape", "done" if bool(GameManager.get("bookstore_correction_tape")) else "active")
	add_quest("Discrete Math Book", "done" if bool(GameManager.get("bookstore_discrete_math_book")) else "active")
	add_section_header("OPTIONAL")
	add_quest("Talk to the Friends", "done" if bool(GameManager.get("bookstore_talked_to_friends")) else "active")
	add_quest("Talk to Ate Libro", "done" if bool(GameManager.get("bookstore_talked_to_ate_libro")) else "active")
	add_quest("Talk to Kuya Libro", "done" if bool(GameManager.get("bookstore_talked_to_kuya_libro")) else "active")

func build_cafe_quests() -> void:
	add_section_header("CURRENT OBJECTIVE")
	add_quest("Finish your final conversation")

func build_default_quests() -> void:
	add_section_header("CURRENT OBJECTIVE")
	add_quest("Continue through your first day")

func get_house_progress_text() -> String:
	var done: int = 0
	if parent_call_completed: done += 1
	if baon_completed: done += 1
	return "MORNING PROGRESS   %d / 2" % done

func get_school_progress_text() -> String:
	var done: int = 0
	if bool(GameManager.get("quiz_completed")): done += 1
	if bool(GameManager.get("maclab_challenge_completed")): done += 1
	if bool(GameManager.get("lecture_challenge_completed")): done += 1
	return "CLASS PROGRESS   %d / 3" % done

func get_bookstore_progress_text() -> String:
	var done: int = 0
	if bool(GameManager.get("bookstore_yellow_pad")): done += 1
	if int(GameManager.get("bookstore_ballpens")) >= 3: done += 1
	if bool(GameManager.get("bookstore_correction_tape")): done += 1
	if bool(GameManager.get("bookstore_discrete_math_book")): done += 1
	return "SHOPPING PROGRESS   %d / 4" % done

func build_state_signature(kind: String) -> String:
	return str([
		kind,
		parent_call_completed,
		baon_completed,
		friends_choice,
		bully_choice,
		bully_event_started,
		bool(GameManager.get("quiz_completed")),
		bool(GameManager.get("maclab_challenge_completed")),
		bool(GameManager.get("lecture_challenge_completed")),
		bool(GameManager.get("bookstore_yellow_pad")),
		int(GameManager.get("bookstore_ballpens")),
		bool(GameManager.get("bookstore_correction_tape")),
		bool(GameManager.get("bookstore_discrete_math_book")),
		bool(GameManager.get("bookstore_talked_to_friends")),
		bool(GameManager.get("bookstore_talked_to_ate_libro")),
		bool(GameManager.get("bookstore_talked_to_kuya_libro"))
	])

func position_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_width: float = minf(PANEL_WIDTH, maxf(280.0, viewport_size.x - (PANEL_RIGHT_MARGIN * 2.0)))
	var panel_height: float = clampf(viewport_size.y * 0.67, PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT)
	var top_position: float = PANEL_TOP_MARGIN
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var top_bar := current_scene.find_child("TopBar", true, false) as Control
		if top_bar != null and top_bar.visible:
			top_position = maxf(top_position, top_bar.position.y + top_bar.size.y + 18.0)
	panel.size = Vector2(panel_width, panel_height)

	var normal_position := Vector2(
		viewport_size.x - panel_width - PANEL_RIGHT_MARGIN,
		top_position
	)
	var hidden_position := normal_position + Vector2(
		panel_width + PANEL_RIGHT_MARGIN + PANEL_SLIDE_EXTRA,
		0.0
	)

	# Keep the current X position while the slide tween is running.
	# This prevents the periodic UI refresh from snapping the panel instantly.
	if not panel_hidden:
		panel.position.x = normal_position.x
	elif panel_tween == null or not panel_tween.is_valid():
		panel.position.x = hidden_position.x

	panel.position.y = top_position
	var usable_width: float = panel_width - 36.0
	eyebrow_label.size.x = usable_width
	title_label.size.x = usable_width
	progress_label.size.x = usable_width
	scroll.size = Vector2(usable_width, maxf(180.0, panel_height - 132.0))
	var accent := panel.get_node_or_null("QuestAccent") as ColorRect
	if accent != null: accent.size.x = panel_width
	var divider := panel.get_node_or_null("HeaderDivider") as ColorRect
	if divider != null: divider.size.x = usable_width

func is_dialogue_active() -> bool:
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null:
		return false
	return bool(dialogue_manager.get("is_active"))

func update_panel_visibility() -> void:
	if panel == null or not panel.visible:
		return

	# Any moment when player controls are locked is treated as a cinematic/event
	# moment. This covers dialogue, challenges, bully encounters, scripted NPC
	# movement, choices, and other interactions without requiring every script
	# to manually animate the quest tracker.
	var player_locked := false
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null:
		player_locked = bool(game_manager.get("player_controls_locked"))

	var should_hide := player_locked or is_dialogue_active() or cutscene_active
	if should_hide == panel_hidden:
		return

	panel_hidden = should_hide

	if panel_tween != null and panel_tween.is_valid():
		panel_tween.kill()

	var viewport_size := get_viewport().get_visible_rect().size
	var panel_width := panel.size.x
	var normal_x := viewport_size.x - panel_width - PANEL_RIGHT_MARGIN
	var target_x := normal_x

	if panel_hidden:
		target_x = normal_x + panel_width + PANEL_RIGHT_MARGIN + PANEL_SLIDE_EXTRA

	panel_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	panel_tween.tween_property(panel, "position:x", target_x, PANEL_SLIDE_DURATION)

func start_cutscene() -> void:
	cutscene_active = true
	update_panel_visibility()

func end_cutscene() -> void:
	cutscene_active = false
	update_panel_visibility()

func hide_legacy_quest_ui() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	for node in current_scene.find_children("QuestUI", "Control", true, false):
		node.visible = false

func complete_parent_call() -> void:
	parent_call_completed = true
	last_state_signature = ""
	refresh_ui()

func complete_baon() -> void:
	baon_completed = true
	last_state_signature = ""
	refresh_ui()

func start_friends_choice() -> void:
	friends_choice = 0
	last_state_signature = ""
	refresh_ui()

func resolve_friends_choice(choice: int) -> void:
	friends_choice = choice
	last_state_signature = ""
	refresh_ui()

func start_bully_choice() -> void:
	bully_event_started = true
	bully_choice = 0
	last_state_signature = ""
	refresh_ui()

func resolve_bully_choice(choice: int) -> void:
	bully_event_started = true
	bully_choice = choice
	last_state_signature = ""
	refresh_ui()
