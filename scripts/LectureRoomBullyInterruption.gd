extends Node

const COZY_CHOICE_UI = preload("res://scripts/PolishedChoiceUI.gd")

# LECTURE ROOM BULLY INTERRUPTION CONTROLLER

@onready var player: CharacterBody2D = $"../Player"
@onready var joe: CharacterBody2D = $"../Joe"
@onready var joey: CharacterBody2D = $"../Joey"
@onready var joseph: CharacterBody2D = $"../Joseph"

var sir_charles: CharacterBody2D = null

var running: bool = false
var original_bully_collision_data: Dictionary = {}
var original_player_collision_layer: int = 0
var original_player_collision_mask: int = 0
var sir_charles_original_position: Vector2 = Vector2.ZERO
var sir_charles_original_visible: bool = false
var controlled_characters: Array[CharacterBody2D] = []
var sir_charles_entered_lecture_room: bool = false

const BULLY_WALK_SPEED: float = 85.0
const BULLY_RUN_SPEED: float = 240.0
const WALK_WITH_BULLIES_DURATION: float = 3.0
const SIR_CHARLES_APPROACH_SPEED: float = 95.0
const SIR_CHARLES_STOP_DISTANCE: float = 55.0
const BULLY_RUN_DURATION: float = 4.2
const SIR_CHARLES_ENTER_SPEED: float = 95.0
const SIR_CHARLES_ENTER_EXTRA_TIME: float = 0.35
const CHOICE_PANEL_SIZE := Vector2(620.0, 250.0)

const JOE_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joe/Joe.png")
const JOEY_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joey/Joey.png")
const JOSEPH_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joseph/Joseph.png")
const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const SIR_CHARLES_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Charles/Charles.png")

var cutting_choice_result: int = 0


func _ready() -> void:

	sir_charles = get_node_or_null("../Sir Charles") as CharacterBody2D

	if sir_charles == null:
		sir_charles = get_node_or_null("../Sir_Charles") as CharacterBody2D

	if sir_charles != null:
		sir_charles_original_position = sir_charles.global_position
		sir_charles_original_visible = sir_charles.visible
		sir_charles.visible = false


func start_interruption() -> void:

	if running:
		return

	if GameManager.lecture_bully_interruption_done:
		return

	if player == null or joe == null or joey == null or joseph == null:
		print("ERROR: LectureRoomBullyInterruption could not find the Player or bullies.")
		return

	set_character_visible(joe, true)
	set_character_visible(joey, true)
	set_character_visible(joseph, true)

	running = true

	GameManager.player_controls_locked = true

	take_control_of_character(player)
	take_control_of_character(joe)
	take_control_of_character(joey)
	take_control_of_character(joseph)

	stop_character(player)
	stop_character(joe)
	stop_character(joey)
	stop_character(joseph)

	store_and_disable_character_collisions(joe)
	store_and_disable_character_collisions(joey)
	store_and_disable_character_collisions(joseph)

	await start_far_end_callout()
	await start_bully_conversation()

	# The optional interruption objectives appear when the choice begins.
	var quest_manager := get_node_or_null("/root/QuestUIManager")
	if quest_manager != null and quest_manager.has_method("start_bully_choice"):
		quest_manager.start_bully_choice()

	var choice: int = await show_cutting_choice()

	# YES = Play Along / Make Enemies crossed.
	# NO = Make Enemies completed / Play Along crossed.
	if quest_manager != null and quest_manager.has_method("resolve_bully_choice"):
		quest_manager.resolve_bully_choice(choice)

	if choice == 1:
		await play_yes_route()
	else:
		await play_no_route()

	GameManager.lecture_bully_interruption_done = true
	GameManager.player_controls_locked = false

	restore_character_collision(joe)
	restore_character_collision(joey)
	restore_character_collision(joseph)

	if sir_charles != null:
		if sir_charles_entered_lecture_room:
			# Sir Charles has already entered the Lecture Room, so keep him hidden
			# instead of resetting him back into the hallway.
			sir_charles.visible = false
		else:
			sir_charles.visible = sir_charles_original_visible
			sir_charles.global_position = sir_charles_original_position

	for character in controlled_characters:
		release_control_of_character(character)

	controlled_characters.clear()

	stop_character(player)
	stop_character(joe)
	stop_character(joey)
	stop_character(joseph)

	running = false


