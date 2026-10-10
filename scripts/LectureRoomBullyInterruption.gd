extends Node

const BULLY_WALK_SPEED: float = 72.0
const BULLY_RUN_SPEED: float = 235.0
const SIR_CHARLES_WALK_SPEED: float = 72.0

const SPAWN_REACTION_DELAY: float = 2.0
const TARGET_DISTANCE: float = 1.0

const EXCLAMATION_POP_TIME: float = 0.28
const EXCLAMATION_HIDE_TIME: float = 0.18

const CAMERA_BULLIES_ZOOM: float = 1.65
const CAMERA_SIR_CHARLES_ZOOM: float = 2.0

const CAMERA_MOVE_TIME: float = 0.75
const SIR_CHARLES_FOCUS_TIME: float = 2.0
const CAMERA_RETURN_TIME: float = 0.8

const BULLY_MUSIC_VOLUME_DB: float = -4.0
const BULLY_DIALOGUE_VOLUME_DB: float = -18.0

const ACCEPT_LEFT_DISTANCE: float = 180.0

const JOE_HD = preload(
	"res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joe/Joe.png"
)

const JOEY_HD = preload(
	"res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joey/Joey.png"
)

const JOSEPH_HD = preload(
	"res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Bullies/Joseph/Joseph.png"
)

const PLAYER_HD = preload(
	"res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png"
)

const SIR_CHARLES_HD = preload(
	"res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Profs/Charles/Charles.png"
)

const BULLY_ENTRANCE_MUSIC = preload(
	"res://GAME ASSETS_/Misc/Music/bully_entrace_music.mp3"
)

@onready var player: CharacterBody2D = $"../Player"

@onready var joe: CharacterBody2D = $"../Joe"
@onready var joey: CharacterBody2D = $"../Joey"
@onready var joseph: CharacterBody2D = $"../Joseph"

@onready var cinematic_camera: Camera2D = $"../CinematicCamera"

var sir_charles: CharacterBody2D = null

var sir_charles_original_position: Vector2 = Vector2.ZERO
var sir_charles_original_visible: bool = false

var sir_charles_spawn0: Marker2D = null
var sir_charles_spawn1: Marker2D = null

var joe_spawn0: Marker2D = null
var joe_spawn1: Marker2D = null
var joe_spawn2: Marker2D = null
var joe_spawn3: Marker2D = null

var joey_spawn0: Marker2D = null
var joey_spawn1: Marker2D = null
var joey_spawn2: Marker2D = null
var joey_spawn3: Marker2D = null

var joseph_spawn0: Marker2D = null
var joseph_spawn1: Marker2D = null
var joseph_spawn2: Marker2D = null
var joseph_spawn3: Marker2D = null

var sequence_running: bool = false

var player_camera: Camera2D = null

var choice_result: int = 0

var bully_music: AudioStreamPlayer = null

var saved_camera_position: Vector2 = Vector2.ZERO
var saved_camera_zoom: Vector2 = Vector2.ONE

var saved_cinematic_camera_position: Vector2 = Vector2.ZERO
var saved_cinematic_camera_zoom: Vector2 = Vector2.ONE

var saved_player_camera_enabled: bool = false
var saved_cinematic_camera_enabled: bool = false

var saved_player_camera_current: bool = false
var saved_cinematic_camera_current: bool = false

var camera_state_saved: bool = false

var saved_player_physics_process: bool = true
var saved_player_process: bool = true

func _ready() -> void:
	if player != null:
		player_camera = player.get_node_or_null(
			"Camera2D"
		) as Camera2D

	_find_sir_charles()
	_find_spawn_markers()
	_setup_exclamation_labels()
	_setup_bully_music()

	if joe != null:
		joe.visible = false

	if joey != null:
		joey.visible = false

	if joseph != null:
		joseph.visible = false

func _find_sir_charles() -> void:
	var scene := get_tree().current_scene

	if scene == null:
		return

	var found: Node = scene.find_child(
		"Sir Charles",
		true,
		false
	)

	if found == null:
		found = scene.find_child(
			"Sir_Charles",
			true,
			false
		)

	if found is CharacterBody2D:
		sir_charles = found as CharacterBody2D
		sir_charles_original_position = sir_charles.global_position
		sir_charles_original_visible = sir_charles.visible
		sir_charles.visible = false

