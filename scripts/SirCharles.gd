extends CharacterBody2D

const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const SIR_CHARLES_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Charles/Charles.png")

func _ready() -> void:
	add_to_group("npc")

func interact() -> void:
	if DialogueManager.is_active:
		return

	if GameManager.player_controls_locked:
		return

	if not GameManager.sir_charles_dialogue_done:
		start_first_dialogue()
	elif GameManager.lecture_challenge_completed and not GameManager.sir_charles_second_dialogue_done:
		start_second_dialogue()
	else:
		print("No additional dialogue.")

func start_first_dialogue() -> void:
	var dialogue = [
		{
			"speaker": "Sir Charles",
			"text": "Good. You're here."
		},
		{
			"speaker": "Player",
			"text": "Good morning, sir."
		},
		{
			"speaker": "Sir Charles",
			"text": "Before you begin, I want to see how well you understand the fundamentals of Discrete Mathematics."
		},
		{
			"speaker": "Player",
			"text": "Discrete Mathematics?"
		},
		{
			"speaker": "Sir Charles",
			"text": "Yes. Everything from basic notation and propositions to logic and Boolean algebra."
		},
		{
			"speaker": "Player",
			"text": "That sounds difficult."
		},
		{
			"speaker": "Sir Charles",
			"text": "It may be challenging, but don't be intimidated."
		},
		{
			"speaker": "Sir Charles",
			"text": "I want you to work through the problems carefully instead of rushing through them."
		},
		{
			"speaker": "Player",
			"text": "Alright, sir."
		},
		{
			"speaker": "Sir Charles",
			"text": "Your activity is prepared on the notebook in front of you."
		},
		{
			"speaker": "Sir Charles",
			"text": "Write your answers carefully and do your best."
		},
		{
			"speaker": "Player",
			"text": "Yes, sir. I'll do my best."
		}
	]

	DialogueManager.start_dialogue(
		dialogue,
		SIR_CHARLES_HD,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	GameManager.sir_charles_dialogue_done = true

func start_second_dialogue() -> void:
	var performance := get_performance_level(GameManager.lecture_performance_score)
	var dialogue := get_performance_dialogue(performance)

	DialogueManager.start_dialogue(
		dialogue,
		SIR_CHARLES_HD,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	GameManager.sir_charles_second_dialogue_done = true


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
				{"speaker": "Sir Charles", "text": "You're finished. I have checked your answers."},
				{"speaker": "Player", "text": "Yes, sir. I tried to work through each problem carefully."},
				{"speaker": "Sir Charles", "text": "It paid off. Your performance was excellent. You showed a strong understanding of logical notation, Boolean laws, and simplification."},
				{"speaker": "Player", "text": "Some of the later problems took time, but I think the steps helped."},
				{"speaker": "Sir Charles", "text": "Exactly. Correct reasoning is more valuable than simply arriving at an answer. In mathematics, you should know why the answer is correct."},
				{"speaker": "Player", "text": "I tried to check each step before moving on."},
				{"speaker": "Sir Charles", "text": "Keep doing that. You also handled the timed environment well, which tells me you can remain organized under pressure."},
				{"speaker": "Player", "text": "Thank you, sir."},
				{"speaker": "Sir Charles", "text": "Do not stop at these exercises. Challenge yourself with more complicated expressions and practice explaining each law you use."},
				{"speaker": "Player", "text": "So I should focus on explaining the reasoning, not just getting the final answer."},
				{"speaker": "Sir Charles", "text": "Correct. A strong solution should be understandable to another person, not only to the person who wrote it."},
				{"speaker": "Player", "text": "I'll keep practicing, sir."},
				{"speaker": "Sir Charles", "text": "Good. You have a solid foundation. Continue building on it."}
			]
		"Very Good":
			return [
				{"speaker": "Sir Charles", "text": "You're finished. I have gone through your answers."},
				{"speaker": "Player", "text": "How did I do, sir?"},
				{"speaker": "Sir Charles", "text": "Very good. You understand most of the material, especially the basic notation and Boolean laws."},
				{"speaker": "Player", "text": "I struggled a little with the simplification problems."},
				{"speaker": "Sir Charles", "text": "That is where you should spend more time. Simplification is not about guessing the shortest-looking answer. It is about recognizing which law will reduce the expression."},
				{"speaker": "Player", "text": "Sometimes I know the law, but I hesitate about when to use it."},
				{"speaker": "Sir Charles", "text": "Then practice identifying the structure first. Look at the expression, determine what pattern you recognize, and only then apply the law."},
				{"speaker": "Player", "text": "That should make the process less random."},
				{"speaker": "Sir Charles", "text": "Exactly. Also watch your time. When you spend too long on one problem, the remaining questions become more difficult to manage."},
				{"speaker": "Player", "text": "I noticed that near the end."},
				{"speaker": "Sir Charles", "text": "Your foundation is good. Now work on speed without sacrificing the reasoning behind your answers."},
				{"speaker": "Player", "text": "Yes, sir. I'll practice that."},
				{"speaker": "Sir Charles", "text": "Good. Continue reviewing and challenge yourself with different forms of the same concepts."}
			]
		"Average":
			return [
				{"speaker": "Sir Charles", "text": "You're finished. I have checked your activity."},
				{"speaker": "Player", "text": "I had difficulty with some of the problems, sir."},
				{"speaker": "Sir Charles", "text": "Your performance was average. You understand several of the basic concepts, but your reasoning becomes less consistent when the problems require multiple steps."},
				{"speaker": "Player", "text": "The Boolean algebra questions took me the longest."},
				{"speaker": "Sir Charles", "text": "Then start there. Review the laws one by one and practice recognizing the patterns they apply to."},
				{"speaker": "Player", "text": "I sometimes forget which law to use."},
				{"speaker": "Sir Charles", "text": "Do not memorize the names alone. Understand what each law does to an expression. If you understand the transformation, choosing the law becomes easier."},
				{"speaker": "Player", "text": "So I should practice the transformation itself."},
				{"speaker": "Sir Charles", "text": "Yes. Write the original expression, apply one law, and check the result before moving to the next step."},
				{"speaker": "Player", "text": "That sounds slower, though."},
				{"speaker": "Sir Charles", "text": "It is slower while you are learning. With practice, the process becomes faster and more natural."},
				{"speaker": "Player", "text": "I'll keep practicing, sir."},
				{"speaker": "Sir Charles", "text": "Good. Do not let the timer convince you to abandon your reasoning. Learn the method first, then build speed."},
				{"speaker": "Player", "text": "Understood."},
				{"speaker": "Sir Charles", "text": "Keep working on it. You can improve from here."}
			]
		"Poor":
			return [
				{"speaker": "Sir Charles", "text": "You're finished. I have reviewed your answers."},
				{"speaker": "Player", "text": "I struggled a lot, sir."},
				{"speaker": "Sir Charles", "text": "Your result was below the expected level. More importantly, it shows that your fundamentals need reinforcement."},
				{"speaker": "Player", "text": "I knew some of the symbols, but I got lost when the problems became longer."},
				{"speaker": "Sir Charles", "text": "That tells us where to begin. Before solving complicated expressions, make sure you are comfortable with the basic logical operators and laws."},
				{"speaker": "Player", "text": "Should I practice the definitions first?"},
				{"speaker": "Sir Charles", "text": "Yes. Review AND, OR, NOT, implication, and biconditional. Then practice the basic laws before combining them."},
				{"speaker": "Player", "text": "I think I tried to jump straight into the harder questions."},
				{"speaker": "Sir Charles", "text": "That can make the process unnecessarily difficult. Complex problems are usually built from simpler ideas."},
				{"speaker": "Player", "text": "What about the time pressure?"},
				{"speaker": "Sir Charles", "text": "Ignore speed for now while you rebuild your method. Once you can solve the basic problems consistently, introduce a timer gradually."},
				{"speaker": "Player", "text": "I'll work on the basics first."},
				{"speaker": "Sir Charles", "text": "Good. Practice step by step and write down your reasoning. That will make your mistakes easier to find."},
				{"speaker": "Player", "text": "Thank you, sir."},
				{"speaker": "Sir Charles", "text": "You're welcome. Use this result as a guide for what to study next."}
			]
		_:
			return [
				{"speaker": "Sir Charles", "text": "You're finished. I have reviewed your activity."},
				{"speaker": "Player", "text": "I know I did poorly, sir."},
				{"speaker": "Sir Charles", "text": "Your result shows that you need to rebuild the fundamentals before attempting more difficult problems."},
				{"speaker": "Player", "text": "I had trouble remembering even the basic laws."},
				{"speaker": "Sir Charles", "text": "Then that is where we begin. There is no need to rush into complicated Boolean expressions before the basic ideas are secure."},
				{"speaker": "Player", "text": "What should I study first?"},
				{"speaker": "Sir Charles", "text": "Start with the meaning of each logical symbol. Then study the identity, inverse, idempotent, and De Morgan's laws one at a time."},
				{"speaker": "Player", "text": "Should I memorize their formulas?"},
				{"speaker": "Sir Charles", "text": "Learn what the formulas mean. Try simple examples and explain each transformation in your own words."},
				{"speaker": "Player", "text": "That might help me remember them."},
				{"speaker": "Sir Charles", "text": "It will also help you understand when they should be used. Once the basics become familiar, move to short simplification exercises."},
				{"speaker": "Player", "text": "And only after that should I practice with a timer?"},
				{"speaker": "Sir Charles", "text": "Correct. First build accuracy, then build speed. Pressure should test your preparation, not replace it."},
				{"speaker": "Player", "text": "I'll start over and practice properly."},
				{"speaker": "Sir Charles", "text": "Good. One difficult activity does not end your progress. It simply tells you what you need to work on next."},
				{"speaker": "Player", "text": "Thank you, sir."},
				{"speaker": "Sir Charles", "text": "You're welcome. Keep practicing."}
			]
