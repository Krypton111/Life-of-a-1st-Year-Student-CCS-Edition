extends Node

var has_baon := false
var house_opening_completed := false
var lecture_bully_interruption_done := false

var quiz_completed := false
var maclab_challenge_completed := false
var lecture_challenge_completed := false
var tina_hallway_encounter_done := false

# Identifies which hallway cafe route entered game.tscn.
# Empty preserves the existing/default cafe behavior.
var cafe_route := ""

# Challenge performance percentages. These are stored as 0.0-100.0 so each
# challenge can have a different maximum score.
var comlab_performance_score: float = -1.0
var maclab_performance_score: float = -1.0
var lecture_performance_score: float = -1.0

var friends_encounter_done := false
var friends_bookstore_choice := 0

var miss_joyz_first_dialogue_done := false
var miss_joyz_second_dialogue_done := false

var sir_mico_dialogue_done := false
var sir_mico_second_dialogue_done := false

var sir_charles_dialogue_done := false
var sir_charles_second_dialogue_done := false

var computer_unlocked := false
var mac_computer_unlocked := false
var lecture_computer_unlocked := false

var player_controls_locked := false

# Set when the player chooses to go home from the post-friends hallway route.
# HouseOpeningController uses this to play the dream-wakeup transition before
# resuming the normal parent phone-call sequence.
var returning_from_tina_dream := false

var dream_return_sequence_running := false
var tina_post_hallway_sequence_running := false
var tina_post_hallway_sequence_started := false



func _process(_delta: float) -> void:
	if not returning_from_tina_dream or dream_return_sequence_running:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	if current_scene.scene_file_path.ends_with("house_game_level.tscn"):
		dream_return_sequence_running = true
		call_deferred("_run_tina_dream_return_sequence")
		return

	if current_scene.scene_file_path.ends_with("School.tscn") and tina_hallway_encounter_done and not tina_post_hallway_sequence_started:
		tina_post_hallway_sequence_started = true
		tina_post_hallway_sequence_running = true
		call_deferred("_run_tina_post_hallway_sequence")


func _run_tina_post_hallway_sequence() -> void:
	# This continuation handles the final hallway choices after the original
	# TinaHallwayEncounter has completed. It intentionally runs only once.
	var scene := get_tree().current_scene
	if scene == null:
		tina_post_hallway_sequence_running = false
		return

	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		tina_post_hallway_sequence_running = false
		return

	# If the player had just declined Tina's cafe invitation, the original
	# hallway controller has already finished their farewell dialogue. Complete
	# the intended physical handoff here before the friends route begins.
	var hallway_controller: Node = scene.get_node_or_null("TinaHallwayEncounter")
	var tina: Node = scene.get_node_or_null("Tina")
	player_controls_locked = true
	if hallway_controller != null and tina != null and tina.visible:
		if hallway_controller.has_method("walk_tina_off_screen"):
			await hallway_controller.walk_tina_off_screen()
		if hallway_controller.has_method("start_friend_quiz_encounter"):
			await hallway_controller.start_friend_quiz_encounter()
		# The friends route handles its own cafe decision. If it transitions to
		# the cafe, the current scene will no longer be School.tscn.
		if not get_tree().current_scene.scene_file_path.ends_with("School.tscn"):
			tina_post_hallway_sequence_running = false
			return

	# If the friends route has just ended with "No, I'll pass", move the
	# visible group out of frame before returning control to the player.
	await _walk_visible_friends_off_screen(scene, player)
	_lock_tina_challenge_doors(scene)

	# Give the player control for five seconds before the final thought.
	player_controls_locked = false
	player.set_physics_process(true)
	await get_tree().create_timer(5.0).timeout

	player_controls_locked = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var portrait: Texture2D = load("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png") as Texture2D
	var monologue := [
		{"speaker": "Player", "text": "...Maybe I should just go to the cafe by myself."},
		{"speaker": "Player", "text": "I don't really need a group to have a decent afternoon."},
		{"speaker": "Player", "text": "Or... maybe I should just go home."},
		{"speaker": "Player", "text": "It's been a long day already."},
		{"speaker": "Player", "text": "What do I actually want to do?"}
	]

	DialogueManager.start_dialogue(monologue, portrait, portrait)
	await DialogueManager.dialogue_finished

	var choice_ui := preload("res://scripts/PolishedChoiceUI.gd").new()
	choice_ui.layer = 4096
	choice_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(choice_ui)
	await get_tree().process_frame

	var choice := await choice_ui.show_choice(
		"What do you want to do?",
		"The day is winding down. You can still make one last decision.",
		"Go to the cafe alone",
		"Just go home",
		1,
		2
	)

	if choice == 1:
		var cafe_dialogue := [
			{"speaker": "Player", "text": "You know what... I'll go."},
			{"speaker": "Player", "text": "Maybe going there alone isn't such a bad idea."},
			{"speaker": "Player", "text": "I'll grab something, sit down, and just clear my head for a while."},
			{"speaker": "Player", "text": "Yeah. The cafe it is."}
		]
		DialogueManager.start_dialogue(cafe_dialogue, portrait, portrait)
		await DialogueManager.dialogue_finished
		await FadeManager.change_scene_with_fade("res://scenes/main_level_scenes/game.tscn")
	else:
		await _run_tina_go_home_sequence(portrait)

	tina_post_hallway_sequence_running = false