func _find_spawn_markers() -> void:
	var scene := get_tree().current_scene

	if scene == null:
		return

	sir_charles_spawn0 = _find_marker(
		scene,
		"SirCharlesSpawn0"
	)

	sir_charles_spawn1 = _find_marker(
		scene,
		"SirCharlesSpawn1"
	)

	joe_spawn0 = _find_marker(
		scene,
		"JoeSpawn0"
	)

	joe_spawn1 = _find_marker(
		scene,
		"JoeSpawn1"
	)

	joe_spawn2 = _find_marker(
		scene,
		"JoeSpawn2"
	)

	joe_spawn3 = _find_marker(
		scene,
		"JoeSpawn3"
	)

	joey_spawn0 = _find_marker(
		scene,
		"JoeySpawn0"
	)

	joey_spawn1 = _find_marker(
		scene,
		"JoeySpawn1"
	)

	joey_spawn2 = _find_marker(
		scene,
		"JoeySpawn2"
	)

	joey_spawn3 = _find_marker(
		scene,
		"JoeySpawn3"
	)

	joseph_spawn0 = _find_marker(
		scene,
		"JosephSpawn0"
	)

	joseph_spawn1 = _find_marker(
		scene,
		"JosephSpawn1"
	)

	joseph_spawn2 = _find_marker(
		scene,
		"JosephSpawn2"
	)

	joseph_spawn3 = _find_marker(
		scene,
		"JosephSpawn3"
	)

	if joseph_spawn0 == null:
		joseph_spawn0 = _find_marker(
			scene,
			"JospehSpawn0"
		)

	if joseph_spawn1 == null:
		joseph_spawn1 = _find_marker(
			scene,
			"JospehSpawn1"
		)

	if joseph_spawn2 == null:
		joseph_spawn2 = _find_marker(
			scene,
			"JospehSpawn2"
		)

	if joseph_spawn3 == null:
		joseph_spawn3 = _find_marker(
			scene,
			"JospehSpawn3"
		)

	if joe_spawn1 == null:
		joe_spawn1 = _find_marker(
			scene,
			"JoeSpawn"
		)

	if joey_spawn1 == null:
		joey_spawn1 = _find_marker(
			scene,
			"JoeySpawn"
		)

	if joseph_spawn1 == null:
		joseph_spawn1 = _find_marker(
			scene,
			"JospehSpawn"
		)

	print(
		"LectureRoomBullyInterruption markers:"
	)

	print(
		"Sir Charles: ",
		sir_charles_spawn0 != null,
		" / ",
		sir_charles_spawn1 != null
	)

	print(
		"Joe: ",
		joe_spawn0 != null,
		" / ",
		joe_spawn1 != null,
		" / ",
		joe_spawn2 != null,
		" / ",
		joe_spawn3 != null
	)

	print(
		"Joey: ",
		joey_spawn0 != null,
		" / ",
		joey_spawn1 != null,
		" / ",
		joey_spawn2 != null,
		" / ",
		joey_spawn3 != null
	)

	print(
		"Joseph: ",
		joseph_spawn0 != null,
		" / ",
		joseph_spawn1 != null,
		" / ",
		joseph_spawn2 != null,
		" / ",
		joseph_spawn3 != null
	)

func _find_marker(
	root: Node,
	marker_name: String
) -> Marker2D:
	if root == null:
		return null

	var found := root.find_child(
		marker_name,
		true,
		false
	)

	if found is Marker2D:
		return found as Marker2D

	return null

func _setup_exclamation_labels() -> void:
	_setup_single_exclamation(joe)
	_setup_single_exclamation(joey)
	_setup_single_exclamation(joseph)

func _setup_single_exclamation(
	bully: CharacterBody2D
) -> void:
	if bully == null:
		return

	var label := bully.get_node_or_null(
		"Exclamation"
	) as Label

	if label == null:
		label = Label.new()
		label.name = "Exclamation"
		bully.add_child(label)

	label.text = "!!"

	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	label.add_theme_font_size_override(
		"font_size",
		32
	)

	label.add_theme_color_override(
		"font_color",
		Color("#FFF1A8")
	)

	label.add_theme_color_override(
		"font_outline_color",
		Color("#231B18")
	)

	label.add_theme_constant_override(
		"outline_size",
		7
	)

	label.position = Vector2(
		-34.0,
		-52.0
	)

	label.size = Vector2(
		68.0,
		45.0
	)

	label.z_index = 100
	label.visible = false
	label.modulate.a = 0.0
	label.scale = Vector2.ZERO

func _setup_bully_music() -> void:
	if bully_music != null:
		return

	bully_music = AudioStreamPlayer.new()
	bully_music.name = "BullyEntranceMusic"
	bully_music.add_to_group("school_special_music")
	var bully_stream := BULLY_ENTRANCE_MUSIC as AudioStreamMP3
	if bully_stream != null:
		bully_stream.loop = true
	bully_music.stream = BULLY_ENTRANCE_MUSIC
	bully_music.volume_db = BULLY_MUSIC_VOLUME_DB
	bully_music.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(bully_music)

func _play_bully_music() -> void:
	_setup_bully_music()

	if bully_music == null:
		return

	bully_music.volume_db = BULLY_MUSIC_VOLUME_DB

	if not bully_music.playing:
		bully_music.play()

func _lower_bully_music_for_dialogue() -> void:
	if bully_music == null:
		return

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		bully_music,
		"volume_db",
		BULLY_DIALOGUE_VOLUME_DB,
		0.25
	)

	await tween.finished

