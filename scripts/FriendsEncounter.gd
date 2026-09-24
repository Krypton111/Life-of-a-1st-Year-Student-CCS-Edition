extends Node

const COZY_CHOICE_UI = preload("res://scripts/PolishedChoiceUI.gd")

#CONTROLLER FOR THIS SCRIPT
@onready var player: CharacterBody2D = $"../Player"

@onready var kairi: CharacterBody2D = $"../Kairi"
@onready var kerwin: CharacterBody2D = $"../Kerwin"
@onready var janssen: CharacterBody2D = $"../Janssen"
@onready var nathaly: CharacterBody2D = $"../Nathaly"

@onready var cinematic_camera: Camera2D = $"../CinematicCamera"

@onready var top_bar: ColorRect = $"../CinematicUI/TopBar"
@onready var bottom_bar: ColorRect = $"../CinematicUI/BottomBar"

@onready var choice_ui: Control = $"../CinematicUI/BookstoreChoice"
@onready var question_label: Label = $"../CinematicUI/BookstoreChoice/Question"
@onready var yes_button: Button = $"../CinematicUI/BookstoreChoice/YesButton"
@onready var no_button: Button = $"../CinematicUI/BookstoreChoice/NoButton"

var running: bool = false
var player_camera: Camera2D = null

const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const KAIRI_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kairi/Kairi.png")
const KERWIN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png")
const JANSSEN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Janssen/Janssen.png")
const NATHALY_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Nathaly/Nathaly.png")

#CHALLENGE CHECKER AND BUTTON CHECKER
func _ready() -> void:
	top_bar.visible = false
	bottom_bar.visible = false

	choice_ui.visible = false
	choice_ui.modulate.a = 1.0

	question_label.visible = false
	yes_button.visible = false
	no_button.visible = false

	cinematic_camera.enabled = false

	player_camera = player.get_node_or_null("Camera2D") as Camera2D

	if not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	await get_tree().process_frame

	if GameManager.maclab_challenge_completed and not GameManager.friends_encounter_done:
		await get_tree().create_timer(0.3).timeout
		await start_encounter()

#ENCOUNTER WITH MC AND FRIENDS
func start_encounter() -> void:
	if running:
		return

	if GameManager.friends_encounter_done:
		return

	if not GameManager.maclab_challenge_completed:
		return

	running = true

	GameManager.player_controls_locked = true
	GameManager.friends_bookstore_choice = 0

	# The optional "Make Friends" quest becomes active when this encounter starts.
	var quest_manager := get_node_or_null("/root/QuestUIManager")
	if quest_manager != null and quest_manager.has_method("start_friends_choice"):
		quest_manager.start_friends_choice()

	kairi.visible = true
	kerwin.visible = true
	janssen.visible = true
	nathaly.visible = true
	player.visible = true

	stop_player()
	stop_friends()

	await show_cinematic_bars()
	await focus_on_friends()
	await friends_walk_casually()
	await friends_notice_player()

	await focus_on_player_for_fall()
	await player_falls()

	await focus_on_friends_before_rush()
	await friends_rush_to_player()
	await friends_help_player()

	await return_camera_to_group()
	await start_friends_dialogue()

	await show_bookstore_choice()

	GameManager.friends_encounter_done = true

	if GameManager.friends_bookstore_choice == 1:
		await yes_route()
	else:
		await no_route()

	running = false


func stop_player() -> void:
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()

	var sound := player.get_node_or_null(
		"FootstepSound"
	) as AudioStreamPlayer

	if sound:
		sound.stop()


func stop_friends() -> void:
	kairi.set_physics_process(false)
	kerwin.set_physics_process(false)
	janssen.set_physics_process(false)
	nathaly.set_physics_process(false)


