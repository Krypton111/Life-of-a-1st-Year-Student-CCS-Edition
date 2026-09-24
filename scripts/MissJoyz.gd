extends CharacterBody2D


func _ready():
	add_to_group("npc")


func interact():

	if DialogueManager.is_active:
		return

	if not GameManager.miss_joyz_first_dialogue_done:
		start_first_dialogue()
		return

	if GameManager.quiz_completed and not GameManager.miss_joyz_second_dialogue_done:
		start_second_dialogue()
		return

	print("Miss Joyz has nothing else to say.")


func start_first_dialogue():

	var dialogue = [
		{
			"speaker": "Miss Joyz",
			"text": "You're late."
		},
		{
			"speaker": "Player",
			"text": "I'm sorry, ma'am."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Do you know what time our class started?"
		},
		{
			"speaker": "Player",
			"text": "Around eight, ma'am..."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Around eight? Class started at eight sharp."
		},
		{
			"speaker": "Player",
			"text": "I'm really sorry, ma'am. I had trouble finding the room."
		},
		{
			"speaker": "Miss Joyz",
			"text": "That's not an excuse. You should have arrived earlier and given yourself enough time to find your classroom."
		},
		{
			"speaker": "Player",
			"text": "Yes, ma'am. I understand."
		},
		{
			"speaker": "Miss Joyz",
			"text": "This is college now. You need to start taking responsibility for your time."
		},
		{
			"speaker": "Player",
			"text": "Yes, ma'am. It won't happen again."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Good. At least you understand."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Now, instead of standing there, go ahead and take a seat."
		},
		{
			"speaker": "Player",
			"text": "Yes, ma'am."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Before we begin today's lesson, I'll have you take a quick quiz."
		},
		{
			"speaker": "Player",
			"text": "A quiz already?"
		},
		{
			"speaker": "Miss Joyz",
			"text": "Don't worry. It's not graded."
		},
		{
			"speaker": "Miss Joyz",
			"text": "I just want to see where your programming skills are right now."
		},
		{
			"speaker": "Player",
			"text": "Okay. I'll do my best."
		},
		{
			"speaker": "Miss Joyz",
			"text": "That's all I'm asking for."
		},
		{
			"speaker": "Miss Joyz",
			"text": "Go to the computer in front of you and start the activity."
		},
		{
			"speaker": "Player",
			"text": "Yes, ma'am."
		}
	]

	DialogueManager.start_dialogue(
		dialogue,
		preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Joyz/Joyz.png"),
		preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
	)

	await DialogueManager.dialogue_finished

	GameManager.miss_joyz_first_dialogue_done = true
	GameManager.computer_unlocked = true


func start_second_dialogue():

	var performance := get_performance_level(GameManager.comlab_performance_score)
	var dialogue := get_performance_dialogue(performance)

	DialogueManager.start_dialogue(
		dialogue,
		preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Joyz/Joyz.png"),
		preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
	)

	await DialogueManager.dialogue_finished

	GameManager.miss_joyz_second_dialogue_done = true


func get_performance_level(score: float) -> String:
	if score >= 90.0:
		return "Excellent"
	if score >= 80.0:
		return "Very Good"
	if score >= 60.0:
		return "Average"
	if score >= 30.0:
		return "Poor"
	return "Very Poor"