func _restore_bully_music_after_dialogue() -> void:
	if bully_music == null:
		return

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		bully_music,
		"volume_db",
		BULLY_MUSIC_VOLUME_DB,
		0.3
	)

	await tween.finished

func _stop_bully_music() -> void:
	if bully_music == null:
		return

	if not bully_music.playing:
		return

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		bully_music,
		"volume_db",
		-30.0,
		0.5
	)

	await tween.finished

	bully_music.stop()

	bully_music.volume_db = BULLY_MUSIC_VOLUME_DB

func _save_camera_state() -> void:
	camera_state_saved = false

	if player_camera != null:
		saved_camera_position = player_camera.global_position
		saved_camera_zoom = player_camera.zoom
		saved_player_camera_enabled = player_camera.enabled
		saved_player_camera_current = player_camera.is_current()

	if cinematic_camera != null:
		saved_cinematic_camera_position = cinematic_camera.global_position
		saved_cinematic_camera_zoom = cinematic_camera.zoom
		saved_cinematic_camera_enabled = cinematic_camera.enabled
		saved_cinematic_camera_current = cinematic_camera.is_current()

	camera_state_saved = true

func _save_player_state() -> void:
	if player == null:
		return

	saved_player_physics_process = player.is_physics_processing()
	saved_player_process = player.is_processing()

func start_interruption() -> void:
	if sequence_running:
		return

	if GameManager.lecture_bully_interruption_done:
		return

	if player == null:
		print(
			"ERROR: LectureRoomBullyInterruption - Player missing."
		)
		return

	if joe == null \
	or joey == null \
	or joseph == null:
		print(
			"ERROR: LectureRoomBullyInterruption - One or more bullies missing."
		)
		return

	if joe_spawn0 == null \
	or joe_spawn1 == null \
	or joe_spawn2 == null \
	or joe_spawn3 == null:
		print(
			"ERROR: Joe Spawn markers are incomplete."
		)
		return

	if joey_spawn0 == null \
	or joey_spawn1 == null \
	or joey_spawn2 == null \
	or joey_spawn3 == null:
		print(
			"ERROR: Joey Spawn markers are incomplete."
		)
		return

	if joseph_spawn0 == null \
	or joseph_spawn1 == null \
	or joseph_spawn2 == null \
	or joseph_spawn3 == null:
		print(
			"ERROR: Joseph Spawn markers are incomplete."
		)
		return

	if sir_charles == null:
		print(
			"ERROR: Sir Charles node was not found."
		)
		return

	if sir_charles_spawn0 == null \
	or sir_charles_spawn1 == null:
		print(
			"ERROR: Sir Charles Spawn markers are incomplete."
		)
		return

	_save_camera_state()
	_save_player_state()

	sequence_running = true
	GameManager.player_controls_locked = true

	_play_bully_music()

	_stop_player()

	_stop_bully_physics(joe)
	_stop_bully_physics(joey)
	_stop_bully_physics(joseph)

	if sir_charles != null:
		sir_charles.velocity = Vector2.ZERO
		sir_charles.set_physics_process(false)
		sir_charles.visible = false

	await _prepare_cinematic_camera()

	await spawn_bullies_one_by_one()

	face_character_toward_character(
		joe,
		player
	)

	face_character_toward_character(
		joey,
		player
	)

	face_character_toward_character(
		joseph,
		player
	)

	await show_bully_exclamations()

	await move_bullies_to_spawn2()

	await start_bully_conversation()

	choice_result = await show_bully_choice()

	if choice_result == 1:
		GameManager.set_meta(
			"lecture_bully_choice",
			1
		)

		await start_bully_acceptance_dialogue()

		await move_bullies_left_after_accept()

	else:
		GameManager.set_meta(
			"lecture_bully_choice",
			2
		)

		await start_bully_decline_dialogue()

	await sir_charles_reveal_sequence()

	await start_sir_charles_reaction_dialogue()

	await run_bullies_to_spawn3()

	await _stop_bully_music()

	await start_sir_charles_dialogue()

	await move_sir_charles_back_to_spawn0()

	_remove_sir_charles()

	await restore_player_camera(
		CAMERA_RETURN_TIME
	)

	_restore_player()

	GameManager.lecture_bully_interruption_done = true
	GameManager.player_controls_locked = false
	sequence_running = false

