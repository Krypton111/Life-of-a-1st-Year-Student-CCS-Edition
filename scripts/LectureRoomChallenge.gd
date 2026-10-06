extends Control

@onready var question_text: Label = $notebook/QuestionText
@onready var question_number_label: Label = $notebook/QuestionNumberLabel
@onready var answer_input: LineEdit = $notebook/AnswerInput
@onready var submit_button: Button = $notebook/SubmitButton
@onready var feedback_label: Label = $notebook/FeedbackLabel
@onready var progress_bar: ProgressBar = $notebook/ProgressBar
@onready var notebook: TextureRect = $notebook
@onready var paper_answers: TextureRect = $PaperAnswers
@onready var notebook_drag_bar: Control = $notebook/DragBar
@onready var paper_drag_bar: Control = $PaperAnswers/DragBar

@onready var result_panel: Panel = $notebook/ResultPanel
@onready var result_title: Label = $notebook/ResultPanel/ResultTitle
@onready var score_label: Label = $notebook/ResultPanel/ScoreLabel
@onready var continue_button: Button = $notebook/ResultPanel/ContinueButton

var current_question: int = 0
var score: int = 0
var processing_answer: bool = false

# The guide appears only when the player went with the friends and
# completed the required bookstore material list.
var paper_answers_available: bool = false