func start_far_end_callout() -> void:

	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD
	}

	var dialogue = [
		{
			"speaker": "Joseph",
			"text": "Yo, twerp! Where do you think you're going?"
		},
		{
			"speaker": "Player",
			"text": "Huh?"
		},
		{
			"speaker": "Joe",
			"text": "Hey! We're talking to you!"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


func start_bully_conversation() -> void:

	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD
	}

	var dialogue = [
		{
			"speaker": "Joe",
			"text": "Well, well. Look who finally decided to show up."
		},
		{
			"speaker": "Player",
			"text": "What do you guys want?"
		},
		{
			"speaker": "Joey",
			"text": "Nothing much. We just wanted to see what the new kid was up to."
		},
		{
			"speaker": "Player",
			"text": "I'm trying to get to my class."
		},
		{
			"speaker": "Joseph",
			"text": "Already running off to class? You really take school seriously, huh?"
		},
		{
			"speaker": "Player",
			"text": "Some of us actually want to pass."
		},
		{
			"speaker": "Joe",
			"text": "Relax, twerp. We're not asking you to drop out."
		},
		{
			"speaker": "Joey",
			"text": "We're just offering you a better way to spend your time."
		},
		{
			"speaker": "Player",
			"text": "And what exactly is that?"
		},
		{
			"speaker": "Joseph",
			"text": "Come with us. Cut class for a while."
		},
		{
			"speaker": "Joe",
			"text": "We'll go somewhere, mess around, maybe play some games."
		},
		{
			"speaker": "Joey",
			"text": "No teachers. No lectures. Just fun."
		},
		{
			"speaker": "Joseph",
			"text": "So? You coming with us or what?"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


func show_cutting_choice() -> int:

	cutting_choice_result = 0

	var choice_ui := COZY_CHOICE_UI.new()
	get_tree().current_scene.add_child(choice_ui)

	cutting_choice_result = await choice_ui.show_choice(
		"CUT CLASS WITH THE BULLIES?",
		"The three bullies are asking you to leave class with them and do something stupid instead of going inside.",
		"YES — I'LL COME",
		"NO — I HAVE CLASS",
		1,
		2,
		Color("#FF5C8A")
	)

	return cutting_choice_result

func _on_cutting_choice_yes_pressed() -> void:

	cutting_choice_result = 1


func _on_cutting_choice_no_pressed() -> void:

	cutting_choice_result = 2


func play_yes_route() -> void:

	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD
	}

	var dialogue = [
		{
			"speaker": "Player",
			"text": "I guess I can come for a little while."
		},
		{
			"speaker": "Joseph",
			"text": "That's more like it!"
		},
		{
			"speaker": "Joe",
			"text": "See? School can wait for a few minutes."
		},
		{
			"speaker": "Joey",
			"text": "Come on, twerp. Let's move."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await walk_with_bullies_left(WALK_WITH_BULLIES_DURATION)
	await sir_charles_interrupt_bullies()


func play_no_route() -> void:

	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD
	}

	var dialogue = [
		{
			"speaker": "Player",
			"text": "No. I have a class to attend."
		},
		{
			"speaker": "Joseph",
			"text": "Seriously? You're choosing class over us?"
		},
		{
			"speaker": "Joe",
			"text": "That's pretty rude, twerp."
		},
		{
			"speaker": "Joey",
			"text": "Maybe he needs a little encouragement."
		},
		{
			"speaker": "Joseph",
			"text": "Yeah. One punch ought to change your mind."
		},
		{
			"speaker": "Player",
			"text": "What?"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await sir_charles_interrupt_bullies()


func walk_with_bullies_left(duration: float) -> void:

	var characters: Array[CharacterBody2D] = [
		player,
		joe,
		joey,
		joseph
	]

	for character in characters:
		if character != null:
			set_walk_animation(character, Vector2.LEFT)

	var timer := 0.0

	while timer < duration:

		var delta := get_process_delta_time()

		for character in characters:
			if character != null:
				character.global_position.x -= BULLY_WALK_SPEED * delta
				play_footstep(character, delta)

		timer += delta
		await get_tree().process_frame

	for character in characters:
		if character != null:
			stop_character(character)


func sir_charles_interrupt_bullies() -> void:

	if sir_charles == null:
		print("WARNING: Sir Charles was not found. Ending bully interruption without professor scene.")
		return

	var lecture_door_position := find_lecture_room_door_position()

	sir_charles.visible = true
	sir_charles.global_position = lecture_door_position
	take_control_of_character(sir_charles)
	stop_character(sir_charles)

	set_walk_animation(sir_charles, Vector2.LEFT)

	var angry_line = [
		{
			"speaker": "Sir Charles",
			"text": "HEY! What do you three think you're doing?!"
		}
	]

	DialogueManager.start_multi_dialogue(
		angry_line,
		{"Sir Charles": SIR_CHARLES_HD},
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await run_bullies_away()

	await approach_player_with_sir_charles()

	var professor_dialogue = [
		{
			"speaker": "Sir Charles",
			"text": "You!"
		},
		{
			"speaker": "Player",
			"text": "Sir Charles?"
		},
		{
			"speaker": "Sir Charles",
			"text": "What are you doing out here? You're already late for class."
		},
		{
			"speaker": "Player",
			"text": "I..."
		},
		{
			"speaker": "Sir Charles",
			"text": "Don't let those three turn you into one of them."
		},
		{
			"speaker": "Sir Charles",
			"text": "You have a class waiting for you. Go inside the Lecture Room."
		},
		{
			"speaker": "Player",
			"text": "Yes, sir."
		}
	]

	DialogueManager.start_multi_dialogue(
		professor_dialogue,
		{"Sir Charles": SIR_CHARLES_HD},
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	face_character_toward_character(sir_charles, player)
	face_character_toward_character(player, sir_charles)

	# Sir Charles does not remain in the hallway after telling the player to go to class.
	await send_sir_charles_into_lecture_room()


func run_bullies_away() -> void:

	var characters: Array[CharacterBody2D] = [
		joe,
		joey,
		joseph
	]

	var dialogue = [
		{
			"speaker": "Joey",
			"text": "Oh no! Run! It's Sir Charles!"
		},
		{
			"speaker": "Joe",
			"text": "Forget it! Move!"
		},
		{
			"speaker": "Joseph",
			"text": "We'll deal with you later, twerp!"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Joe": JOE_HD, "Joey": JOEY_HD, "Joseph": JOSEPH_HD},
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	for character in characters:
		if character != null:
			set_walk_animation(character, Vector2.LEFT)

	var timer := 0.0

	while timer < BULLY_RUN_DURATION:

		var delta := get_process_delta_time()

		for character in characters:
			if character != null:
				character.global_position.x -= BULLY_RUN_SPEED * delta

		timer += delta
		await get_tree().process_frame

	for character in characters:
		if character != null:
			set_character_visible(character, false)
			stop_character(character)


func send_sir_charles_into_lecture_room() -> void:

	if sir_charles == null:
		return

	var lecture_door_position := find_lecture_room_door_position()

	# Walk back toward the Lecture Room entrance after finishing the conversation.
	face_character_toward_position(sir_charles, lecture_door_position)

	var last_time := Time.get_ticks_msec() / 1000.0

	while sir_charles.global_position.distance_to(lecture_door_position) > 8.0:

		var current_time := Time.get_ticks_msec() / 1000.0
		var delta: float = max(0.0, current_time - last_time)
		last_time = current_time

		var direction := lecture_door_position - sir_charles.global_position

		if direction.length() <= 8.0:
			break

		direction = direction.normalized()
		sir_charles.global_position += direction * SIR_CHARLES_ENTER_SPEED * delta
		set_walk_animation(sir_charles, direction)

		await get_tree().process_frame

	stop_character(sir_charles)

	# Move a little farther past the doorway so it looks like he actually entered the room.
	var enter_direction := player.global_position.direction_to(lecture_door_position)
	if enter_direction.length() <= 0.01:
		enter_direction = Vector2.UP

	set_walk_animation(sir_charles, enter_direction)

	var enter_timer := 0.0

	while enter_timer < SIR_CHARLES_ENTER_EXTRA_TIME:
		sir_charles.global_position += enter_direction * SIR_CHARLES_ENTER_SPEED * get_process_delta_time()
		enter_timer += get_process_delta_time()
		await get_tree().process_frame

	stop_character(sir_charles)
	sir_charles.visible = false
	sir_charles_entered_lecture_room = true


func face_character_toward_position(
	character: CharacterBody2D,
	target_position: Vector2
) -> void:

	if character == null:
		return

	var difference := target_position - character.global_position

	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := "idle_down"

	if abs(difference.x) > abs(difference.y):
		animation_name = "idle_right" if difference.x > 0.0 else "idle_left"
	else:
		animation_name = "idle_down" if difference.y > 0.0 else "idle_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
		sprite.pause()

func approach_player_with_sir_charles() -> void:

	if sir_charles == null or player == null:
		return

	var target_position := player.global_position + Vector2(0.0, -SIR_CHARLES_STOP_DISTANCE)
	var last_time := Time.get_ticks_msec() / 1000.0

	while sir_charles.global_position.distance_to(target_position) > 6.0:

		var current_time := Time.get_ticks_msec() / 1000.0
		var delta: float = max(0.0, current_time - last_time)
		last_time = current_time

		var direction := target_position - sir_charles.global_position

		if direction.length() <= 6.0:
			break

		direction = direction.normalized()
		sir_charles.global_position += direction * SIR_CHARLES_APPROACH_SPEED * delta
		set_walk_animation(sir_charles, direction)

		await get_tree().process_frame

	stop_character(sir_charles)


func find_lecture_room_door_position() -> Vector2:

	var lecture_door := get_node_or_null("../Door_Room202/Area2D3") as Area2D

	if lecture_door != null:
		var collision := lecture_door.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision != null:
			return collision.global_position
		return lecture_door.global_position

	return player.global_position + Vector2(120.0, 0.0)


func take_control_of_character(character: CharacterBody2D) -> void:

	if character == null:
		return

	if not controlled_characters.has(character):
		controlled_characters.append(character)

	character.set_physics_process(false)
	character.set_process(false)


func release_control_of_character(character: CharacterBody2D) -> void:

	if character == null:
		return

	character.set_physics_process(true)
	character.set_process(true)


func stop_character(character: CharacterBody2D) -> void:

	if character == null:
		return

	character.velocity = Vector2.ZERO

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite != null:
		sprite.pause()

	var sound := character.get_node_or_null(
		"FootstepSound"
	) as AudioStreamPlayer

	if sound != null:
		sound.stop()


func store_and_disable_character_collisions(character: CharacterBody2D) -> void:

	if character == null:
		return

	original_bully_collision_data[character] = {
		"layer": character.collision_layer,
		"mask": character.collision_mask
	}

	character.collision_layer = 0
	character.collision_mask = 0

	var collision_shapes := character.find_children(
		"CollisionShape2D",
		"CollisionShape2D",
		true,
		false
	)

	for node in collision_shapes:
		var shape := node as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", true)


func restore_character_collision(character: CharacterBody2D) -> void:

	if character == null:
		return

	if original_bully_collision_data.has(character):
		var data: Dictionary = original_bully_collision_data[character]
		character.collision_layer = int(data["layer"])
		character.collision_mask = int(data["mask"])

	var collision_shapes := character.find_children(
		"CollisionShape2D",
		"CollisionShape2D",
		true,
		false
	)

	for node in collision_shapes:
		var shape := node as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", false)


func set_walk_animation(character: CharacterBody2D, direction: Vector2) -> void:

	if character == null or direction.length() <= 0.01:
		return

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := "walk_down"

	if abs(direction.x) > abs(direction.y):
		animation_name = "walk_right" if direction.x > 0.0 else "walk_left"
	else:
		animation_name = "walk_down" if direction.y > 0.0 else "walk_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.speed_scale = 1.0
		sprite.play(animation_name)


func play_footstep(character: CharacterBody2D, _delta: float) -> void:

	if character == null:
		return

	# Footsteps are intentionally omitted from this controller because the
	# player and bully scenes already handle their own step sounds.


func face_character_toward_character(
	character: CharacterBody2D,
	target_character: CharacterBody2D
) -> void:

	if character == null or target_character == null:
		return

	var difference := target_character.global_position - character.global_position

	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := "idle_down"

	if abs(difference.x) > abs(difference.y):
		animation_name = "idle_right" if difference.x > 0.0 else "idle_left"
	else:
		animation_name = "idle_down" if difference.y > 0.0 else "idle_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
		sprite.pause()


func get_player_texture() -> Texture2D:
	return PLAYER_HD


func get_character_texture(character: Node) -> Texture2D:

	if character == joe:
		return JOE_HD

	if character == joey:
		return JOEY_HD

	if character == joseph:
		return JOSEPH_HD

	if character == sir_charles:
		return SIR_CHARLES_HD

	if character == player:
		return PLAYER_HD

	return null


func set_character_visible(character: CharacterBody2D, should_be_visible: bool) -> void:

	if character == null:
		return

	character.visible = should_be_visible

	var animated_sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if animated_sprite != null:
		animated_sprite.visible = should_be_visible
		animated_sprite.modulate = Color.WHITE

	var sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite != null:
		sprite.visible = should_be_visible
		sprite.modulate = Color.WHITE