func spawn_bullies_one_by_one() -> void:
	joe.global_position = joe_spawn0.global_position
	joe.visible = true

	face_character_toward_position(
		joe,
		joe_spawn1.global_position
	)

	await move_bully_to_marker(
		joe,
		joe_spawn1,
		BULLY_WALK_SPEED
	)

	await get_tree().create_timer(
		0.2
	).timeout

	joey.global_position = joey_spawn0.global_position
	joey.visible = true

	face_character_toward_position(
		joey,
		joey_spawn1.global_position
	)

	await move_bully_to_marker(
		joey,
		joey_spawn1,
		BULLY_WALK_SPEED
	)

	await get_tree().create_timer(
		0.2
	).timeout

	joseph.global_position = joseph_spawn0.global_position
	joseph.visible = true

	face_character_toward_position(
		joseph,
		joseph_spawn1.global_position
	)

	await move_bully_to_marker(
		joseph,
		joseph_spawn1,
		BULLY_WALK_SPEED
	)

	joe.global_position = joe_spawn1.global_position
	joey.global_position = joey_spawn1.global_position
	joseph.global_position = joseph_spawn1.global_position

func move_bully_to_marker(
	bully: CharacterBody2D,
	target: Marker2D,
	speed: float
) -> void:
	if bully == null or target == null:
		return

	var difference := (
		target.global_position
		- bully.global_position
	)

	if difference.length() <= 0.01:
		return

	_play_walk_animation(
		bully,
		difference
	)

	while (
		bully.global_position.distance_to(
			target.global_position
		)
		> TARGET_DISTANCE
	):
		var delta := get_process_delta_time()

		var movement := (
			target.global_position
			- bully.global_position
		)

		if movement.length() > 0.01:
			_play_walk_animation(
				bully,
				movement
			)

		bully.global_position = (
			bully.global_position.move_toward(
				target.global_position,
				speed * delta
			)
		)

		await get_tree().process_frame

	bully.global_position = target.global_position

	_pause_bully_animation(bully)

func move_bullies_to_spawn2() -> void:
	var targets := {
		joe: joe_spawn2,
		joey: joey_spawn2,
		joseph: joseph_spawn2
	}

	var finished := {
		joe: false,
		joey: false,
		joseph: false
	}

	_play_walk_animation(
		joe,
		joe_spawn2.global_position - joe.global_position
	)

	_play_walk_animation(
		joey,
		joey_spawn2.global_position - joey.global_position
	)

	_play_walk_animation(
		joseph,
		joseph_spawn2.global_position - joseph.global_position
	)

	while not (
		finished[joe]
		and finished[joey]
		and finished[joseph]
	):
		var delta := get_process_delta_time()

		for bully in targets:
			if finished[bully]:
				continue

			var bully_character := (
				bully as CharacterBody2D
			)

			var target_marker := (
				targets[bully] as Marker2D
			)

			if bully_character == null \
			or target_marker == null:
				finished[bully] = true
				continue

			var difference := (
				target_marker.global_position
				- bully_character.global_position
			)

			if difference.length() > 0.01:
				_play_walk_animation(
					bully_character,
					difference
				)

			bully_character.global_position = (
				bully_character.global_position.move_toward(
					target_marker.global_position,
					BULLY_WALK_SPEED * delta
				)
			)

			if (
				bully_character.global_position.distance_to(
					target_marker.global_position
				)
				<= TARGET_DISTANCE
			):
				bully_character.global_position = (
					target_marker.global_position
				)

				finished[bully] = true

				_pause_bully_animation(
					bully_character
				)

		_update_camera_on_bully_group(delta)

		await get_tree().process_frame

	joe.global_position = joe_spawn2.global_position
	joey.global_position = joey_spawn2.global_position
	joseph.global_position = joseph_spawn2.global_position

	face_character_toward_character(
		joe,
		player
	)

	face_character_toward_character(
		joey,
		player
	)

	face_character_toward_character(
		joseph,
		player
	)

	await get_tree().create_timer(
		0.35
	).timeout

func _update_camera_on_bully_group(
	delta: float
) -> void:
	if cinematic_camera == null:
		return

	var center: Vector2 = (
		joe.global_position
		+ joey.global_position
		+ joseph.global_position
		+ player.global_position
	) / 4.0

	cinematic_camera.global_position = (
		cinematic_camera.global_position.lerp(
			center,
			clampf(
				delta * 5.0,
				0.0,
				1.0
			)
		)
	)

func start_bully_conversation() -> void:
	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD,
		"Player": PLAYER_HD
	}

	var dialogue := [
		{
			"speaker": "Joe",
			"text": "Hey."
		},
		{
			"speaker": "Player",
			"text": "Uh... what's up?"
		},
		{
			"speaker": "Joey",
			"text": "We've been looking for you."
		},
		{
			"speaker": "Player",
			"text": "Why?"
		},
		{
			"speaker": "Joseph",
			"text": "We're heading somewhere after class."
		},
		{
			"speaker": "Joe",
			"text": "You should come with us."
		},
		{
			"speaker": "Player",
			"text": "Where are you guys going?"
		},
		{
			"speaker": "Joey",
			"text": "You'll find out."
		},
		{
			"speaker": "Joseph",
			"text": "Come on. Don't overthink it."
		}
	]

	await _lower_bully_music_for_dialogue()

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await _restore_bully_music_after_dialogue()

