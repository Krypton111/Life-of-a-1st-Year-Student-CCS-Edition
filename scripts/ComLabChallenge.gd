extends Control

var current_question := 0
var score := 0
var processing_answer := false

@onready var question_text = $browserquiz/QuestionText
@onready var answer1 = $browserquiz/Answer1
@onready var answer2 = $browserquiz/Answer2
@onready var answer3 = $browserquiz/Answer3
@onready var answer4 = $browserquiz/Answer4

@onready var answer1_text = $browserquiz/Answer1/Answer1Text
@onready var answer2_text = $browserquiz/Answer2/Answer2Text
@onready var answer3_text = $browserquiz/Answer3/Answer3Text
@onready var answer4_text = $browserquiz/Answer4/Answer4Text

@onready var correct_sound = $CorrectSound
@onready var wrong_sound = $WrongSound

var questions = [
	{
		"question": "What does HTML stand for?",
		"answers": [
			"HyperText Markup Language",
			"HighText Machine Language",
			"Hyperlink Text Management \n Language",
			"Home Tool Markup Language"
		],
		"correct": 0
	},
	{
		"question": "Which language is primarily used to \n style web pages?",
		"answers": [
			"Python",
			"CSS",
			"Java",
			"C++"
		],
		"correct": 1
	},
	{
		"question": "Which language is commonly used \n to add interactivity to web pages?",
		"answers": [
			"JavaScript",
			"HTML",
			"CSS",
			"SQL"
		],
		"correct": 0
	},
	{
		"question": "What does CPU stand for?",
		"answers": [
			"Central Processing Unit",
			"Computer Personal Unit",
			"Central Program Utility",
			"Computer Processing Utility"
		],
		"correct": 0
	},
	{
		"question": "Which of these is a programming \n language?",
		"answers": [
			"HTML",
			"Python",
			"HTTP",
			"Wi-Fi"
		],
		"correct": 1
	},
	{
		"question": "Which symbol is commonly used \n to start a comment in GDScript?",
		"answers": [
			"//",
			"<!--",
			"#",
			"**"
		],
		"correct": 2
	},
	{
		"question": "What does RAM stand for?",
		"answers": [
			"Random Access Memory",
			"Read Access Machine",
			"Rapid Application Memory",
			"Random Application Module"
		],
		"correct": 0
	},
	{
		"question": "Which data type stores true \n or false values?",
		"answers": [
			"String",
			"Integer",
			"Boolean",
			"Float"
		],
		"correct": 2
	},
	{
		"question": "Which keyword is used to \n define a function in GDScript?",
		"answers": [
			"function",
			"func",
			"define",
			"method"
		],
		"correct": 1
	},
	{
		"question": "Which engine are you currently \n using to develop this game?",
		"answers": [
			"Unity",
			"Unreal Engine",
			"Godot",
			"GameMaker"
		],
		"correct": 2
	}
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	answer1.pressed.connect(_on_answer1_pressed)
	answer2.pressed.connect(_on_answer2_pressed)
	answer3.pressed.connect(_on_answer3_pressed)
	answer4.pressed.connect(_on_answer4_pressed)

	show_question()

func show_question():
	if current_question >= questions.size():
		return

	var question = questions[current_question]

	question_text.text = question["question"]
	answer1_text.text = question["answers"][0]
	answer2_text.text = question["answers"][1]
	answer3_text.text = question["answers"][2]
	answer4_text.text = question["answers"][3]

	set_answer_buttons_enabled(true)

func _on_answer1_pressed():
	check_answer(0)

func _on_answer2_pressed():
	check_answer(1)

func _on_answer3_pressed():
	check_answer(2)

func _on_answer4_pressed():
	check_answer(3)

func set_answer_buttons_enabled(enabled: bool):
	answer1.disabled = not enabled
	answer2.disabled = not enabled
	answer3.disabled = not enabled
	answer4.disabled = not enabled

func check_answer(answer_index: int):
	if processing_answer or current_question >= questions.size():
		return

	processing_answer = true
	set_answer_buttons_enabled(false)

	var question = questions[current_question]
	var is_correct = answer_index == question["correct"]

	if is_correct:
		score += 1
		print("CORRECT!")
		if correct_sound:
			correct_sound.play()
	else:
		print("WRONG!")
		if wrong_sound:
			wrong_sound.play()

	print("Question: ", current_question + 1)
	print("Score: ", score)

	current_question += 1

	if current_question >= questions.size():
		finish_challenge()
		return

	show_question()
	processing_answer = false

func finish_challenge():
	print("Challenge complete!")
	print("Final Score: ", score, "/", questions.size())

	GameManager.comlab_performance_score = (
		float(score) / float(questions.size()) * 100.0
	)
	GameManager.quiz_completed = true

	await FadeManager.change_scene_with_fade(
		"res://scenes/main_level_scenes/comlab202.tscn"
	)