var questions: Array[Dictionary] = [
	{
		"question": "What does the symbol ∧ mean?",
		"answers": ["and", "conjunction"],
		"answer_display": "AND / Conjunction"
	},
	{
		"question": "What does the symbol ∨ mean?",
		"answers": ["or", "disjunction"],
		"answer_display": "OR / Disjunction"
	},
	{
		"question": "What does the symbol ¬ mean?",
		"answers": ["not", "negation", "not p"],
		"answer_display": "NOT / Negation"
	},
	{
		"question": "What does the symbol → mean?",
		"answers": ["implies", "implication", "conditional"],
		"answer_display": "Implication / Conditional"
	},
	{
		"question": "What does the symbol ↔ mean?",
		"answers": ["biconditional", "if and only if", "iff"],
		"answer_display": "Biconditional / If and only if"
	},

	{
		"question": "What law is represented by p ∨ p = p?",
		"answers": ["idempotent law", "idempotent"],
		"answer_display": "Idempotent Law"
	},
	{
		"question": "What law is represented by p ∧ T = p?",
		"answers": ["identity law", "identity"],
		"answer_display": "Identity Law"
	},
	{
		"question": "What law is represented by p ∨ F = p?",
		"answers": ["identity law", "identity"],
		"answer_display": "Identity Law"
	},
	{
		"question": "What law is represented by p ∧ ¬p = F?",
		"answers": ["inverse law", "inverse"],
		"answer_display": "Inverse Law"
	},
	{
		"question": "What law is represented by ¬(p ∧ q) = ¬p ∨ ¬q?",
		"answers": ["de morgan's law", "de morgans law", "demorgan's law", "demorgans law", "de morgan", "demorgan"],
		"answer_display": "De Morgan's Law"
	},

	{
		"question": "Simplify: p ∨ p",
		"answers": ["p"],
		"answer_display": "p"
	},
	{
		"question": "Simplify: p ∧ p",
		"answers": ["p"],
		"answer_display": "p"
	},
	{
		"question": "Simplify: p ∨ F",
		"answers": ["p"],
		"answer_display": "p"
	},
	{
		"question": "Simplify: p ∧ T",
		"answers": ["p"],
		"answer_display": "p"
	},
	{
		"question": "Simplify: p ∨ ¬p",
		"answers": ["true", "t", "1"],
		"answer_display": "T / True"
	},
	{
		"question": "Simplify: p ∧ ¬p",
		"answers": ["false", "f", "0"],
		"answer_display": "F / False"
	},
	{
		"question": "Simplify: (p ∨ q) ∧ (p ∨ q)",
		"answers": ["p ∨ q", "p or q", "p+q"],
		"answer_display": "p ∨ q"
	},
	{
		"question": "Simplify: (p ∨ q) ∧ (¬p ∨ q)",
		"answers": ["q"],
		"answer_display": "q"
	},
	{
		"question": "Simplify: (p ∧ q) ∨ (p ∧ ¬q)",
		"answers": ["p"],
		"answer_display": "p"
	},
	{
		"question": "Simplify: ¬(p ∧ q) ∨ (p ∧ q)",
		"answers": ["true", "t", "1"],
		"answer_display": "T / True"
	}
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	if not answer_input.text_submitted.is_connected(_on_answer_submitted):
		answer_input.text_submitted.connect(_on_answer_submitted)

	result_panel.visible = false

	setup_answer_guide()
	setup_document_layer_clicks()

	show_question()


func setup_answer_guide() -> void:
	# The guide is a reward for taking the FRIENDS route to the bookstore
	# and actually buying the required materials.
	#
	# We intentionally check the individual GameManager purchase variables
	# instead of depending only on bookstore_completed. This makes the guide
	# appear as soon as the four required purchases are truly recorded.
	paper_answers_available = (
		GameManager.friends_bookstore_choice == 1
		and GameManager.bookstore_completed
		and GameManager.bookstore_yellow_pad
		and GameManager.bookstore_ballpens >= 3
		and GameManager.bookstore_correction_tape
		and GameManager.bookstore_discrete_math_book
	)

	paper_answers.visible = paper_answers_available

	if not paper_answers_available:
		return

	# The paper starts behind the notebook, but is deliberately offset so a
	# visible part of it remains exposed and can be clicked.
	paper_answers.position = Vector2(-500.0, -430.0)
	paper_answers.z_index = 1
	notebook.z_index = 2

	connect_document_input()


func connect_document_input() -> void:
	if paper_drag_bar != null:
		paper_drag_bar.mouse_filter = Control.MOUSE_FILTER_STOP
		paper_drag_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
		if not paper_drag_bar.gui_input.is_connected(_on_paper_drag_bar_gui_input):
			paper_drag_bar.gui_input.connect(_on_paper_drag_bar_gui_input)

	if paper_answers != null:
		paper_answers.mouse_filter = Control.MOUSE_FILTER_STOP
		if not paper_answers.gui_input.is_connected(_on_paper_gui_input):
			paper_answers.gui_input.connect(_on_paper_gui_input)

	if notebook_drag_bar != null:
		notebook_drag_bar.mouse_filter = Control.MOUSE_FILTER_STOP
		notebook_drag_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
		if not notebook_drag_bar.gui_input.is_connected(_on_notebook_drag_bar_gui_input):
			notebook_drag_bar.gui_input.connect(_on_notebook_drag_bar_gui_input)

	if notebook != null:
		notebook.mouse_filter = Control.MOUSE_FILTER_STOP
		if not notebook.gui_input.is_connected(_on_notebook_gui_input):
			notebook.gui_input.connect(_on_notebook_gui_input)


func setup_document_layer_clicks() -> void:
	# Input is connected in setup_answer_guide() after the route check.
	# Keep this function because the challenge startup calls it separately.
	if notebook_drag_bar != null:
		notebook_drag_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

	if paper_drag_bar != null:
		paper_drag_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE


func _on_paper_drag_bar_gui_input(event: InputEvent) -> void:
	if not paper_answers_available:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			move_document_to_front(paper_answers)


func _on_notebook_drag_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			move_document_to_front(notebook)


func _on_paper_gui_input(event: InputEvent) -> void:
	if not paper_answers_available:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			move_document_to_front(paper_answers)


func _on_notebook_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			move_document_to_front(notebook)


func move_document_to_front(document: Control) -> void:
	if document == null:
		return

	if document == notebook:
		notebook.z_index = 3
		paper_answers.z_index = 2
	else:
		paper_answers.z_index = 3
		notebook.z_index = 2


func show_question() -> void:
	if current_question >= questions.size():
		return

	processing_answer = false

	var question: Dictionary = questions[current_question]

	question_number_label.text = "Question %d / %d" % [
		current_question + 1,
		questions.size()
	]

	question_text.text = question["question"]

	answer_input.clear()
	answer_input.editable = true

	submit_button.disabled = false

	feedback_label.text = ""
	feedback_label.add_theme_color_override(
		"font_color",
		Color("#BCA58E")
	)

	progress_bar.value = (float(current_question) / float(questions.size())) * 100.0
	answer_input.grab_focus()


func _on_answer_submitted(_text: String) -> void:
	check_answer()


func _on_submit_pressed() -> void:
	check_answer()


func normalize_answer(answer: String) -> String:
	var normalized: String = answer.strip_edges().to_lower()

	normalized = normalized.replace(" ", "")
	normalized = normalized.replace("_", "")
	normalized = normalized.replace("-", "")
	normalized = normalized.replace("(", "")
	normalized = normalized.replace(")", "")

	return normalized


func check_answer() -> void:
	if processing_answer:
		return

	if current_question >= questions.size():
		return

	processing_answer = true

	var player_answer: String = normalize_answer(
		answer_input.text
	)

	var question: Dictionary = questions[current_question]
	var accepted_answers: Array = question["answers"]

	var correct: bool = false

	for accepted_answer in accepted_answers:
		if player_answer == normalize_answer(
			str(accepted_answer)
		):
			correct = true
			break

	submit_button.disabled = true
	answer_input.editable = false

	if correct:
		score += 1

		feedback_label.text = "Correct!"

		feedback_label.add_theme_color_override(
			"font_color",
			Color("#8FB9A8")
		)
	else:
		feedback_label.text = (
			"Correct answer: %s"
			% question["answer_display"]
		)

		feedback_label.add_theme_color_override(
			"font_color",
			Color("#D98F78")
		)

	current_question += 1

	await get_tree().create_timer(0.8).timeout

	if current_question >= questions.size():
		finish_challenge()
	else:
		show_question()


func finish_challenge() -> void:
	var final_score: int = roundi(
		float(score)
		/ float(questions.size())
		* 100.0
	)

	GameManager.lecture_performance_score = final_score
	progress_bar.value = 100.0

	result_title.text = "Challenge Complete!"
	score_label.text = "Final Score: %d%%" % final_score

	result_panel.visible = true

	submit_button.disabled = true
	answer_input.editable = false


func _on_continue_pressed() -> void:
	GameManager.lecture_challenge_completed = true
	GameManager.player_controls_locked = false

	await FadeManager.change_scene_with_fade(
		"res://scenes/main_level_scenes/Lecture Room.tscn"
	)