func show_bully_choice() -> int:
	var choice_script = preload(
		"res://scripts/PolishedChoiceUI.gd"
	)

	var choice_ui := choice_script.new()

	choice_ui.layer = 4096

	choice_ui.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	get_tree().root.add_child(
		choice_ui
	)

	await get_tree().process_frame

	var result := await choice_ui.show_choice(
		"Come with the bullies?",
		"They are heading somewhere instead of going straight to class.",
		"Yes, I'll come",
		"No, I have class",
		1,
		2
	)

	if is_instance_valid(choice_ui):
		choice_ui.queue_free()

	return int(result)

func start_bully_acceptance_dialogue() -> void:
	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD,
		"Player": PLAYER_HD
	}

	var dialogue := [
		{
			"speaker": "Joe",
			"text": "That's what I'm talking about."
		},
		{
			"speaker": "Joey",
			"text": "Good. You won't regret it."
		},
		{
			"speaker": "Player",
			"text": "So where are we actually going?"
		},
		{
			"speaker": "Joseph",
			"text": "Just keep up with us."
		},
		{
			"speaker": "Player",
			"text": "You guys are being really vague."
		},
		{
			"speaker": "Joe",
			"text": "You'll see soon enough."
		},
		{
			"speaker": "Joey",
			"text": "Come on. Let's go."
		}
	]

	await _lower_bully_music_for_dialogue()

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await _restore_bully_music_after_dialogue()

func start_bully_decline_dialogue() -> void:
	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD,
		"Player": PLAYER_HD
	}

	var dialogue := [
		{
			"speaker": "Joe",
			"text": "What did you just say?"
		},
		{
			"speaker": "Player",
			"text": "I said I have class."
		},
		{
			"speaker": "Joey",
			"text": "You really think you can just say no to us?"
		},
		{
			"speaker": "Joseph",
			"text": "We've been asking you nicely."
		},
		{
			"speaker": "Joe",
			"text": "Keep acting like that and you're going to regret it."
		},
		{
			"speaker": "Joey",
			"text": "Maybe we should teach you a lesson."
		},
		{
			"speaker": "Player",
			"text": "..."
		},
		{
			"speaker": "Joseph",
			"text": "Yeah. That's what I thought."
		}
	]

	await _lower_bully_music_for_dialogue()

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await _restore_bully_music_after_dialogue()

func move_bullies_left_after_accept() -> void:
	var target_joe := joe.global_position + Vector2(
		-ACCEPT_LEFT_DISTANCE,
		0.0
	)

	var target_joey := joey.global_position + Vector2(
		-ACCEPT_LEFT_DISTANCE,
		0.0
	)

	var target_joseph := joseph.global_position + Vector2(
		-ACCEPT_LEFT_DISTANCE,
		0.0
	)

	var targets := {
		joe: target_joe,
		joey: target_joey,
		joseph: target_joseph
	}

	var finished := {
		joe: false,
		joey: false,
		joseph: false
	}

	_play_walk_animation(
		joe,
		target_joe - joe.global_position
	)

	_play_walk_animation(
		joey,
		target_joey - joey.global_position
	)

	_play_walk_animation(
		joseph,
		target_joseph - joseph.global_position
	)

	while not (
		finished[joe]
		and finished[joey]
		and finished[joseph]
	):
		var delta := get_process_delta_time()

		for bully in targets:
			if finished[bully]:
				continue

			var bully_character := (
				bully as CharacterBody2D
			)

			if bully_character == null:
				finished[bully] = true
				continue

			var target_position: Vector2 = targets[bully]

			var difference := (
				target_position
				- bully_character.global_position
			)

			if difference.length() > 0.01:
				_play_walk_animation(
					bully_character,
					difference
				)

			bully_character.global_position = (
				bully_character.global_position.move_toward(
					target_position,
					BULLY_WALK_SPEED * delta
				)
			)

			if (
				bully_character.global_position.distance_to(
					target_position
				)
				<= TARGET_DISTANCE
			):
				bully_character.global_position = target_position
				finished[bully] = true

				_pause_bully_animation(
					bully_character
				)

		_update_camera_on_bully_group(delta)

		await get_tree().process_frame

	face_character_toward_position(
		joe,
		sir_charles_spawn0.global_position
	)

	face_character_toward_position(
		joey,
		sir_charles_spawn0.global_position
	)

	face_character_toward_position(
		joseph,
		sir_charles_spawn0.global_position
	)

	await get_tree().create_timer(
		0.4
	).timeout

func sir_charles_reveal_sequence() -> void:
	if sir_charles == null:
		return

	if sir_charles_spawn0 == null:
		return

	if sir_charles_spawn1 == null:
		return

	sir_charles.global_position = (
		sir_charles_spawn0.global_position
	)

	sir_charles.visible = true

	if cinematic_camera != null:
		cinematic_camera.enabled = true
		cinematic_camera.make_current()

	await move_sir_charles_to_spawn1()

	face_character_toward_character(
		sir_charles,
		player
	)

	await get_tree().create_timer(
		SIR_CHARLES_FOCUS_TIME
	).timeout