func _run_tina_go_home_sequence(portrait: Texture2D) -> void:
	var dialogue := [
		{"speaker": "Player", "text": "No... I think I should just go home."},
		{"speaker": "Player", "text": "I can always come back another day."},
		{"speaker": "Player", "text": "My head feels exhausted."},
		{"speaker": "Player", "text": "Maybe sleep will help me sort everything out."}
	]
	DialogueManager.start_dialogue(dialogue, portrait, portrait)
	await DialogueManager.dialogue_finished

	await _play_tina_alarm()
	returning_from_tina_dream = true
	await FadeManager.change_scene_with_fade("res://scenes/main_level_scenes/house_game_level.tscn")


func _play_tina_alarm() -> void:
	var alarm_player := AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.25
	alarm_player.stream = generator
	add_child(alarm_player)
	alarm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	alarm_player.play()

	var playback := alarm_player.get_stream_playback() as AudioStreamGeneratorPlayback
	var elapsed: float = 0.0
	var phase: float = 0.0
	var duration: float = 6.0
	var sample_rate: float = 44100.0

	while elapsed < duration:
		var progress: float = elapsed / duration
		var volume: float = lerpf(0.04, 0.32, progress)
		var frequency: float = 660.0 if int(elapsed * 3.0) % 2 == 0 else 880.0
		if playback != null:
			var frames: int = min(playback.get_frames_available(), 2205)
			for _i in range(frames):
				var sample: float = sin(phase) * volume
				playback.push_frame(Vector2(sample, sample))
				phase += TAU * frequency / sample_rate
				if phase > TAU:
					phase = fmod(phase, TAU)
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

	alarm_player.stop()
	alarm_player.queue_free()


func _walk_visible_friends_off_screen(scene: Node, player: CharacterBody2D) -> void:
	var friends: Array[Node] = []
	for node_name in ["Kairi", "Kerwin", "Janssen", "Nathaly"]:
		var friend: Node = scene.get_node_or_null(node_name)
		if friend != null and friend.visible:
			friends.append(friend)

	if friends.is_empty():
		return

	var target_x: float = player.global_position.x - 700.0
	var speed: float = 75.0
	while true:
		var all_offscreen := true
		var delta: float = get_process_delta_time()
		for friend in friends:
			var friend_position: Vector2 = friend.global_position
			if friend_position.x > target_x:
				all_offscreen = false
				friend_position.x = move_toward(friend_position.x, target_x, speed * delta)
				friend.global_position = friend_position
			var sprite: AnimatedSprite2D = friend.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if sprite != null and sprite.sprite_frames.has_animation("walk_left"):
				sprite.process_mode = Node.PROCESS_MODE_ALWAYS
				sprite.play("walk_left")

		if all_offscreen:
			break
		await get_tree().process_frame

	for friend in friends:
		friend.visible = false
		var sprite: AnimatedSprite2D = friend.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite != null:
			sprite.pause()


func _lock_tina_challenge_doors(scene: Node) -> void:
	var door_script = preload("res://scripts/door.gd")
	for node in scene.find_children("*", "Area2D", true, false):
		if node.get_script() != door_script:
			continue
		var room_name: String = str(node.get("room_name"))
		if room_name in ["ComLab", "MacLab", "LectureRoom"]:
			node.set_process(false)
			node.set_deferred("monitoring", false)


func _run_tina_dream_return_sequence() -> void:
	returning_from_tina_dream = false
	player_controls_locked = true

	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)

	var dream_dialogue := [
		{"speaker": "Player", "text": "Huh...?"},
		{"speaker": "Player", "text": "Where am I...?"},
		{"speaker": "Player", "text": "Wait... the cafe... Tina... everyone..."},
		{"speaker": "Player", "text": "That was all just a dream...?"},
		{"speaker": "Player", "text": "I... I just woke up."}
	]

	var portrait: Texture2D = load("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png") as Texture2D
	DialogueManager.start_dialogue(dream_dialogue, portrait, portrait)
	await DialogueManager.dialogue_finished

	var house_controller := get_tree().current_scene.get_node_or_null("HouseOpeningController")
	if house_controller != null:
		if house_controller.has_method("play_phone_ring"):
			await house_controller.play_phone_ring()
		if house_controller.has_method("play_parent_phone_call"):
			await house_controller.play_parent_phone_call()

	if player != null:
		player.set_physics_process(true)

	player_controls_locked = false
	dream_return_sequence_running = false

var room_return_position := Vector2.ZERO
var has_room_return_position := false

var challenge_return_position := Vector2.ZERO
var has_challenge_return_position := false


func save_room_position(position: Vector2) -> void:
	room_return_position = position
	has_room_return_position = true


func get_room_return_position() -> Vector2:
	return room_return_position


func clear_room_position() -> void:
	has_room_return_position = false


func save_challenge_position(position: Vector2) -> void:
	challenge_return_position = position
	has_challenge_return_position = true


func get_challenge_return_position() -> Vector2:
	return challenge_return_position


func clear_challenge_position() -> void:
	has_challenge_return_position = false


var has_return_position := false
var return_position := Vector2.ZERO


func save_player_position(position: Vector2) -> void:
	return_position = position
	has_return_position = true


func get_player_return_position() -> Vector2:
	return return_position


func clear_return_position() -> void:
	has_return_position = false

#BULLY ENCOUNTER
var bullies_encounter_done := false

#BOOKSTORE
var bookstore_started := false

var bookstore_yellow_pad := false
var bookstore_ballpens := 0
var bookstore_correction_tape := false
var bookstore_discrete_math_book := false

var bookstore_talked_to_kairi := false
var bookstore_talked_to_kerwin := false
var bookstore_talked_to_janssen := false
var bookstore_talked_to_nathaly := false

var bookstore_talked_to_ate_libro := false
var bookstore_talked_to_kuya_libro := false

var bookstore_talked_to_friends := false
var bookstore_completed := false

var bookstore_return_event_pending := false