func get_performance_dialogue(performance: String) -> Array:
	match performance:
		"Excellent":
			return [
				{"speaker": "Miss Joyz", "text": "You're back. I have reviewed your quiz results."},
				{"speaker": "Player", "text": "Yes, ma'am. How did I do?"},
				{"speaker": "Miss Joyz", "text": "Excellent. You demonstrated a strong understanding of the programming fundamentals covered in the activity."},
				{"speaker": "Player", "text": "I'm glad to hear that, ma'am."},
				{"speaker": "Miss Joyz", "text": "You should be. But do not mistake a strong result for permission to stop studying."},
				{"speaker": "Player", "text": "Of course, ma'am."},
				{"speaker": "Miss Joyz", "text": "The next step is to apply those fundamentals. Knowing what HTML, CSS, JavaScript, variables, and data types are is different from using them correctly in a project."},
				{"speaker": "Player", "text": "So I should focus on applying what I know."},
				{"speaker": "Miss Joyz", "text": "Exactly. Follow instructions carefully, organize your code, and test your work instead of assuming it will run correctly the first time."},
				{"speaker": "Player", "text": "I'll keep that in mind."},
				{"speaker": "Miss Joyz", "text": "Good. Your preparation is showing. Keep that same discipline when the lessons become more demanding."},
				{"speaker": "Player", "text": "Yes, ma'am. Thank you."},
				{"speaker": "Miss Joyz", "text": "You're welcome. Keep learning, and do not become overconfident."}
			]
		"Very Good":
			return [
				{"speaker": "Miss Joyz", "text": "You're back. I checked your quiz."},
				{"speaker": "Player", "text": "How did I do, ma'am?"},
				{"speaker": "Miss Joyz", "text": "Very good. You understood most of the fundamentals and made only a few mistakes."},
				{"speaker": "Player", "text": "I wasn't completely sure about some of the questions."},
				{"speaker": "Miss Joyz", "text": "That is normal. What I want you to do now is identify which topics caused hesitation."},
				{"speaker": "Player", "text": "I think I need to review some of the basic terminology."},
				{"speaker": "Miss Joyz", "text": "Then review it before the next activity. Do not wait until an assessment forces you to remember it."},
				{"speaker": "Player", "text": "Yes, ma'am."},
				{"speaker": "Miss Joyz", "text": "Also remember to read instructions completely. A student can know the answer and still lose time by misunderstanding what the task is asking."},
				{"speaker": "Player", "text": "I'll be more careful with that."},
				{"speaker": "Miss Joyz", "text": "Good. Your foundation is developing well. Keep reviewing and start practicing by writing small programs instead of only reading examples."},
				{"speaker": "Player", "text": "I'll try that."},
				{"speaker": "Miss Joyz", "text": "That's the right next step. Keep improving."}
			]
		"Average":
			return [
				{"speaker": "Miss Joyz", "text": "You're back. I have your quiz result."},
				{"speaker": "Player", "text": "Was it okay, ma'am?"},
				{"speaker": "Miss Joyz", "text": "It was average. You have some of the fundamentals, but there are several areas that need more preparation."},
				{"speaker": "Player", "text": "I wasn't sure about some of the programming questions."},
				{"speaker": "Miss Joyz", "text": "I noticed. That usually means the concepts have not become familiar enough yet."},
				{"speaker": "Player", "text": "What should I review first?"},
				{"speaker": "Miss Joyz", "text": "Start with the basics. Review common programming terms, data types, and the role of HTML, CSS, and JavaScript. Do not skip the simple topics just because they look easy."},
				{"speaker": "Player", "text": "I tend to jump ahead when I think something is simple."},
				{"speaker": "Miss Joyz", "text": "And that can create gaps later. Programming builds on previous concepts, so weak fundamentals eventually make harder lessons confusing."},
				{"speaker": "Player", "text": "I'll slow down and review them properly."},
				{"speaker": "Miss Joyz", "text": "Good. Also, practice following instructions exactly. Read the problem, identify what is being asked, then work through it."},
				{"speaker": "Player", "text": "Understood, ma'am."},
				{"speaker": "Miss Joyz", "text": "This result is a reminder to prepare more, not a reason to be discouraged. You can improve with consistent practice."},
				{"speaker": "Player", "text": "Thank you, ma'am. I'll work on it."},
				{"speaker": "Miss Joyz", "text": "Good. Keep practicing."}
			]
		"Poor":
			return [
				{"speaker": "Miss Joyz", "text": "You're back. I checked your quiz results."},
				{"speaker": "Player", "text": "I don't think I did very well, ma'am."},
				{"speaker": "Miss Joyz", "text": "Your result was below the expected level. We need to work on your preparation before moving too quickly into harder programming topics."},
				{"speaker": "Player", "text": "I realized I was guessing on several questions."},
				{"speaker": "Miss Joyz", "text": "That is exactly what I want you to avoid. Guessing may get you through one question, but it will not help you build programming skills."},
				{"speaker": "Player", "text": "So I need to study the basics again."},
				{"speaker": "Miss Joyz", "text": "Yes. Review the terminology, understand what each tool or language is used for, and practice one concept at a time."},
				{"speaker": "Player", "text": "Should I start writing programs right away?"},
				{"speaker": "Miss Joyz", "text": "Start small. Write short examples, make mistakes, read the errors, and fix them. That process is more valuable than memorizing answers."},
				{"speaker": "Player", "text": "That makes sense."},
				{"speaker": "Miss Joyz", "text": "And prepare before class. Read the instructions, review your notes, and ask questions when something is unclear."},
				{"speaker": "Player", "text": "I'll make sure to prepare better next time."},
				{"speaker": "Miss Joyz", "text": "Good. Improvement starts with recognizing what needs work."},
				{"speaker": "Player", "text": "Thank you for telling me directly, ma'am."},
				{"speaker": "Miss Joyz", "text": "You're welcome. Now put in the work."}
			]
		_:
			return [
				{"speaker": "Miss Joyz", "text": "You're back. I reviewed your quiz."},
				{"speaker": "Player", "text": "I know it was bad, ma'am."},
				{"speaker": "Miss Joyz", "text": "Your result shows that you need to rebuild your programming fundamentals before moving ahead too quickly."},
				{"speaker": "Player", "text": "I barely knew some of the answers."},
				{"speaker": "Miss Joyz", "text": "Then we start there. There is no shame in reviewing the basics, but you must take responsibility for doing the work."},
				{"speaker": "Player", "text": "Where do I begin?"},
				{"speaker": "Miss Joyz", "text": "Begin with the terms you encountered today. Learn what they mean, what they are used for, and how they connect to one another."},
				{"speaker": "Player", "text": "Should I memorize all of them?"},
				{"speaker": "Miss Joyz", "text": "No. Understand them. Memorization without understanding will not help you solve programming problems."},
				{"speaker": "Player", "text": "I'll review them and practice."},
				{"speaker": "Miss Joyz", "text": "Good. Write very small programs. Follow each instruction carefully. When something breaks, find out why instead of simply starting over."},
				{"speaker": "Player", "text": "I'll try to be more patient with the process."},
				{"speaker": "Miss Joyz", "text": "That will help. Your current result tells you where to begin. It does not have to determine where you finish."},
				{"speaker": "Player", "text": "Thank you, ma'am. I'll do better."},
				{"speaker": "Miss Joyz", "text": "Good. Then start preparing for the next lesson."}
			]