func move_sir_charles_to_spawn1() -> void:
	if sir_charles == null:
		return

	if sir_charles_spawn0 == null \
	or sir_charles_spawn1 == null:
		return

	var target_position := (
		sir_charles_spawn1.global_position
	)

	var start_camera_position := (
		cinematic_camera.global_position
		if cinematic_camera != null
		else sir_charles.global_position
	)

	var start_zoom := (
		cinematic_camera.zoom
		if cinematic_camera != null
		else Vector2(1.3, 1.3)
	)

	var target_zoom := Vector2(
		CAMERA_SIR_CHARLES_ZOOM,
		CAMERA_SIR_CHARLES_ZOOM
	)

	var total_distance := (
		sir_charles.global_position.distance_to(
			target_position
		)
	)

	var walk_duration: float = maxf(
		total_distance / SIR_CHARLES_WALK_SPEED,
		0.8
	)

	var elapsed: float = 0.0

	_play_walk_animation(
		sir_charles,
		target_position - sir_charles.global_position
	)

	while elapsed < walk_duration:
		var delta := get_process_delta_time()

		elapsed += delta

		var progress := clampf(
			elapsed / walk_duration,
			0.0,
			1.0
		)

		sir_charles.global_position = (
			sir_charles.global_position.move_toward(
				target_position,
				SIR_CHARLES_WALK_SPEED * delta
			)
		)

		if cinematic_camera != null:
			var camera_target := (
				sir_charles.global_position
			)

			cinematic_camera.global_position = camera_target

			cinematic_camera.zoom = (
				start_zoom.lerp(
					target_zoom,
					progress
				)
			)

		await get_tree().process_frame

	sir_charles.global_position = target_position

	if cinematic_camera != null:
		cinematic_camera.global_position = (
			sir_charles.global_position
		)

		cinematic_camera.zoom = target_zoom

	_pause_bully_animation(
		sir_charles
	)

func start_sir_charles_reaction_dialogue() -> void:
	var portraits: Dictionary = {
		"Joe": JOE_HD,
		"Joey": JOEY_HD,
		"Joseph": JOSEPH_HD,
		"Player": PLAYER_HD,
		"Sir Charles": SIR_CHARLES_HD
	}

	var dialogue := [
		{
			"speaker": "Joe",
			"text": "Oh shoot!"
		},
		{
			"speaker": "Joey",
			"text": "It's Sir Charles!"
		},
		{
			"speaker": "Joseph",
			"text": "We're in trouble!"
		},
		{
			"speaker": "Joe",
			"text": "Come on, guys!"
		},
		{
			"speaker": "Joey",
			"text": "Run!"
		}
	]

	await _lower_bully_music_for_dialogue()

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await _restore_bully_music_after_dialogue()

func run_bullies_to_spawn3() -> void:
	var targets := {
		joe: joe_spawn3,
		joey: joey_spawn3,
		joseph: joseph_spawn3
	}

	var finished := {
		joe: false,
		joey: false,
		joseph: false
	}

	_play_run_animation(
		joe,
		joe_spawn3.global_position - joe.global_position
	)

	_play_run_animation(
		joey,
		joey_spawn3.global_position - joey.global_position
	)

	_play_run_animation(
		joseph,
		joseph_spawn3.global_position - joseph.global_position
	)

	while not (
		finished[joe]
		and finished[joey]
		and finished[joseph]
	):
		var delta := get_process_delta_time()

		for bully in targets:
			if finished[bully]:
				continue

			var bully_character := (
				bully as CharacterBody2D
			)

			var target_marker := (
				targets[bully] as Marker2D
			)

			if bully_character == null \
			or target_marker == null:
				finished[bully] = true
				continue

			var difference := (
				target_marker.global_position
				- bully_character.global_position
			)

			if difference.length() > 0.01:
				_play_run_animation(
					bully_character,
					difference
				)

			bully_character.global_position = (
				bully_character.global_position.move_toward(
					target_marker.global_position,
					BULLY_RUN_SPEED * delta
				)
			)

			if (
				bully_character.global_position.distance_to(
					target_marker.global_position
				)
				<= TARGET_DISTANCE
			):
				bully_character.global_position = (
					target_marker.global_position
				)

				finished[bully] = true

				_remove_bully_from_scene(
					bully_character
				)

		await get_tree().process_frame

