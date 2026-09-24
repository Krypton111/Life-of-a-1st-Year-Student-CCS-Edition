extends Control

@onready var question_text: Label = $notebook/QuestionText
@onready var question_number_label: Label = $notebook/QuestionNumberLabel
@onready var answer_input: LineEdit = $notebook/AnswerInput
@onready var submit_button: Button = $notebook/SubmitButton
@onready var feedback_label: Label = $notebook/FeedbackLabel

@onready var result_panel: Panel = $notebook/ResultPanel
@onready var result_title: Label = $notebook/ResultPanel/ResultTitle
@onready var score_label: Label = $notebook/ResultPanel/ScoreLabel
@onready var continue_button: Button = $notebook/ResultPanel/ContinueButton

var current_question: int = 0
var score: int = 0
var processing_answer: bool = false

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

	submit_button.pressed.connect(_on_submit_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)

	result_panel.visible = false

	show_question()


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
		Color.WHITE
	)

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
			Color.GREEN
		)
	else:
		feedback_label.text = (
			"Correct answer: %s"
			% question["answer_display"]
		)

		feedback_label.add_theme_color_override(
			"font_color",
			Color.RED
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
