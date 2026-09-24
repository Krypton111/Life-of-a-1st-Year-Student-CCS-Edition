extends Node

@onready var player: CharacterBody2D = $"../Player"

@onready var joe: CharacterBody2D = $"../Joe"
@onready var joey: CharacterBody2D = $"../Joey"
@onready var joseph: CharacterBody2D = $"../Joseph"

@onready var cinematic_camera: Camera2D = $"../CinematicCamera"

@onready var top_bar: ColorRect = $"../CinematicUI/TopBar"
@onready var bottom_bar: ColorRect = $"../CinematicUI/BottomBar"

@onready var joe_exclamation: Label = $"../Joe/Exclamation"
@onready var joey_exclamation: Label = $"../Joey/Exclamation"
@onready var joseph_exclamation: Label = $"../Joseph/Exclamation"

var running: bool = false
var player_camera: Camera2D = null

const JOE_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joe/Joe.png")
const JOEY_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joey/Joey.png")
const JOSEPH_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joseph/Joseph.png")
const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")


func _ready() -> void:
	top_bar.visible = false
	bottom_bar.visible = false

	joe_exclamation.visible = false
	joey_exclamation.visible = false
	joseph_exclamation.visible = false

	joe.visible = false
	joey.visible = false
	joseph.visible = false

	cinematic_camera.enabled = false

	player_camera = player.get_node_or_null("Camera2D") as Camera2D

	await get_tree().process_frame

	if GameManager.quiz_completed and not GameManager.bullies_encounter_done:
		await get_tree().create_timer(0.3).timeout
		await start_encounter()

func start_encounter() -> void:
	if running:
		return

	running = true

	GameManager.player_controls_locked = true

	joe.visible = true
	joey.visible = true
	joseph.visible = true

	stop_player()
	stop_bullies()

	await show_cinematic_bars()
	await focus_on_bullies()
	await bullies_notice_player()
	await bullies_approach_player()

	await start_bully_dialogue()

	await return_camera_to_player()
	await bullies_walk_offscreen()

	GameManager.bullies_encounter_done = true

	GameManager.player_controls_locked = false
	player.set_physics_process(true)

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

func stop_bullies() -> void:
	joe.set_physics_process(false)
	joey.set_physics_process(false)
	joseph.set_physics_process(false)


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
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		bottom_bar,
		"position:y",
		viewport_size.y - bar_height,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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


func focus_on_bullies() -> void:
	var bully_center: Vector2 = (
		joe.global_position
		+ joey.global_position
		+ joseph.global_position
	) / 3.0

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
		bully_center,
		1.4
	)

	await tween.finished


func bullies_notice_player() -> void:
	joe_exclamation.visible = true
	joey_exclamation.visible = true
	joseph_exclamation.visible = true

	joe_exclamation.scale = Vector2.ZERO
	joey_exclamation.scale = Vector2.ZERO
	joseph_exclamation.scale = Vector2.ZERO

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		joe_exclamation,
		"scale",
		Vector2.ONE,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		joey_exclamation,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		joseph_exclamation,
		"scale",
		Vector2.ONE,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	await get_tree().create_timer(0.45).timeout

	face_character_toward_player(joe)
	face_character_toward_player(joey)
	face_character_toward_player(joseph)

	await get_tree().create_timer(0.4).timeout

	joe_exclamation.visible = false
	joey_exclamation.visible = false
	joseph_exclamation.visible = false