func show_cinematic_bars() -> void:
	top_bar.visible = true
	bottom_bar.visible = true

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var bar_height: float = viewport_size.y * 0.13

	top_bar.position = Vector2(
		0.0,
		-bar_height
	)

	top_bar.size = Vector2(
		viewport_size.x,
		bar_height
	)

	bottom_bar.position = Vector2(
		0.0,
		viewport_size.y
	)

	bottom_bar.size = Vector2(
		viewport_size.x,
		bar_height
	)

	top_bar.modulate.a = 0.0
	bottom_bar.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		top_bar,
		"position:y",
		0.0,
		0.5
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		bottom_bar,
		"position:y",
		viewport_size.y - bar_height,
		0.5
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		top_bar,
		"modulate:a",
		1.0,
		0.5
	)

	tween.tween_property(
		bottom_bar,
		"modulate:a",
		1.0,
		0.5
	)

	await tween.finished


func hide_cinematic_bars() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var bar_height: float = viewport_size.y * 0.13

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		top_bar,
		"position:y",
		-bar_height,
		0.5
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	tween.tween_property(
		bottom_bar,
		"position:y",
		viewport_size.y,
		0.5
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	tween.tween_property(
		top_bar,
		"modulate:a",
		0.0,
		0.5
	)

	tween.tween_property(
		bottom_bar,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	top_bar.visible = false
	bottom_bar.visible = false

#FRIENDS WALK AS SOON AS THE CAMERA SEES THEM
func friends_walk_casually() -> void:
	var walk_speed: float = 30.0

	play_animation(kairi, "walk_left")
	play_animation(kerwin, "walk_left")
	play_animation(janssen, "walk_left")
	play_animation(nathaly, "walk_left")

	var target_kairi := kairi.global_position + Vector2(-90.0, 0.0)
	var target_kerwin := kerwin.global_position + Vector2(-90.0, 0.0)
	var target_janssen := janssen.global_position + Vector2(-90.0, 0.0)
	var target_nathaly := nathaly.global_position + Vector2(-90.0, 0.0)

	var timer := 0.0

	while timer < 2.0:
		var delta := get_process_delta_time()

		kairi.global_position = kairi.global_position.move_toward(
			target_kairi,
			walk_speed * delta
		)

		kerwin.global_position = kerwin.global_position.move_toward(
			target_kerwin,
			walk_speed * delta
		)

		janssen.global_position = janssen.global_position.move_toward(
			target_janssen,
			walk_speed * delta
		)

		nathaly.global_position = nathaly.global_position.move_toward(
			target_nathaly,
			walk_speed * delta
		)

		timer += delta

		await get_tree().process_frame

	pause_friends_animation()

#NOTICE PLAYER
func friends_notice_player() -> void:
	face_character_toward_player(kairi)
	face_character_toward_player(kerwin)
	face_character_toward_player(janssen)
	face_character_toward_player(nathaly)

	await get_tree().create_timer(0.5).timeout

#WHAT IF I'VE TOLD YOU THAT I'VE FALLEN
func player_falls() -> void:
	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		player,
		"rotation_degrees",
		90.0,
		0.25
	)

	await tween.finished

	await get_tree().create_timer(0.5).timeout

#TOLONGGGGG
func friends_rush_to_player() -> void:
	var player_position := player.global_position

	var kairi_target := player_position + Vector2(-55.0, -15.0)
	var kerwin_target := player_position + Vector2(55.0, -15.0)
	var janssen_target := player_position + Vector2(-45.0, 45.0)
	var nathaly_target := player_position + Vector2(45.0, 45.0)

	var walk_speed: float = 90.0

	var kairi_finished := false
	var kerwin_finished := false
	var janssen_finished := false
	var nathaly_finished := false

	while not (
		kairi_finished
		and kerwin_finished
		and janssen_finished
		and nathaly_finished
	):
		var delta := get_process_delta_time()

		if not kairi_finished:
			update_friend_walk_direction(kairi)

			kairi.global_position = kairi.global_position.move_toward(
				kairi_target,
				walk_speed * delta
			)

			if kairi.global_position.distance_to(kairi_target) <= 1.0:
				kairi.global_position = kairi_target
				kairi_finished = true
				face_character_toward_player(kairi)

		if not kerwin_finished:
			update_friend_walk_direction(kerwin)

			kerwin.global_position = kerwin.global_position.move_toward(
				kerwin_target,
				walk_speed * delta
			)

			if kerwin.global_position.distance_to(kerwin_target) <= 1.0:
				kerwin.global_position = kerwin_target
				kerwin_finished = true
				face_character_toward_player(kerwin)

		if not janssen_finished:
			update_friend_walk_direction(janssen)

			janssen.global_position = janssen.global_position.move_toward(
				janssen_target,
				walk_speed * delta
			)

			if janssen.global_position.distance_to(janssen_target) <= 1.0:
				janssen.global_position = janssen_target
				janssen_finished = true
				face_character_toward_player(janssen)

		if not nathaly_finished:
			update_friend_walk_direction(nathaly)

			nathaly.global_position = nathaly.global_position.move_toward(
				nathaly_target,
				walk_speed * delta
			)

			if nathaly.global_position.distance_to(nathaly_target) <= 1.0:
				nathaly.global_position = nathaly_target
				nathaly_finished = true
				face_character_toward_player(nathaly)

		var friend_center := (
			kairi.global_position
			+ kerwin.global_position
			+ janssen.global_position
			+ nathaly.global_position
		) / 4.0

		var camera_target := (
			friend_center
			+ player.global_position
		) / 2.0

		var camera_follow_speed: float = 5.0

		cinematic_camera.global_position = cinematic_camera.global_position.lerp(
			camera_target,
			min(1.0, camera_follow_speed * delta)
		)

		await get_tree().process_frame

	pause_friends_animation()

	face_character_toward_player(kairi)
	face_character_toward_player(kerwin)
	face_character_toward_player(janssen)
	face_character_toward_player(nathaly)

	await get_tree().create_timer(0.4).timeout

#E2 NA TUMUTULONG NA
func friends_help_player() -> void:
	face_character_toward_player(kairi)
	face_character_toward_player(kerwin)
	face_character_toward_player(janssen)
	face_character_toward_player(nathaly)

	await get_tree().create_timer(0.7).timeout

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		player,
		"rotation_degrees",
		0.0,
		0.35
	)

	await tween.finished

	await get_tree().create_timer(0.4).timeout