func _remove_bully_from_scene(
	bully: CharacterBody2D
) -> void:
	if bully == null:
		return

	bully.collision_layer = 0
	bully.collision_mask = 0

	var collision_nodes := bully.find_children(
		"*",
		"CollisionShape2D",
		true,
		false
	)

	for node in collision_nodes:
		var shape := node as CollisionShape2D

		if shape != null:
			shape.set_deferred(
				"disabled",
				true
			)

	var polygon_nodes := bully.find_children(
		"*",
		"CollisionPolygon2D",
		true,
		false
	)

	for node in polygon_nodes:
		var polygon := node as CollisionPolygon2D

		if polygon != null:
			polygon.set_deferred(
				"disabled",
				true
			)

	bully.velocity = Vector2.ZERO
	bully.set_physics_process(false)

	_pause_bully_animation(
		bully
	)

	bully.visible = false

func start_sir_charles_dialogue() -> void:
	var portraits: Dictionary = {
		"Player": PLAYER_HD,
		"Sir Charles": SIR_CHARLES_HD
	}

	var dialogue := [
		{
			"speaker": "Sir Charles",
			"text": "Hey."
		},
		{
			"speaker": "Player",
			"text": "Sir Charles..."
		},
		{
			"speaker": "Sir Charles",
			"text": "Were those the students who were bothering you?"
		},
		{
			"speaker": "Player",
			"text": "Yeah. They were asking me to go somewhere with them."
		},
		{
			"speaker": "Sir Charles",
			"text": "I see."
		},
		{
			"speaker": "Sir Charles",
			"text": "Be careful around those three."
		},
		{
			"speaker": "Sir Charles",
			"text": "If they try anything again, come find me."
		},
		{
			"speaker": "Player",
			"text": "Okay, Sir Charles."
		}
	]

	await _lower_bully_music_for_dialogue()

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	await _restore_bully_music_after_dialogue()

func move_sir_charles_back_to_spawn0() -> void:
	if sir_charles == null:
		return

	if sir_charles_spawn0 == null:
		return

	var target_position := (
		sir_charles_spawn0.global_position
	)

	_play_walk_animation(
		sir_charles,
		target_position - sir_charles.global_position
	)

	while (
		sir_charles.global_position.distance_to(
			target_position
		)
		> TARGET_DISTANCE
	):
		var delta := get_process_delta_time()

		var difference := (
			target_position
			- sir_charles.global_position
		)

		if difference.length() > 0.01:
			_play_walk_animation(
				sir_charles,
				difference
			)

		sir_charles.global_position = (
			sir_charles.global_position.move_toward(
				target_position,
				SIR_CHARLES_WALK_SPEED * delta
			)
		)

		if cinematic_camera != null:
			cinematic_camera.global_position = (
				cinematic_camera.global_position.lerp(
					sir_charles.global_position,
					clampf(
						delta * 5.0,
						0.0,
						1.0
					)
				)
			)

		await get_tree().process_frame

	sir_charles.global_position = target_position

	_pause_bully_animation(
		sir_charles
	)

func _remove_sir_charles() -> void:
	if sir_charles == null:
		return

	sir_charles.velocity = Vector2.ZERO
	sir_charles.set_physics_process(false)
	sir_charles.visible = false

func show_bully_exclamations() -> void:
	var labels: Array[Label] = []

	var joe_label := joe.get_node_or_null(
		"Exclamation"
	) as Label

	if joe_label != null:
		labels.append(joe_label)

	var joey_label := joey.get_node_or_null(
		"Exclamation"
	) as Label

	if joey_label != null:
		labels.append(joey_label)

	var joseph_label := joseph.get_node_or_null(
		"Exclamation"
	) as Label

	if joseph_label != null:
		labels.append(joseph_label)

	for label in labels:
		label.visible = true
		label.modulate.a = 0.0
		label.scale = Vector2.ZERO

		var tween := create_tween()

		tween.set_trans(
			Tween.TRANS_BACK
		)

		tween.set_ease(
			Tween.EASE_OUT
		)

		tween.parallel().tween_property(
			label,
			"modulate:a",
			1.0,
			0.12
		)

		tween.parallel().tween_property(
			label,
			"scale",
			Vector2.ONE,
			EXCLAMATION_POP_TIME
		)

	await get_tree().create_timer(
		SPAWN_REACTION_DELAY
	).timeout

	for label in labels:
		var tween := create_tween()

		tween.set_trans(
			Tween.TRANS_BACK
		)

		tween.set_ease(
			Tween.EASE_IN
		)

		tween.parallel().tween_property(
			label,
			"scale",
			Vector2.ZERO,
			EXCLAMATION_HIDE_TIME
		)

		tween.parallel().tween_property(
			label,
			"modulate:a",
			0.0,
			EXCLAMATION_HIDE_TIME
		)

		await tween.finished

		label.visible = false

func _stop_player() -> void:
	if player == null:
		return

	player.velocity = Vector2.ZERO
	player.set_physics_process(false)

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite != null:
		sprite.pause()

