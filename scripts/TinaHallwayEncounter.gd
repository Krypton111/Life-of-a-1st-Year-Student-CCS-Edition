extends Node

const COZY_CHOICE_UI = preload("res://scripts/PolishedChoiceUI.gd")

const PLAYER_PORTRAIT = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const TINA_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/8-bit Sprite Models/Tina (dating binubully ni mc na ngayon bespren)/tina.png")

@onready var player: CharacterBody2D = $"../Player"
@onready var tina: CharacterBody2D = $"../Tina"
@onready var kairi: CharacterBody2D = $"../Kairi"
@onready var kerwin: CharacterBody2D = $"../Kerwin"
@onready var janssen: CharacterBody2D = $"../Janssen"
@onready var nathaly: CharacterBody2D = $"../Nathaly"
@onready var cinematic_camera: Camera2D = $"../CinematicCamera"
@onready var top_bar: ColorRect = $"../CinematicUI/TopBar"
@onready var bottom_bar: ColorRect = $"../CinematicUI/BottomBar"

var running := false
var tina_move_tween: Tween
var tina_walk_animating := false
var tina_walk_animation_name := "walk_left"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_bar.visible = false
	bottom_bar.visible = false

	tina.visible = false
	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	if not GameManager.lecture_challenge_completed:
		return

	if GameManager.tina_hallway_encounter_done:
		return

	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await start_encounter()


func start_encounter() -> void:
	if running or GameManager.tina_hallway_encounter_done:
		return

	if not GameManager.lecture_challenge_completed:
		return

	running = true
	GameManager.player_controls_locked = true

	stop_player()

	tina.visible = true
	# Tina enters from the player's right and walks right-to-left into the
	# middle of the hallway, matching the intended scene direction.
	tina.global_position = Vector2(
		player.global_position.x + 350.0,
		player.global_position.y + 100.0
	)
	tina.set_physics_process(false)

	# Let Tina actually walk into position before the story/UI begins.
	move_tina_with_animation(
		tina.global_position,
		Vector2(620.0, player.global_position.y + 100.0),
		110.0
	)
	await tina_move_tween.finished
	play_animation(tina, "idle_left")
	pause_animation(tina)

	await start_player_monologue()

	# Give the player a brief moment to react before the timed choice appears.
	await get_tree().create_timer(0.35).timeout

	var choice_ui := COZY_CHOICE_UI.new()
	choice_ui.layer = 4096
	choice_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(choice_ui)
	await get_tree().process_frame

	var choice := await choice_ui.show_timed_choice(
		"Call out to Tina?",
		"Tina is already a few steps away.
You only have 5 seconds to decide.",
		"Call her",
		"Let her go",
		5.0,
		1,
		2
	)

	if choice == 1:
		await tina_route()
	else:
		await ignore_tina_route()

	GameManager.tina_hallway_encounter_done = true
	GameManager.player_controls_locked = false
	running = false


func start_player_monologue() -> void:
	var dialogue := [
		{
			"speaker": "Player",
			"text": "Is that... Tina?"
		}
	]

	# Player-only monologue: use the normal dialogue path because
	# multi-dialogue requires an NPC portrait.
	DialogueManager.start_dialogue(
		dialogue,
		PLAYER_PORTRAIT,
		PLAYER_PORTRAIT
	)

	await DialogueManager.dialogue_finished


func move_tina_with_animation(from_position: Vector2, to_position: Vector2, speed: float) -> void:
	var distance: float = from_position.distance_to(to_position)
	var duration: float = distance / speed if speed > 0.0 else 0.0

	if is_instance_valid(tina_move_tween):
		tina_move_tween.kill()

	tina.global_position = from_position

	var sprite := tina.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		sprite.stop()

		var movement := to_position - from_position
		if abs(movement.x) >= abs(movement.y):
			tina_walk_animation_name = "walk_right" if movement.x > 0.0 else "walk_left"
		else:
			tina_walk_animation_name = "walk_down" if movement.y > 0.0 else "walk_up"

		if sprite.sprite_frames.has_animation(tina_walk_animation_name):
			sprite.animation = StringName(tina_walk_animation_name)
		else:
			tina_walk_animation_name = "walk_left"
			sprite.animation = &"walk_left"

		# Use AnimatedSprite2D's built-in looping so the slow walk repeats
		# continuously for the entire movement instead of stopping after one cycle.
		sprite.speed_scale = 0.9 if speed <= 70.0 else 1.0
		sprite.frame = 0
		sprite.play(tina_walk_animation_name)

	tina_walk_animating = duration > 0.0

	tina_move_tween = create_tween()
	tina_move_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	if duration <= 0.0:
		tina.global_position = to_position
		tina_walk_animating = false
		return

	tina_move_tween.tween_property(
		tina,
		"global_position",
		to_position,
		duration
	).set_trans(Tween.TRANS_LINEAR)

	await tina_move_tween.finished

	tina_walk_animating = false
	if sprite and is_instance_valid(sprite):
		sprite.stop()
		sprite.speed_scale = 1.0
		sprite.frame = 0



func tina_route() -> void:
	face_character_toward_player(tina)
	face_character_toward_player(player)

	# Tina first turns toward the player before any conversation begins.
	face_character_toward_player(tina)
	face_character_toward_player(player)

	var opening_dialogue := [
		{"speaker": "Player", "text": "Tina... wait."},
		{"speaker": "Tina", "text": "Huh?"},
		{"speaker": "Player", "text": "It's... it's me."},
		{"speaker": "Tina", "text": "I know."},
		{"speaker": "Player", "text": "Sorry. This is probably awkward."},
		{"speaker": "Tina", "text": "A little. I honestly didn't expect to see you here."},
		{"speaker": "Player", "text": "Yeah. Me neither."},
		{"speaker": "Tina", "text": "So... how have you been?"},
		{"speaker": "Player", "text": "I've been okay. College has been a lot."},
		{"speaker": "Tina", "text": "Same. I'm still getting used to everything."},
		{"speaker": "Player", "text": "Tina, there's something I've wanted to say for a long time."},
		{"speaker": "Tina", "text": "...What is it?"}
	]

	DialogueManager.start_multi_dialogue(
		opening_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	# Tina begins slowly walking toward the player exactly as the apology starts.
	# Build the tween directly here so this route contains no async function call.
	var distance: float = tina.global_position.distance_to(player.global_position)
	var target_distance: float = 90.0
	var travel_distance: float = maxf(0.0, distance - target_distance)
	var speed: float = 55.0
	var direction: Vector2 = (player.global_position - tina.global_position).normalized()
	var target_position: Vector2 = player.global_position - (direction * target_distance)

	var apology_dialogue := [
		{"speaker": "Player", "text": "I was horrible to you back then."},
		{"speaker": "Player", "text": "I bullied you, and I know saying sorry doesn't erase what I did."},
		{"speaker": "Player", "text": "I really regret it. I wish I had treated you differently."},
		{"speaker": "Tina", "text": "I won't pretend it didn't hurt."},
		{"speaker": "Tina", "text": "But... I can tell you mean what you're saying."},
		{"speaker": "Player", "text": "I do. I'm genuinely sorry, Tina."}
	]

	move_tina_with_animation(
		tina.global_position,
		target_position,
		speed
	)

	DialogueManager.start_multi_dialogue(
		apology_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished
	await tina_move_tween.finished
	face_character_toward_player(tina)

	var closing_dialogue := [
		{"speaker": "Tina", "text": "Okay. I accept your apology."},
		{"speaker": "Player", "text": "Thank you. I don't expect us to suddenly forget everything."},
		{"speaker": "Tina", "text": "We don't have to. We can just start from here."},
		{"speaker": "Player", "text": "I'd like that."},
		{"speaker": "Tina", "text": "You know, you're different from how I remember you."},
		{"speaker": "Player", "text": "I hope that's a good thing."},
		{"speaker": "Tina", "text": "I think it is."},
		{"speaker": "Player", "text": "So... what have you been up to?"},
		{"speaker": "Tina", "text": "Mostly surviving classes and trying not to get lost."},
		{"speaker": "Player", "text": "That sounds familiar."},
		{"speaker": "Tina", "text": "Actually, there's a cafe nearby called Sus! Marya & Hosep Cafe."},
		{"speaker": "Tina", "text": "Do you want to go there for a bit? We could catch up properly."}
	]

	DialogueManager.start_multi_dialogue(
		closing_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	var choice_ui := COZY_CHOICE_UI.new()
	choice_ui.layer = 4096
	choice_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	# Add the choice UI to the root so it cannot be hidden behind scene-level CanvasLayers.
	get_tree().root.add_child(choice_ui)
	await get_tree().process_frame

	var choice := await choice_ui.show_choice(
		"Go to the cafe?",
		"Tina has invited you to Sus! Marya & Hosep Cafe.",
		"Yes, let's go",
		"No, maybe later",
		1,
		2
	)

	if choice == 1:
		await walk_tina_and_player_to_left()
		await FadeManager.change_scene_with_fade(
			"res://scenes/main_level_scenes/game.tscn"
		)
	else:
		var goodbye := [
			{"speaker": "Tina", "text": "No worries. Maybe another time."},
			{"speaker": "Player", "text": "Yeah... take care, Tina."}
		]

		DialogueManager.start_multi_dialogue(
			goodbye,
			{"Tina": TINA_PORTRAIT},
			PLAYER_PORTRAIT
		)
		await DialogueManager.dialogue_finished


func walk_tina_and_player_to_left() -> void:
	# After agreeing to go to the cafe, the player and Tina leave together,
	# walking side-by-side toward the left before the scene transition.
	var target_x: float = minf(player.global_position.x, tina.global_position.x) - 280.0
	var speed := 46.0

	play_animation(player, "walk_left")
	play_animation(tina, "walk_left")

	while player.global_position.x > target_x:
		var delta := get_process_delta_time()
		player.global_position.x = move_toward(
			player.global_position.x,
			target_x,
			speed * delta
		)
		tina.global_position.x = move_toward(
			tina.global_position.x,
			player.global_position.x + 52.0,
			speed * delta
		)
		await get_tree().process_frame

	player.global_position.x = target_x
	tina.global_position.x = target_x + 52.0
	play_animation(player, "idle_left")
	play_animation(tina, "idle_left")
	pause_animation(player)
	pause_animation(tina)


func ignore_tina_route() -> void:
	face_character_toward_player(tina)

	var monologue := [
		{
			"speaker": "Player",
			"text": "I shouldn't have done that to her back then."
		},
		{
			"speaker": "Player",
			"text": "I really regret bullying her. I wish I had treated Tina differently."
		},
		{
			"speaker": "Player",
			"text": "I just hope she's doing okay."
		},
		{
			"speaker": "Player",
			"text": "I hope college is treating her well."
		}
	]

	DialogueManager.start_multi_dialogue(
		monologue,
		{},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	# Tina leaves first. Keep the friends hidden until she is completely
	# off-screen so the two hallway moments do not overlap.
	await walk_tina_off_screen()

	await start_friend_quiz_encounter()


func walk_tina_off_screen() -> void:
	if tina == null:
		return

	play_animation(tina, "walk_left")

	var target_x: float = player.global_position.x - 700.0
	var speed: float = 75.0

	while tina.global_position.x > target_x:
		var delta := get_process_delta_time()
		tina.global_position.x = move_toward(
			tina.global_position.x,
			target_x,
			speed * delta
		)
		await get_tree().process_frame

	pause_animation(tina)
	tina.visible = false


func start_friend_quiz_encounter() -> void:
	kairi.visible = true
	kerwin.visible = true
	janssen.visible = true
	nathaly.visible = true

	kairi.global_position = Vector2(650.0, 554.0)
	kerwin.global_position = Vector2(700.0, 515.0)
	janssen.global_position = Vector2(750.0, 423.0)
	nathaly.global_position = Vector2(725.0, 475.0)

	stop_friend_physics()

	var player_center := player.global_position
	cinematic_camera.global_position = player_center
	cinematic_camera.zoom = Vector2(1.8, 1.8)
	cinematic_camera.enabled = true

	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera:
		player_camera.enabled = false

	await show_cinematic_bars()

	# The four friends walk right-to-left toward the player.
	play_animation(kairi, "walk_left")
	play_animation(kerwin, "walk_left")
	play_animation(janssen, "walk_left")
	play_animation(nathaly, "walk_left")

	var targets := {
		kairi: Vector2(340.0, 454.0),
		kerwin: Vector2(390.0, 505.0),
		janssen: Vector2(440.0, 423.0),
		nathaly: Vector2(365.0, 475.0)
	}

	var finished := {}
	for friend in targets:
		finished[friend] = false

	while not (
		finished[kairi]
		and finished[kerwin]
		and finished[janssen]
		and finished[nathaly]
	):
		var delta := get_process_delta_time()

		for friend in targets:
			if finished[friend]:
				continue

			friend.global_position = friend.global_position.move_toward(
				targets[friend],
				58.0 * delta
			)

			if friend.global_position.distance_to(targets[friend]) <= 1.0:
				friend.global_position = targets[friend]
				finished[friend] = true

		var group_center := (
			kairi.global_position
			+ kerwin.global_position
			+ janssen.global_position
			+ nathaly.global_position
			+ player.global_position
		) / 5.0

		cinematic_camera.global_position = cinematic_camera.global_position.lerp(
			group_center,
			min(1.0, 5.0 * delta)
		)

		await get_tree().process_frame

	for friend in [kairi, kerwin, janssen, nathaly]:
		pause_animation(friend)
		face_character_toward_player(friend)

	await get_tree().create_timer(0.35).timeout

	var player_score := roundi(
		clamp(GameManager.lecture_performance_score, 0.0, 100.0)
		/ 100.0 * 20.0
	)

	var dialogue := [
		{"speaker": "Kairi", "text": "There you are! We were just talking about the Discrete Mathematics challenge."},
		{"speaker": "Kerwin", "text": "That quiz was something else. I got 17 out of 20."},
		{"speaker": "Janssen", "text": "I got 12. Some of those simplification questions got me."},
		{"speaker": "Nathaly", "text": "I got 18. I felt pretty confident with the Boolean laws."},
		{"speaker": "Kairi", "text": "I got 15. I knew the basics, but the longer expressions slowed me down."},
		{"speaker": "Kerwin", "text": "What about you? How did you do?"},
		{"speaker": "Player", "text": "I got %d out of 20." % player_score},
		{"speaker": "Janssen", "text": "At least we all had different experiences with it."},
		{"speaker": "Nathaly", "text": "Yeah. Some parts were straightforward, and some really made you think."},
		{"speaker": "Kairi", "text": "I think the pressure made it harder than it looked."},
		{"speaker": "Kerwin", "text": "Still, now we know what we need to work on."},
		{"speaker": "Player", "text": "True. I'll probably review the parts I struggled with."},
		{"speaker": "Kerwin", "text": "Speaking of taking a break, I heard there's a cafe nearby."},
		{"speaker": "Kerwin", "text": "Want to go to Sus! Marya & Hosep Cafe with us?"}
	]

	var portraits := {
		"Kairi": preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kairi/Kairi.png"),
		"Kerwin": preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png"),
		"Janssen": preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Janssen/Janssen.png"),
		"Nathaly": preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Nathaly/Nathaly.png")
	}

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	var choice_ui := COZY_CHOICE_UI.new()
	choice_ui.layer = 4096
	choice_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(choice_ui)
	await get_tree().process_frame

	var choice := await choice_ui.show_choice(
		"Go with them?",
		"The group is heading to Sus! Marya & Hosep Cafe.",
		"Yes, I'll come",
		"No, I'll pass",
		1,
		2
	)

	if choice == 1:
		await get_tree().create_timer(0.35).timeout
		await hide_cinematic_bars()
		await FadeManager.change_scene_with_fade(
			"res://scenes/main_level_scenes/game.tscn"
		)
	else:
		await no_cafe_route()


func no_cafe_route() -> void:
	var dialogue := [
		{"speaker": "Kerwin", "text": "Oh, okay. That's fine."},
		{"speaker": "Kerwin", "text": "Well, we'll get going then. Bye!"}
	]

	var portraits := {
		"Kerwin": preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png")
	}

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	await hide_cinematic_bars()
	await restore_player_camera()


func show_cinematic_bars() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var bar_height := viewport_size.y * 0.13

	top_bar.visible = true
	bottom_bar.visible = true

	top_bar.position = Vector2(0.0, -bar_height)
	bottom_bar.position = Vector2(0.0, viewport_size.y)

	top_bar.size = Vector2(viewport_size.x, bar_height)
	bottom_bar.size = Vector2(viewport_size.x, bar_height)

	top_bar.modulate.a = 0.0
	bottom_bar.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(top_bar, "position:y", 0.0, 0.45)
	tween.tween_property(
		bottom_bar,
		"position:y",
		viewport_size.y - bar_height,
		0.45
	)
	tween.tween_property(top_bar, "modulate:a", 1.0, 0.45)
	tween.tween_property(bottom_bar, "modulate:a", 1.0, 0.45)

	await tween.finished


func hide_cinematic_bars() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var bar_height := viewport_size.y * 0.13

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(top_bar, "position:y", -bar_height, 0.45)
	tween.tween_property(bottom_bar, "position:y", viewport_size.y, 0.45)
	tween.tween_property(top_bar, "modulate:a", 0.0, 0.45)
	tween.tween_property(bottom_bar, "modulate:a", 0.0, 0.45)

	await tween.finished

	top_bar.visible = false
	bottom_bar.visible = false


func restore_player_camera() -> void:
	cinematic_camera.enabled = false

	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera:
		player_camera.enabled = true
		player_camera.make_current()

	await get_tree().process_frame


func stop_player() -> void:
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.pause()


func stop_friend_physics() -> void:
	for friend in [kairi, kerwin, janssen, nathaly]:
		friend.velocity = Vector2.ZERO
		friend.set_physics_process(false)


func play_animation(character: CharacterBody2D, animation_name: String) -> void:
	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.flip_h = false
		sprite.speed_scale = 1.0
		sprite.frame = 0
		# Tina's scripted movement continues while the dialogue/game is paused.
		# ALWAYS keeps the AnimatedSprite2D processing so all walk frames advance.
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		sprite.play(animation_name)


func pause_animation(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.pause()


func face_character_toward_player(character: CharacterBody2D) -> void:
	var difference := player.global_position - character.global_position
	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
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