#SAY HI TO THE CAMERA MGA VADING
func focus_on_friends() -> void:
	var friend_center := (
		kairi.global_position
		+ kerwin.global_position
		+ janssen.global_position
		+ nathaly.global_position
	) / 4.0

	cinematic_camera.global_position = player.global_position

	if player_camera:
		cinematic_camera.zoom = player_camera.zoom

	cinematic_camera.enabled = true

	if player_camera:
		player_camera.enabled = false

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		friend_center,
		1.2
	)

	await tween.finished


func focus_on_player_for_fall() -> void:
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		player.global_position,
		0.8
	)

	await tween.finished


func focus_on_friends_before_rush() -> void:
	var friend_center := (
		kairi.global_position
		+ kerwin.global_position
		+ janssen.global_position
		+ nathaly.global_position
	) / 4.0

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		friend_center,
		0.8
	)

	await tween.finished


func return_camera_to_group() -> void:
	var group_center := (
		kairi.global_position
		+ kerwin.global_position
		+ janssen.global_position
		+ nathaly.global_position
		+ player.global_position
	) / 5.0

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		group_center,
		0.8
	)

	await tween.finished
	
#OSAP-OSAP CLA
func start_friends_dialogue() -> void:
	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Hey! Are you okay?"
		},
		{
			"speaker": "Player",
			"text": "Yeah... I think so."
		},
		{
			"speaker": "Nathaly",
			"text": "You really scared us there."
		},
		{
			"speaker": "Player",
			"text": "Sorry. I wasn't paying attention."
		},
		{
			"speaker": "Janssen",
			"text": "You just suddenly fell right in front of us."
		},
		{
			"speaker": "Player",
			"text": "I guess I wasn't looking where I was going."
		},
		{
			"speaker": "Kerwin",
			"text": "At least you didn't hit your head."
		},
		{
			"speaker": "Player",
			"text": "Yeah. I'm okay."
		},
		{
			"speaker": "Kairi",
			"text": "That's good. We were actually starting to worry."
		},
		{
			"speaker": "Player",
			"text": "You guys really rushed over that fast."
		},
		{
			"speaker": "Nathaly",
			"text": "Of course. We couldn't exactly just watch you fall."
		},
		{
			"speaker": "Player",
			"text": "I appreciate it."
		},
		{
			"speaker": "Janssen",
			"text": "No problem. We're classmates, aren't we?"
		},
		{
			"speaker": "Player",
			"text": "I suppose we are."
		},
		{
			"speaker": "Kerwin",
			"text": "Speaking of classes, we're actually heading somewhere right now."
		},
		{
			"speaker": "Player",
			"text": "Where are you guys going?"
		},
		{
			"speaker": "Kairi",
			"text": "We're going to the bookstore."
		},
		{
			"speaker": "Player",
			"text": "The bookstore?"
		},
		{
			"speaker": "Nathaly",
			"text": "Yeah. We need some extra school supplies."
		},
		{
			"speaker": "Janssen",
			"text": "We're trying to get everything ready before our next class."
		},
		{
			"speaker": "Kerwin",
			"text": "Especially because Discrete Mathematics is coming up."
		},
		{
			"speaker": "Player",
			"text": "Already? We just got here."
		},
		{
			"speaker": "Kairi",
			"text": "I know! The schedule doesn't really give us time to relax."
		},
		{
			"speaker": "Nathaly",
			"text": "We need paper, pens, and a few other things."
		},
		{
			"speaker": "Janssen",
			"text": "I'm probably going to buy more than I actually need."
		},
		{
			"speaker": "Player",
			"text": "At least you're prepared."
		},
		{
			"speaker": "Janssen",
			"text": "That's the plan."
		},
		{
			"speaker": "Kerwin",
			"text": "You should come with us."
		},
		{
			"speaker": "Player",
			"text": "Me?"
		},
		{
			"speaker": "Kairi",
			"text": "Yeah. You could probably use some supplies too."
		},
		{
			"speaker": "Player",
			"text": "I guess I could."
		},
		{
			"speaker": "Nathaly",
			"text": "It won't take long. We'll grab what we need and head back."
		},
		{
			"speaker": "Janssen",
			"text": "And it'll be less boring if we go together."
		},
		{
			"speaker": "Player",
			"text": "You guys seem pretty comfortable together."
		},
		{
			"speaker": "Kerwin",
			"text": "We've known each other for a while."
		},
		{
			"speaker": "Kairi",
			"text": "You'll get used to us."
		},
		{
			"speaker": "Player",
			"text": "That's a little dangerous to say."
		},
		{
			"speaker": "Nathaly",
			"text": "Don't worry. We're mostly harmless."
		},
		{
			"speaker": "Janssen",
			"text": "Mostly."
		},
		{
			"speaker": "Player",
			"text": "That doesn't sound very reassuring."
		},
		{
			"speaker": "Kairi",
			"text": "So? What do you say?"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished
	

func show_bookstore_choice() -> void:
	GameManager.player_controls_locked = true
	GameManager.friends_bookstore_choice = 0

	var cozy_choice_ui := COZY_CHOICE_UI.new()
	get_tree().current_scene.add_child(cozy_choice_ui)

	GameManager.friends_bookstore_choice = await cozy_choice_ui.show_choice(
		"COME WITH THE GROUP?",
		"Kairi, Kerwin, Janssen, and Nathaly are heading to the bookstore to grab supplies for Discrete Mathematics.",
		"YES — LET'S GO",
		"NO — MAYBE NEXT TIME",
		1,
		2,
		Color("#D8A15D")
	)

	# Accepting the invitation completes "Make Friends"; refusing crosses it out.
	var quest_manager := get_node_or_null("/root/QuestUIManager")
	if quest_manager != null and quest_manager.has_method("resolve_friends_choice"):
		quest_manager.resolve_friends_choice(GameManager.friends_bookstore_choice)

func _on_yes_pressed() -> void:
	GameManager.friends_bookstore_choice = 1
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_no_pressed() -> void:
	GameManager.friends_bookstore_choice = 2
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

#EDI YES
func yes_route() -> void:
	GameManager.player_controls_locked = true

	player.rotation_degrees = 0.0

	await start_yes_route_dialogue()

	play_animation(kairi, "walk_left")
	play_animation(kerwin, "walk_left")
	play_animation(janssen, "walk_left")
	play_animation(nathaly, "walk_left")

	play_player_walk_left()

	var camera_position := cinematic_camera.global_position
	var exit_x := camera_position.x - 900.0

	var walk_speed: float = 55.0
	var follow_distance: float = 90.0

	while (
		kairi.global_position.x > exit_x
		or kerwin.global_position.x > exit_x
		or janssen.global_position.x > exit_x
		or nathaly.global_position.x > exit_x
		or player.global_position.x > exit_x
	):
		var delta := get_process_delta_time()

		kairi.global_position.x -= walk_speed * delta
		kerwin.global_position.x -= walk_speed * delta
		janssen.global_position.x -= walk_speed * delta
		nathaly.global_position.x -= walk_speed * delta

		var target_player_position := kairi.global_position + Vector2(
			follow_distance,
			0.0
		)

		player.global_position = player.global_position.move_toward(
			target_player_position,
			walk_speed * delta
		)

		play_player_walk_left()

		await get_tree().process_frame

	pause_friends_animation()
	stop_player_animation()

	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false
	player.visible = false

	await get_tree().create_timer(0.4).timeout

	await transition_to_bookstore()

#EDI YES EXTRA DIALOGUE
func start_yes_route_dialogue() -> void:
	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Player",
			"text": "Alright, I guess I'll come with you."
		},
		{
			"speaker": "Kairi",
			"text": "Nice! Come on, we'll show you where it is."
		},
		{
			"speaker": "Nathaly",
			"text": "It's not too far from here."
		},
		{
			"speaker": "Player",
			"text": "Good. I don't want to be late for the next class."
		},
		{
			"speaker": "Janssen",
			"text": "Exactly. We still need to prepare for Discrete Mathematics."
		},
		{
			"speaker": "Kerwin",
			"text": "And I'm definitely getting a yellow pad this time."
		},
		{
			"speaker": "Player",
			"text": "You guys really take your school supplies seriously."
		},
		{
			"speaker": "Kairi",
			"text": "You learn pretty quickly that having the right stuff saves you trouble later."
		},
		{
			"speaker": "Nathaly",
			"text": "Besides, it'll be more fun going together."
		},
		{
			"speaker": "Player",
			"text": "Yeah. It'll be nice to get to know you guys better."
		},
		{
			"speaker": "Janssen",
			"text": "See? You're already getting used to us."
		},
		{
			"speaker": "Player",
			"text": "Don't get too confident."
		},
		{
			"speaker": "Kerwin",
			"text": "Too late."
		},
		{
			"speaker": "Kairi",
			"text": "Alright, enough talking. Let's get moving."
		},
		{
			"speaker": "Player",
			"text": "Alright then. Let's go."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

#EDI DONT
func no_route() -> void:
	GameManager.player_controls_locked = true

	await start_no_dialogue()

	await friends_walk_away_from_player()

	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	await hide_cinematic_bars()

	cinematic_camera.enabled = false

	if player_camera:
		player_camera.enabled = true
		player_camera.make_current()

	await get_tree().process_frame

	GameManager.player_controls_locked = false
	player.set_physics_process(true)
	
func start_no_dialogue() -> void:
	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Player",
			"text": "I think I'll pass for now. I still have somewhere I need to be."
		},
		{
			"speaker": "Kairi",
			"text": "Oh, okay! Maybe next time."
		},
		{
			"speaker": "Nathaly",
			"text": "Yeah, no worries."
		},
		{
			"speaker": "Janssen",
			"text": "We'll see you around."
		},
		{
			"speaker": "Kerwin",
			"text": "Take care!"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

#aww
func friends_walk_away_from_player() -> void:
	var walk_speed: float = 55.0
	var exit_distance: float = 900.0

	play_animation(kairi, "walk_left")
	play_animation(kerwin, "walk_left")
	play_animation(janssen, "walk_left")
	play_animation(nathaly, "walk_left")

	var exit_x := cinematic_camera.global_position.x - exit_distance

	while (
		kairi.global_position.x > exit_x
		or kerwin.global_position.x > exit_x
		or janssen.global_position.x > exit_x
		or nathaly.global_position.x > exit_x
	):
		var delta := get_process_delta_time()

		kairi.global_position.x -= walk_speed * delta
		kerwin.global_position.x -= walk_speed * delta
		janssen.global_position.x -= walk_speed * delta
		nathaly.global_position.x -= walk_speed * delta

		await get_tree().process_frame

	pause_friends_animation()
	

func update_friend_walk_direction(character: CharacterBody2D) -> void:
	var difference: Vector2 = player.global_position - character.global_position

	if difference.length() <= 0.1:
		return

	var direction_name: String

	if abs(difference.x) > abs(difference.y):
		if difference.x > 0.0:
			direction_name = "right"
		else:
			direction_name = "left"
	else:
		if difference.y > 0.0:
			direction_name = "down"
		else:
			direction_name = "up"

	var animation_name := "walk_" + direction_name

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation(animation_name):
			if sprite.animation != animation_name:
				sprite.play(animation_name)
			elif not sprite.is_playing():
				sprite.play(animation_name)


func play_animation(
	character: CharacterBody2D,
	animation_name: String
) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation(animation_name):
			sprite.play(animation_name)


func play_player_walk_left() -> void:
	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation("walk_left"):
			if sprite.animation != "walk_left":
				sprite.play("walk_left")
			elif not sprite.is_playing():
				sprite.play("walk_left")


func stop_player_animation() -> void:
	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()


func pause_animation(
	character: CharacterBody2D
) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()


func pause_friends_animation() -> void:
	pause_animation(kairi)
	pause_animation(kerwin)
	pause_animation(janssen)
	pause_animation(nathaly)

#hi pu
func face_character_toward_player(character: CharacterBody2D) -> void:
	var difference: Vector2 = player.global_position - character.global_position

	if difference.length() <= 0.1:
		return

	if abs(difference.x) > abs(difference.y):
		if difference.x > 0.0:
			face_character_right(character)
		else:
			face_character_left(character)
	else:
		if difference.y > 0.0:
			face_character_down(character)
		else:
			face_character_up(character)


func face_character_right(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation("idle_right"):
			sprite.play("idle_right")
			sprite.frame = 0
			sprite.pause()
		return

	var normal_sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if normal_sprite:
		normal_sprite.flip_h = false


func face_character_left(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation("idle_left"):
			sprite.play("idle_left")
			sprite.frame = 0
			sprite.pause()
		elif sprite.sprite_frames.has_animation("idle_right"):
			sprite.play("idle_right")
			sprite.frame = 0
			sprite.pause()
			sprite.flip_h = true
		return

	var normal_sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if normal_sprite:
		normal_sprite.flip_h = true


func face_character_up(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation("idle_up"):
			sprite.play("idle_up")
			sprite.frame = 0
			sprite.pause()
		return

	var normal_sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if normal_sprite:
		normal_sprite.flip_h = false


func face_character_down(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false

		if sprite.sprite_frames.has_animation("idle_down"):
			sprite.play("idle_down")
			sprite.frame = 0
			sprite.pause()
		return

	var normal_sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if normal_sprite:
		normal_sprite.flip_h = false


func get_character_texture(character: Node) -> Texture2D:
	var sprite := character.get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite and sprite.texture:
		return sprite.texture

	var animated_sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if animated_sprite and animated_sprite.sprite_frames:
		var animation_name: String = animated_sprite.animation
		var frame: int = animated_sprite.frame

		if animated_sprite.sprite_frames.has_animation(animation_name):
			var frame_count: int = animated_sprite.sprite_frames.get_frame_count(
				animation_name
			)

			if frame_count > 0:
				frame = clampi(
					frame,
					0,
					frame_count - 1
				)

				return animated_sprite.sprite_frames.get_frame_texture(
					animation_name,
					frame
				)

	return null


func transition_to_bookstore() -> void:
	var bookstore_paths := [
		"res://scenes/Bookstore.tscn",
		"res://scenes/bookstore.tscn",
		"res://scenes/main_level_scenes/Bookstore.tscn",
		"res://scenes/main_level_scenes/bookstore.tscn"
	]

	for scene_path in bookstore_paths:
		if ResourceLoader.exists(scene_path):
			await FadeManager.change_scene_with_fade(scene_path)
			return

	print("ERROR: Bookstore.tscn could not be found.")