func _restore_player() -> void:
	if player == null:
		return

	player.set_physics_process(
		saved_player_physics_process
	)

	player.set_process(
		saved_player_process
	)

	player.velocity = Vector2.ZERO

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite != null:
		if not sprite.is_playing():
			var idle_animation := _find_player_idle_animation(
				sprite
			)

			if idle_animation != "":
				sprite.play(
					idle_animation
				)

func _find_player_idle_animation(
	sprite: AnimatedSprite2D
) -> String:
	if sprite == null:
		return ""

	var possible_animations := [
		"idle_down",
		"idle_down_left",
		"idle_down_right",
		"idle_right",
		"idle_left",
		"idle_up",
		"idle"
	]

	for animation_name in possible_animations:
		if sprite.sprite_frames.has_animation(
			animation_name
		):
			return animation_name

	return ""

func _stop_bully_physics(
	bully: CharacterBody2D
) -> void:
	if bully == null:
		return

	bully.velocity = Vector2.ZERO
	bully.set_physics_process(false)

func _play_walk_animation(
	bully: CharacterBody2D,
	direction: Vector2
) -> void:
	if bully == null:
		return

	if direction.length() <= 0.01:
		return

	var sprite := bully.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := _get_direction_animation(
		direction,
		"walk_"
	)

	if sprite.sprite_frames.has_animation(
		animation_name
	):
		sprite.speed_scale = 1.0

		if sprite.animation != animation_name \
		or not sprite.is_playing():
			sprite.play(
				animation_name
			)

func _play_run_animation(
	bully: CharacterBody2D,
	direction: Vector2
) -> void:
	if bully == null:
		return

	if direction.length() <= 0.01:
		return

	var sprite := bully.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := _get_direction_animation(
		direction,
		"walk_"
	)

	if sprite.sprite_frames.has_animation(
		animation_name
	):
		sprite.speed_scale = 1.45

		if sprite.animation != animation_name \
		or not sprite.is_playing():
			sprite.play(
				animation_name
			)

func _pause_bully_animation(
	bully: CharacterBody2D
) -> void:
	if bully == null:
		return

	var sprite := bully.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	sprite.pause()
	sprite.speed_scale = 1.0

func _get_direction_animation(
	direction: Vector2,
	prefix: String
) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0.0:
			return prefix + "right"

		return prefix + "left"

	if direction.y > 0.0:
		return prefix + "down"

	return prefix + "up"

func face_character_toward_character(
	character: CharacterBody2D,
	target_character: CharacterBody2D
) -> void:
	if character == null \
	or target_character == null:
		return

	face_character_toward_position(
		character,
		target_character.global_position
	)

func face_character_toward_position(
	character: CharacterBody2D,
	target_position: Vector2
) -> void:
	if character == null:
		return

	var difference := (
		target_position
		- character.global_position
	)

	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := _get_direction_animation(
		difference,
		"idle_"
	)

	if sprite.sprite_frames.has_animation(
		animation_name
	):
		sprite.play(
			animation_name
		)

		sprite.pause()

func _prepare_cinematic_camera() -> void:
	if cinematic_camera == null:
		return

	if player_camera != null:
		cinematic_camera.global_position = (
			player_camera.global_position
		)

		cinematic_camera.zoom = (
			player_camera.zoom
		)

	else:
		cinematic_camera.global_position = (
			player.global_position
		)

		cinematic_camera.zoom = Vector2(
			1.3,
			1.3
		)

	cinematic_camera.enabled = true
	cinematic_camera.make_current()

	if player_camera != null:
		player_camera.enabled = false

	await get_tree().process_frame

func restore_player_camera(
	duration: float
) -> void:
	if cinematic_camera == null:
		return

	if not camera_state_saved:
		if player_camera != null:
			cinematic_camera.global_position = (
				player_camera.global_position
			)

			cinematic_camera.zoom = (
				player_camera.zoom
			)

		cinematic_camera.enabled = false

		if player_camera != null:
			player_camera.enabled = true
			player_camera.make_current()

		return

	var target_position := saved_camera_position
	var target_zoom := saved_camera_zoom

	var tween := create_tween()

	tween.set_parallel(true)

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.tween_property(
		cinematic_camera,
		"global_position",
		target_position,
		duration
	)

	tween.tween_property(
		cinematic_camera,
		"zoom",
		target_zoom,
		duration
	)

	await tween.finished

	cinematic_camera.global_position = (
		target_position
	)

	cinematic_camera.zoom = (
		target_zoom
	)

	cinematic_camera.enabled = (
		saved_cinematic_camera_enabled
	)

	if player_camera != null:
		player_camera.global_position = (
			target_position
		)

		player_camera.zoom = (
			target_zoom
		)

		player_camera.enabled = (
			saved_player_camera_enabled
		)

	if player_camera != null:
		player_camera.enabled = true
		player_camera.make_current()

	if player_camera != null:
		player_camera.global_position = (
			target_position
		)

		player_camera.zoom = (
			target_zoom
		)
