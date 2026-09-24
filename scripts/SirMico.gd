extends CharacterBody2D

const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const SIR_MICO_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Mico/Mico.png")

func _ready() -> void:
	add_to_group("npc")


func interact() -> void:
	if DialogueManager.is_active:
		return

	if GameManager.player_controls_locked:
		return

	if not GameManager.sir_mico_dialogue_done:
		start_first_dialogue()

	elif (
		GameManager.maclab_challenge_completed
		and not GameManager.sir_mico_second_dialogue_done
	):
		start_second_dialogue()

	else:
		print("No additional dialogue.")


func start_first_dialogue() -> void:
	var dialogue = [
		{
			"speaker": "Sir Mico",
			"text": "You're finally here."
		},
		{
			"speaker": "Player",
			"text": "Good morning, sir."
		},
		{
			"speaker": "Sir Mico",
			"text": "This is the Mac Lab. You'll be doing an activity here today."
		},
		{
			"speaker": "Player",
			"text": "What kind of activity, sir?"
		},
		{
			"speaker": "Sir Mico",
			"text": "You'll be using the computer to complete a short drawing challenge."
		},
		{
			"speaker": "Player",
			"text": "A drawing challenge?"
		},
		{
			"speaker": "Sir Mico",
			"text": "Yes. You'll be given several shapes to trace."
		},
		{
			"speaker": "Sir Mico",
			"text": "You will have limited time for each one, so make sure you work carefully."
		},
		{
			"speaker": "Player",
			"text": "Okay, sir. I'll do my best."
		},
		{
			"speaker": "Sir Mico",
			"text": "Good. Don't rush too much. Accuracy matters."
		},
		{
			"speaker": "Sir Mico",
			"text": "Once you're ready, go ahead and use the Mac in front of you."
		},
		{
			"speaker": "Player",
			"text": "Yes, sir."
		}
	]

	DialogueManager.start_dialogue(
		dialogue,
		SIR_MICO_HD,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	GameManager.sir_mico_dialogue_done = true
	GameManager.mac_computer_unlocked = true


func start_second_dialogue() -> void:
	var performance := get_performance_level(GameManager.maclab_performance_score)
	var dialogue := get_performance_dialogue(performance)

	DialogueManager.start_dialogue(
		dialogue,
		SIR_MICO_HD,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	GameManager.sir_mico_second_dialogue_done = true


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
				{"speaker": "Sir Mico", "text": "You're back. I checked your final drawing results."},
				{"speaker": "Player", "text": "Yes, sir. I was trying to keep up with the time while staying close to the guides."},
				{"speaker": "Sir Mico", "text": "And it shows. Your performance was excellent. You maintained strong accuracy even with the time pressure."},
				{"speaker": "Player", "text": "Thank you, sir. I tried not to panic when the timer started getting low."},
				{"speaker": "Sir Mico", "text": "That is an important skill. In actual projects, you will not always have unlimited time to revise your work."},
				{"speaker": "Player", "text": "So the point was not just to draw well, but to make decisions quickly too?"},
				{"speaker": "Sir Mico", "text": "Exactly. You followed the instructions, managed your time, and still paid attention to detail."},
				{"speaker": "Player", "text": "I guess I was more focused than I expected."},
				{"speaker": "Sir Mico", "text": "Keep that discipline. As you move forward, I want you to start thinking beyond simply following a guide. Think about why a design works and what you want the viewer to notice first."},
				{"speaker": "Player", "text": "I'll try to be more intentional with my designs, sir."},
				{"speaker": "Sir Mico", "text": "Good. You have a solid starting point. Keep practicing and do not become complacent just because you did well today."},
				{"speaker": "Player", "text": "Yes, sir. I'll keep improving."},
				{"speaker": "Sir Mico", "text": "That's what I wanted to hear. You can continue with your day."}
			]
		"Very Good":
			return [
				{"speaker": "Sir Mico", "text": "You're back. I reviewed your drawing challenge results."},
				{"speaker": "Player", "text": "Yes, sir. How did I do?"},
				{"speaker": "Sir Mico", "text": "Very good overall. You showed good control and you were able to finish the activities under pressure."},
				{"speaker": "Player", "text": "That's a relief. There were a few shapes where I almost ran out of time."},
				{"speaker": "Sir Mico", "text": "I noticed that. Your accuracy was strong, but there were moments when you rushed near the end."},
				{"speaker": "Player", "text": "I was worried about the timer."},
				{"speaker": "Sir Mico", "text": "That is understandable. Next time, prepare your approach before you start drawing. A few seconds spent planning can save more time later."},
				{"speaker": "Player", "text": "So I should plan the movement instead of reacting to the timer?"},
				{"speaker": "Sir Mico", "text": "Exactly. The timer is there to test how you manage pressure, not to make you panic."},
				{"speaker": "Player", "text": "I'll remember that, sir."},
				{"speaker": "Sir Mico", "text": "Your fundamentals are already in a good place. Work on consistency, especially when the task becomes more complicated."},
				{"speaker": "Player", "text": "Understood."},
				{"speaker": "Sir Mico", "text": "Good. Keep practicing and you will become more confident with design work."},
				{"speaker": "Player", "text": "Thank you, sir."},
				{"speaker": "Sir Mico", "text": "You're welcome. You may continue."}
			]
		"Average":
			return [
				{"speaker": "Sir Mico", "text": "You're back. I have your drawing challenge results here."},
				{"speaker": "Player", "text": "I was worried about how I did, sir."},
				{"speaker": "Sir Mico", "text": "Your performance was average. That is not a reason to give up, but it does show us what you need to work on."},
				{"speaker": "Player", "text": "I had trouble keeping the lines accurate when the timer was running."},
				{"speaker": "Sir Mico", "text": "That was one of the main issues. You understood the task, but your execution became less consistent when you felt pressured."},
				{"speaker": "Player", "text": "I think I started rushing."},
				{"speaker": "Sir Mico", "text": "Then your first goal should be control. Do not focus on finishing quickly if it causes you to lose accuracy."},
				{"speaker": "Player", "text": "But what if I run out of time?"},
				{"speaker": "Sir Mico", "text": "That is where preparation matters. Look at the shape first, identify the difficult sections, and decide how you will approach them before you move."},
				{"speaker": "Player", "text": "So I need to think before I draw."},
				{"speaker": "Sir Mico", "text": "Exactly. Practice tracing slowly first, then gradually reduce the time. Accuracy should become natural before speed becomes the priority."},
				{"speaker": "Player", "text": "I'll practice that, sir."},
				{"speaker": "Sir Mico", "text": "Good. Your result is a starting point, not a final judgment. Use it to see what you can improve."},
				{"speaker": "Player", "text": "Thank you for the advice."},
				{"speaker": "Sir Mico", "text": "You're welcome. Keep working on it and you'll see the difference."}
			]
		"Poor":
			return [
				{"speaker": "Sir Mico", "text": "You're back. I checked your drawing challenge results."},
				{"speaker": "Player", "text": "I already have a feeling I didn't do very well, sir."},
				{"speaker": "Sir Mico", "text": "Your score was below the expected level. Still, this is useful because now we know exactly where you need more practice."},
				{"speaker": "Player", "text": "I kept losing track of the guide, especially when the timer got low."},
				{"speaker": "Sir Mico", "text": "I saw that. You were trying to finish too quickly, and that affected your accuracy."},
				{"speaker": "Player", "text": "I thought finishing everything was more important."},
				{"speaker": "Sir Mico", "text": "Finishing matters, but following instructions matters too. A completed task is not automatically a good task."},
				{"speaker": "Player", "text": "So what should I focus on first?"},
				{"speaker": "Sir Mico", "text": "Start with simple shapes. Practice straight lines, curves, and consistent movement. Once those become comfortable, work on speed."},
				{"speaker": "Player", "text": "That sounds like going back to the basics."},
				{"speaker": "Sir Mico", "text": "It is. Strong fundamentals make difficult work easier later. There is nothing wrong with rebuilding them."},
				{"speaker": "Player", "text": "I'll put more time into practicing."},
				{"speaker": "Sir Mico", "text": "Good. Do not let one activity convince you that you cannot improve. Skills are built through repetition."},
				{"speaker": "Player", "text": "Thank you, sir. I'll work on it."},
				{"speaker": "Sir Mico", "text": "That's the attitude I want. Keep practicing and try again with a calmer approach."}
			]
		_:
			return [
				{"speaker": "Sir Mico", "text": "You're back. I reviewed your drawing challenge results."},
				{"speaker": "Player", "text": "I know I struggled, sir."},
				{"speaker": "Sir Mico", "text": "You did struggle, and your result shows that you need to rebuild some basic skills."},
				{"speaker": "Player", "text": "I felt completely lost once the timer started."},
				{"speaker": "Sir Mico", "text": "That can happen. But do not treat a difficult first attempt as proof that you cannot learn."},
				{"speaker": "Player", "text": "Then where should I start?"},
				{"speaker": "Sir Mico", "text": "Start very simply. Practice controlling your mouse, tracing basic lines, and following a shape without worrying about speed."},
				{"speaker": "Player", "text": "And then increase the difficulty?"},
				{"speaker": "Sir Mico", "text": "Yes. Once your hand control improves, introduce curves and more complicated forms. After that, practice with a timer."},
				{"speaker": "Player", "text": "That sounds like a lot of practice."},
				{"speaker": "Sir Mico", "text": "It is, but that is how fundamentals are built. You do not need to become good overnight."},
				{"speaker": "Player", "text": "I'll try again instead of giving up."},
				{"speaker": "Sir Mico", "text": "Good. Ask for help when you need it, practice consistently, and pay attention to the instructions."},
				{"speaker": "Player", "text": "Yes, sir."},
				{"speaker": "Sir Mico", "text": "Your first result is simply information about where you are starting. What matters next is what you do with it."},
				{"speaker": "Player", "text": "I understand. Thank you, sir."},
				{"speaker": "Sir Mico", "text": "You're welcome. Keep going."}
			]