func bullies_approach_player() -> void:
	var player_position: Vector2 = player.global_position

	var joe_target: Vector2 = player_position + Vector2(-85.0, -25.0)
	var joey_target: Vector2 = player_position + Vector2(0.0, 65.0)
	var joseph_target: Vector2 = player_position + Vector2(85.0, -25.0)

	var walk_speed: float = 55.0

	var joe_finished := false
	var joey_finished := false
	var joseph_finished := false

	while not (joe_finished and joey_finished and joseph_finished):
		var delta: float = get_process_delta_time()

		if not joe_finished:
			update_bully_walk_direction(joe)

			joe.global_position = joe.global_position.move_toward(
				joe_target,
				walk_speed * delta
			)

			if joe.global_position.distance_to(joe_target) <= 1.0:
				joe.global_position = joe_target
				joe_finished = true
				face_character_toward_player(joe)

		if not joey_finished:
			update_bully_walk_direction(joey)

			joey.global_position = joey.global_position.move_toward(
				joey_target,
				walk_speed * delta
			)

			if joey.global_position.distance_to(joey_target) <= 1.0:
				joey.global_position = joey_target
				joey_finished = true
				face_character_toward_player(joey)

		if not joseph_finished:
			update_bully_walk_direction(joseph)

			joseph.global_position = joseph.global_position.move_toward(
				joseph_target,
				walk_speed * delta
			)

			if joseph.global_position.distance_to(joseph_target) <= 1.0:
				joseph.global_position = joseph_target
				joseph_finished = true
				face_character_toward_player(joseph)

		var bully_center: Vector2 = (
			joe.global_position
			+ joey.global_position
			+ joseph.global_position
		) / 3.0

		var camera_follow_speed: float = 4.0

		cinematic_camera.global_position = cinematic_camera.global_position.lerp(
			bully_center,
			min(1.0, camera_follow_speed * delta)
		)

		await get_tree().process_frame

	pause_bully_animation()

	face_character_toward_player(joe)
	face_character_toward_player(joey)
	face_character_toward_player(joseph)

	await get_tree().create_timer(0.4).timeout


func update_bully_walk_direction(character: CharacterBody2D) -> void:
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


func pause_bully_animation() -> void:
	pause_animation(joe)
	pause_animation(joey)
	pause_animation(joseph)


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


func pause_animation(character: CharacterBody2D) -> void:
	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()


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


func return_camera_to_player() -> void:
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		player.global_position,
		1.0
	)

	await tween.finished

	cinematic_camera.global_position = player.global_position

func bullies_walk_offscreen() -> void:
	var walk_speed: float = 55.0

	play_animation(joe, "walk_right")
	play_animation(joey, "walk_right")
	play_animation(joseph, "walk_right")

	face_character_right(player)

	var camera_position: Vector2 = cinematic_camera.global_position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	var screen_distance: float = viewport_size.x * 0.7

	var joe_target := Vector2(
		camera_position.x + screen_distance,
		joe.global_position.y
	)

	var joey_target := Vector2(
		camera_position.x + screen_distance,
		joey.global_position.y
	)

	var joseph_target := Vector2(
		camera_position.x + screen_distance,
		joseph.global_position.y
	)

	var joe_finished := false
	var joey_finished := false
	var joseph_finished := false

	while not (joe_finished and joey_finished and joseph_finished):
		var delta: float = get_process_delta_time()

		face_character_right(player)

		if not joe_finished:
			joe.global_position = joe.global_position.move_toward(
				joe_target,
				walk_speed * delta
			)

			if joe.global_position.distance_to(joe_target) <= 1.0:
				joe.global_position = joe_target
				joe_finished = true

		if not joey_finished:
			joey.global_position = joey.global_position.move_toward(
				joey_target,
				walk_speed * delta
			)

			if joey.global_position.distance_to(joey_target) <= 1.0:
				joey.global_position = joey_target
				joey_finished = true

		if not joseph_finished:
			joseph.global_position = joseph.global_position.move_toward(
				joseph_target,
				walk_speed * delta
			)

			if joseph.global_position.distance_to(joseph_target) <= 1.0:
				joseph.global_position = joseph_target
				joseph_finished = true

		await get_tree().process_frame

	pause_bully_animation()

	await get_tree().create_timer(0.2).timeout
	
	joe.visible = false
	joey.visible = false
	joseph.visible = false

	await hide_cinematic_bars()

	await restore_player_camera()

func restore_player_camera() -> void:
	if player_camera == null:
		return

	cinematic_camera.enabled = false

	await get_tree().process_frame

	player_camera.enabled = true
	player_camera.make_current()

	await get_tree().process_frame

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
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(
		bottom_bar,
		"position:y",
		viewport_size.y,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

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


func start_bully_dialogue() -> void:
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
			"text": "Are you talking to me?"
		},
		{
			"speaker": "Joey",
			"text": "Who else would we be talking to?"
		},
		{
			"speaker": "Player",
			"text": "I don't even know you guys."
		},
		{
			"speaker": "Joseph",
			"text": "You don't have to know us. We've already noticed you."
		},
		{
			"speaker": "Player",
			"text": "Noticed me?"
		},
		{
			"speaker": "Joe",
			"text": "Yeah. You're the new student, right?"
		},
		{
			"speaker": "Player",
			"text": "I guess you could say that."
		},
		{
			"speaker": "Joey",
			"text": "You've been walking around this hallway like you don't know where you're going."
		},
		{
			"speaker": "Player",
			"text": "I'm just trying to find my way around."
		},
		{
			"speaker": "Joseph",
			"text": "You should probably get used to the place quickly."
		},
		{
			"speaker": "Player",
			"text": "I'm sure I'll figure it out."
		},
		{
			"speaker": "Joe",
			"text": "Maybe. But the campus isn't always as easy to figure out as you think."
		},
		{
			"speaker": "Player",
			"text": "And what exactly are you trying to tell me?"
		},
		{
			"speaker": "Joey",
			"text": "We're just giving you some advice."
		},
		{
			"speaker": "Player",
			"text": "Advice usually doesn't involve three people surrounding someone."
		},
		{
			"speaker": "Joseph",
			"text": "You caught that, huh?"
		},
		{
			"speaker": "Player",
			"text": "Kind of hard not to."
		},
		{
			"speaker": "Joe",
			"text": "You seem pretty confident for someone who's new here."
		},
		{
			"speaker": "Player",
			"text": "I'm not trying to cause trouble."
		},
		{
			"speaker": "Joey",
			"text": "Neither are we."
		},
		{
			"speaker": "Player",
			"text": "Then why stop me?"
		},
		{
			"speaker": "Joseph",
			"text": "Because we wanted to know what kind of person you are."
		},
		{
			"speaker": "Player",
			"text": "You could have just asked."
		},
		{
			"speaker": "Joe",
			"text": "Would you have answered?"
		},
		{
			"speaker": "Player",
			"text": "Probably."
		},
		{
			"speaker": "Joey",
			"text": "Maybe we should have tried that first."
		},
		{
			"speaker": "Joseph",
			"text": "Too late now."
		},
		{
			"speaker": "Player",
			"text": "So what do you actually want?"
		},
		{
			"speaker": "Joe",
			"text": "We just want you to know how things work around here."
		},
		{
			"speaker": "Player",
			"text": "And you three are supposed to teach me?"
		},
		{
			"speaker": "Joey",
			"text": "Think of us as your unofficial orientation committee."
		},
		{
			"speaker": "Player",
			"text": "That doesn't sound very official."
		},
		{
			"speaker": "Joseph",
			"text": "Because it isn't."
		},
		{
			"speaker": "Player",
			"text": "Right."
		},
		{
			"speaker": "Joe",
			"text": "Just watch where you go and who you trust."
		},
		{
			"speaker": "Player",
			"text": "Is that a warning?"
		},
		{
			"speaker": "Joey",
			"text": "Call it whatever you want."
		},
		{
			"speaker": "Player",
			"text": "I don't scare that easily."
		},
		{
			"speaker": "Joseph",
			"text": "Nobody said you should be scared."
		},
		{
			"speaker": "Player",
			"text": "You certainly aren't making yourselves look friendly."
		},
		{
			"speaker": "Joe",
			"text": "We're not here to make friends."
		},
		{
			"speaker": "Player",
			"text": "Then we're done here, right?"
		},
		{
			"speaker": "Joey",
			"text": "For now."
		},
		{
			"speaker": "Player",
			"text": "Good."
		},
		{
			"speaker": "Joseph",
			"text": "We'll probably see you again."
		},
		{
			"speaker": "Player",
			"text": "I'd rather not."
		},
		{
			"speaker": "Joe",
			"text": "See you around, freshman."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished
