extends Node

# HOUSE OPENING CONTROLLER

@onready var player: CharacterBody2D = $"../Player"

const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")

const PANIC_WALK_SPEED: float = 255.0
const PANIC_FOOTSTEP_INTERVAL: float = 0.18
const PANIC_POINT_REACHED_DISTANCE: float = 12.0
const PANIC_POINT_STUCK_TIME: float = 0.45
const PANIC_NAVIGATION_RADIUS: float = 12.0
const PANIC_NAVIGATION_PATH_DISTANCE: float = 4.0
const PANIC_NAVIGATION_TARGET_DISTANCE: float = 8.0
const PANIC_NAVIGATION_MAX_SPEED: float = 255.0

const SKIPPABLE_MONOLOGUE_SPEED: float = 0.035
const CALM_MONOLOGUE_SPEED: float = 0.035

const AUTO_PANIC_SPEEDS: Array[float] = [
	0.032,
	0.028,
	0.024,
	0.020,
	0.016,
	0.012,
	0.009,
	0.006,
	0.003
]

const AUTO_PANIC_PAUSES: Array[float] = [
	0.18,
	0.16,
	0.14,
	0.12,
	0.10,
	0.08,
	0.06,
	0.04
]

var transparent_texture: Texture2D = null
var panic_route: Array[Marker2D] = []
var panic_route_running: bool = false
var panic_footstep_timer: float = 0.0
var panic_navigation_agent: NavigationAgent2D = null


func _ready() -> void:

	if GameManager.house_opening_completed:
		return

	if player == null:
		print("ERROR: HouseOpeningController could not find Player.")
		return

	transparent_texture = create_transparent_texture()
	load_panic_route()
	setup_panic_navigation()

	await get_tree().process_frame
	await get_tree().process_frame

	await start_house_opening()


func start_house_opening() -> void:

	# Make sure the player starts from a completely normal controllable state.
	GameManager.player_controls_locked = false
	player.velocity = Vector2.ZERO

	# -------------------------------------------------
	# PART 1 - PLAYER-CONTROLLED PANIC
	# -------------------------------------------------
	await play_skippable_panic_monologue()

	# -------------------------------------------------
	# PART 2 - PANIC TAKES OVER
	# -------------------------------------------------
	await play_automatic_panic_monologue()

	# -------------------------------------------------
	# PART 3 - PHONE CALL FROM PARENTS
	# -------------------------------------------------
	await play_phone_ring()
	await play_parent_phone_call()

	# -------------------------------------------------
	# PART 4 - PLAYER CALMS DOWN
	# -------------------------------------------------
	await play_final_calming_monologue()

	GameManager.house_opening_completed = true
	GameManager.player_controls_locked = false
	player.velocity = Vector2.ZERO

	restore_player_animation()


# =========================================
# PLAYER-CONTROLLED PANIC
# =========================================

func play_skippable_panic_monologue() -> void:

	var dialogue = [
		{
			"speaker": "Player",
			"text": "Okay... today's the day."
		},
		{
			"speaker": "Player",
			"text": "First day of college. No big deal."
		},
		{
			"speaker": "Player",
			"text": "...It's a big deal."
		},
		{
			"speaker": "Player",
			"text": "What if I go to the wrong building?"
		},
		{
			"speaker": "Player",
			"text": "What if I can't find my classroom?"
		},
		{
			"speaker": "Player",
			"text": "What if everyone's already there?"
		},
		{
			"speaker": "Player",
			"text": "What if the professor asks me something and I just... freeze?"
		},
		{
			"speaker": "Player",
			"text": "I don't even know anyone yet."
		}
	]

	await start_dialogue_and_allow_movement(
		dialogue,
		transparent_texture,
		PLAYER_HD,
		SKIPPABLE_MONOLOGUE_SPEED
	)


# =========================================
# AUTOMATIC PANIC
# =========================================

func play_automatic_panic_monologue() -> void:

	var dialogue = [
		{
			"speaker": "Player",
			"text": "Okay. Focus."
		},
		{
			"speaker": "Player",
			"text": "Do I have everything?"
		},
		{
			"speaker": "Player",
			"text": "Registration form. ID. Phone. Bag."
		},
		{
			"speaker": "Player",
			"text": "What time is it?"
		},
		{
			"speaker": "Player",
			"text": "I'm going to be late."
		},
		{
			"speaker": "Player",
			"text": "I'm going to be late."
		},
		{
			"speaker": "Player",
			"text": "I'm going to be late."
		},
		{
			"speaker": "Player",
			"text": "Where's my bag?!"
		},
		{
			"speaker": "Player",
			"text": "I need to get ready!"
		},
		{
			"speaker": "Player",
			"text": "What if I embarrass myself?"
		},
		{
			"speaker": "Player",
			"text": "What if everyone already has friends?"
		},
		{
			"speaker": "Player",
			"text": "What if I don't fit in?"
		},
		{
			"speaker": "Player",
			"text": "What if I'm not ready for college?"
		},
		{
			"speaker": "Player",
			"text": "Wait."
		},
		{
			"speaker": "Player",
			"text": "Wait, wait, wait..."
		},
		{
			"speaker": "Player",
			"text": "WHY AM I THINKING ABOUT THIS NOW?!"
		},
		{
			"speaker": "Player",
			"text": "I'M NOT READY FOR THIS!"
		}
	]

	GameManager.player_controls_locked = true

	DialogueManager.start_dialogue(
		dialogue,
		transparent_texture,
		PLAYER_HD
	)

	var dialogue_ui = DialogueManager.dialogue_ui

	if dialogue_ui == null:
		print("ERROR: DialogueUI was not found for automatic panic.")
		GameManager.player_controls_locked = false
		return

	# Do not let the player skip the automatic spiral.
	dialogue_ui.input_enabled = false

	# The continue prompt would imply that input is allowed, so hide it here.
	var continue_prompt := dialogue_ui.get_node_or_null(
		"ContinuePrompt"
	) as Label

	if continue_prompt:
		continue_prompt.visible = false

	# Keep the first line slow, then accelerate the typing speed line by line.
	dialogue_ui.typing_speed = AUTO_PANIC_SPEEDS[0]

	panic_route_running = true
	panic_footstep_timer = 0.0

	# Start the panic movement separately from the dialogue coroutine.
	# call_deferred() lets the route run without blocking the dialogue loop.
	# Disable the player's normal physics process so Player.gd cannot pause the
	# AnimatedSprite2D every physics frame while this controller is running the panic.
	player.set_physics_process(false)
	call_deferred("run_panic_route")

	# Wait for the dialogue entrance animation and first line to become active.
	await wait_for_dialogue_ui_entered(dialogue_ui)

	# The player's normal script is locked. This controller now moves the player.
	GameManager.player_controls_locked = true

	for line_index in range(dialogue.size()):

		if not DialogueManager.is_active:
			break

		var speed_index: int = min(
			line_index,
			AUTO_PANIC_SPEEDS.size() - 1
		)

		# Change typing speed immediately so the current/next characters accelerate.
		dialogue_ui.typing_speed = AUTO_PANIC_SPEEDS[speed_index]

		while DialogueManager.is_active and dialogue_ui.is_typing:
			await get_tree().process_frame

		if not DialogueManager.is_active:
			break

		if line_index < AUTO_PANIC_PAUSES.size():
			await get_tree().create_timer(
				AUTO_PANIC_PAUSES[line_index]
			).timeout

		if not DialogueManager.is_active:
			break

		if line_index < dialogue.size() - 1:
			var next_speed_index: int = min(
				line_index + 1,
				AUTO_PANIC_SPEEDS.size() - 1
			)

			dialogue_ui.typing_speed = AUTO_PANIC_SPEEDS[next_speed_index]
			dialogue_ui.advance_to_next_line()

	# Wait until the final line has finished typing.
	while DialogueManager.is_active and dialogue_ui.is_typing:
		await get_tree().process_frame

	if DialogueManager.is_active:
		await get_tree().create_timer(0.15).timeout

		# Only advance if the dialogue is still active. If the player used
		# "Skip All", DialogueUI has already ended this dialogue set.
		if DialogueManager.is_active:
			dialogue_ui.advance_to_next_line()

	# IMPORTANT: Skip All can end the dialogue before this point. In that case
	# dialogue_finished was already emitted, so awaiting it here would wait
	# forever and prevent the parent phone call from starting.
	if DialogueManager.is_active:
		await DialogueManager.dialogue_finished

	# Stop the panic movement immediately when the automatic dialogue is skipped.
	panic_route_running = false

	# Wait for the panic movement coroutine to finish cleanly before continuing.
	while panic_route_running:
		await get_tree().physics_frame

	# Restore the player's normal physics process after the automatic panic.
	player.set_physics_process(true)


# =========================================
# PANIC MOVEMENT ROUTE
# =========================================

func load_panic_route() -> void:

	panic_route.clear()

	var route_node := get_node_or_null("../OpeningRoute") as Node2D

	if route_node == null:
		print("WARNING: OpeningRoute was not found. Automatic panic will happen in place.")
		return

	for child in route_node.get_children():

		var marker := child as Marker2D

		if marker != null:
			panic_route.append(marker)

	# Sort markers by name so PanicPoint01, PanicPoint02, etc. are followed in order.
	panic_route.sort_custom(func(a: Marker2D, b: Marker2D):
		return a.name.naturalnocasecmp_to(b.name) < 0
	)


func setup_panic_navigation() -> void:

	if player == null:
		return

	panic_navigation_agent = player.get_node_or_null(
		"PanicNavigationAgent2D"
	) as NavigationAgent2D

	if panic_navigation_agent == null:
		panic_navigation_agent = NavigationAgent2D.new()
		panic_navigation_agent.name = "PanicNavigationAgent2D"
		player.add_child(panic_navigation_agent)

	panic_navigation_agent.path_desired_distance = PANIC_NAVIGATION_PATH_DISTANCE
	panic_navigation_agent.target_desired_distance = PANIC_NAVIGATION_TARGET_DISTANCE
	panic_navigation_agent.path_max_distance = 2000.0
	panic_navigation_agent.radius = PANIC_NAVIGATION_RADIUS
	panic_navigation_agent.neighbor_distance = 100.0
	panic_navigation_agent.avoidance_enabled = false


func get_panic_navigation_target(target_position: Vector2) -> Vector2:

	if panic_navigation_agent == null:
		return target_position

	var navigation_map: RID = panic_navigation_agent.get_navigation_map()

	if not navigation_map.is_valid():
		return target_position

	# Snap the target to the nearest point on the navigation mesh so a panic
	# marker placed slightly outside the walkable area does not break the route.
	return NavigationServer2D.map_get_closest_point(
		navigation_map,
		target_position
	)


func run_panic_route() -> void:

	if player == null:
		panic_route_running = false
		return

	if panic_route.is_empty():
		while panic_route_running and DialogueManager.is_active:
			update_panic_animation(Vector2.ZERO)
			await get_tree().physics_frame

		panic_route_running = false
		return

	for marker in panic_route:

		if marker == null or not marker.is_inside_tree():
			continue

		if not panic_route_running or not DialogueManager.is_active:
			break

		await move_player_to_panic_point(marker.global_position)

	if player:
		player.velocity = Vector2.ZERO
		restore_player_animation()

	panic_route_running = false


func move_player_to_panic_point(target_position: Vector2) -> void:

	var stuck_time: float = 0.0
	var last_position: Vector2 = player.global_position
	var physics_delta: float = 1.0 / float(Engine.physics_ticks_per_second)

	var navigation_target: Vector2 = target_position
	var use_navigation := false
	var detour_direction := Vector2.ZERO
	var detour_time := 0.0

	if panic_navigation_agent != null:
		var navigation_map: RID = panic_navigation_agent.get_navigation_map()

		if navigation_map.is_valid():
			navigation_target = get_panic_navigation_target(target_position)
			panic_navigation_agent.target_position = navigation_target
			use_navigation = true

			# Give NavigationServer2D time to calculate the path before reading it.
			await get_tree().physics_frame

	while panic_route_running and DialogueManager.is_active:

		var distance_to_marker: float = player.global_position.distance_to(target_position)

		if distance_to_marker <= PANIC_POINT_REACHED_DISTANCE:
			player.velocity = Vector2.ZERO
			break

		var direction: Vector2

		if detour_time > 0.0:
			detour_time -= physics_delta
			direction = detour_direction

		else:

			if use_navigation and not panic_navigation_agent.is_navigation_finished():
				var next_position: Vector2 = panic_navigation_agent.get_next_path_position()
				direction = next_position - player.global_position

				if direction.length() <= 1.0:
					direction = navigation_target - player.global_position
			else:
				direction = target_position - player.global_position

		if direction.length() <= 0.1:
			player.velocity = Vector2.ZERO
			break

		direction = direction.normalized()

		player.velocity = direction * PANIC_WALK_SPEED
		player.move_and_slide()

		update_panic_animation(direction)
		update_panic_footsteps()

		var moved_distance: float = player.global_position.distance_to(last_position)

		if moved_distance <= 0.5:
			stuck_time += physics_delta
		else:
			stuck_time = 0.0

		# A collision can make move_and_slide() repeatedly push the player into the
		# same corner. Pick a clear direction around the collision and keep moving.
		if player.get_slide_collision_count() > 0:
			var collision := player.get_slide_collision(0)
			if collision != null:
				var escape_direction := get_collision_escape_direction(
					direction,
					target_position,
					collision.get_normal()
				)

				if escape_direction.length() > 0.1:
					detour_direction = escape_direction
					detour_time = 0.35
					stuck_time = 0.0

		last_position = player.global_position

		# If furniture or another collision blocks the player, do not freeze forever.
		# Ask the navigation agent for a fresh route before giving up on this marker.
		if stuck_time >= PANIC_POINT_STUCK_TIME:
			if use_navigation:
				panic_navigation_agent.target_position = get_panic_navigation_target(target_position)
				stuck_time = 0.0
				detour_direction = get_collision_escape_direction(
					direction,
					target_position,
					Vector2.ZERO
				)
				if detour_direction.length() > 0.1:
					detour_time = 0.45
				await get_tree().physics_frame
				continue

			# Try to find a local escape route even when no NavigationRegion2D exists.
			detour_direction = get_collision_escape_direction(
				direction,
				target_position,
				Vector2.ZERO
			)

			if detour_direction.length() > 0.1:
				detour_time = 0.45
				stuck_time = 0.0
				await get_tree().physics_frame
				continue

			player.velocity = Vector2.ZERO
			break

		await get_tree().physics_frame


func get_collision_escape_direction(
	preferred_direction: Vector2,
	target_position: Vector2,
	collision_normal: Vector2

) -> Vector2:

	var candidates: Array[Vector2] = []

	if collision_normal.length() > 0.1:
		var tangent_left := Vector2(
			-collision_normal.y,
			collision_normal.x
		).normalized()

		var tangent_right := Vector2(
			collision_normal.y,
			-collision_normal.x
		).normalized()

		candidates.append(collision_normal.normalized())
		candidates.append(tangent_left)
		candidates.append(tangent_right)

	# Add several angles around the original movement direction.
	# test_move() makes sure the selected detour is not immediately blocked.
	var angles: Array[float] = [
		-30.0,
		30.0,
		-60.0,
		60.0,
		-90.0,
		90.0,
		-120.0,
		120.0,
		180.0
	]

	var base_direction := preferred_direction
	if base_direction.length() <= 0.1:
		base_direction = (target_position - player.global_position).normalized()

	for angle in angles:
		candidates.append(
			base_direction.rotated(deg_to_rad(angle)).normalized()
		)

	var best_direction := Vector2.ZERO
	var best_score := -INF

	for candidate in candidates:

		if candidate.length() <= 0.1:
			continue

		# Test a short movement first.
		if player.test_move(
			player.global_transform,
			candidate * 18.0
		):
			continue

		var target_score := 0.0
		if target_position != Vector2.ZERO:
			var before_distance := player.global_position.distance_to(target_position)
			var after_distance := (
				player.global_position + candidate * 18.0
			).distance_to(target_position)
			target_score = before_distance - after_distance

		var direction_score := candidate.dot(base_direction) * 5.0
		var score := target_score + direction_score

		if score > best_score:
			best_score = score
			best_direction = candidate

	return best_direction


func update_panic_animation(direction: Vector2) -> void:

	if player == null:
		return

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	if direction.length() <= 0.01:
		sprite.pause()
		return

	var animation_name: String

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0.0:
			animation_name = "walk_right"
		else:
			animation_name = "walk_left"

	else:

		if direction.y > 0.0:
			animation_name = "walk_down"
		else:
			animation_name = "walk_up"

	if sprite.sprite_frames.has_animation(animation_name):
		# Keep the running animation looping instead of stopping after one pass.
		sprite.sprite_frames.set_animation_loop(animation_name, true)

		sprite.speed_scale = 1.35

		if sprite.animation != animation_name:
			sprite.play(animation_name)
		elif not sprite.is_playing():
			sprite.play(animation_name)


func update_panic_footsteps() -> void:

	if player == null:
		return

	panic_footstep_timer -= 1.0 / float(Engine.physics_ticks_per_second)

	if panic_footstep_timer > 0.0:
		return

	var footstep_sound := player.get_node_or_null(
		"FootstepSound"
	) as AudioStreamPlayer

	if footstep_sound:
		footstep_sound.play()

	panic_footstep_timer = PANIC_FOOTSTEP_INTERVAL


# =========================================
# PHONE CALL
# =========================================

func play_phone_ring() -> void:

	if player == null:
		return

	GameManager.player_controls_locked = true
	player.velocity = Vector2.ZERO
	restore_player_animation()

	var player_audio := AudioStreamPlayer.new()
	add_child(player_audio)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 2.0

	player_audio.stream = generator
	player_audio.play()

	var playback := player_audio.get_stream_playback() as AudioStreamGeneratorPlayback

	if playback == null:
		player_audio.queue_free()
		return

	var duration: float = 2.1
	var sample_count: int = int(44100.0 * duration)
	var buffer := PackedVector2Array()
	buffer.resize(sample_count)

	for i in range(sample_count):

		var time: float = float(i) / 44100.0

		var ring_cycle: float = fmod(time, 0.7)
		var active: float = 1.0 if ring_cycle < 0.34 else 0.0

		var envelope: float = 1.0
		if ring_cycle > 0.28 and ring_cycle < 0.34:
			envelope = (0.34 - ring_cycle) / 0.06

		var tone_1: float = sin(TAU * 880.0 * time)
		var tone_2: float = sin(TAU * 1174.66 * time)

		var sample: float = (
			(tone_1 * 0.55)
			+ (tone_2 * 0.45)
		) * active * envelope * 0.20

		buffer[i] = Vector2(sample, sample)

	playback.push_buffer(buffer)

	await get_tree().create_timer(duration + 0.05).timeout

	player_audio.queue_free()


func play_parent_phone_call() -> void:

	var dialogue = [
		{
			"speaker": "Mom",
			"text": "Good morning, honey!"
		},
		{
			"speaker": "Player",
			"text": "Mom?"
		},
		{
			"speaker": "Mom",
			"text": "Your dad and I are already on our way to work."
		},
		{
			"speaker": "Dad",
			"text": "And don't forget your baon. We left it on the table in the living room."
		},
		{
			"speaker": "Player",
			"text": "Oh... right."
		},
		{
			"speaker": "Mom",
			"text": "Please eat properly today, okay? Don't spend the whole day running around without eating."
		},
		{
			"speaker": "Dad",
			"text": "It's your first day. You don't have to figure everything out all at once."
		},
		{
			"speaker": "Mom",
			"text": "Just take things one step at a time."
		},
		{
			"speaker": "Dad",
			"text": "You worked hard to get here."
		},
		{
			"speaker": "Mom",
			"text": "We're proud of you."
		},
		{
			"speaker": "Player",
			"text": "You really think I'll be okay?"
		},
		{
			"speaker": "Mom",
			"text": "Of course you will."
		},
		{
			"speaker": "Dad",
			"text": "You'll be fine. Just be yourself and do your best."
		},
		{
			"speaker": "Mom",
			"text": "And remember to text us when you get to school."
		},
		{
			"speaker": "Player",
			"text": "Okay... I will."
		},
		{
			"speaker": "Mom",
			"text": "We love you, honey. Take care."
		},
		{
			"speaker": "Dad",
			"text": "Good luck on your first day. You've got this."
		},
		{
			"speaker": "Player",
			"text": "Love you too."
		}
	]

	# The player cannot walk around during the phone call.
	GameManager.player_controls_locked = true

	DialogueManager.start_dialogue(
		dialogue,
		transparent_texture,
		transparent_texture
	)

	var dialogue_ui = DialogueManager.dialogue_ui

	if dialogue_ui == null:
		print("ERROR: DialogueUI was not found for parent phone call.")
		GameManager.player_controls_locked = false
		return

	dialogue_ui.typing_speed = CALM_MONOLOGUE_SPEED

	await wait_for_dialogue_ui_entered(dialogue_ui)

	# The phone conversation is still a normal skippable dialogue.
	GameManager.player_controls_locked = true

	await DialogueManager.dialogue_finished

	# Complete the morning-call objective only after the phone-call sequence ends.
	var quest_manager := get_node_or_null("/root/QuestUIManager")
	if quest_manager != null and quest_manager.has_method("complete_parent_call"):
		quest_manager.complete_parent_call()


# =========================================
# FINAL CALMING MOMENT
# =========================================

func play_final_calming_monologue() -> void:

	await get_tree().create_timer(0.75).timeout

	var dialogue = [
		{
			"speaker": "Player",
			"text": "..."
		},
		{
			"speaker": "Player",
			"text": "Maybe they're right."
		},
		{
			"speaker": "Player",
			"text": "I don't have to figure everything out today."
		},
		{
			"speaker": "Player",
			"text": "I just have to get through the first day."
		},
		{
			"speaker": "Player",
			"text": "Okay. Let's do this."
		}
	]

	await start_dialogue_and_lock_player(
		dialogue,
		transparent_texture,
		PLAYER_HD,
		CALM_MONOLOGUE_SPEED
	)


# =========================================
# DIALOGUE HELPERS
# =========================================

func start_dialogue_and_allow_movement(
	dialogue: Array,
	left_texture: Texture2D,
	right_texture: Texture2D,
	speed: float
) -> void:

	DialogueManager.start_dialogue(
		dialogue,
		left_texture,
		right_texture
	)

	var dialogue_ui = DialogueManager.dialogue_ui

	if dialogue_ui == null:
		print("ERROR: DialogueUI was not found.")
		GameManager.player_controls_locked = false
		return

	dialogue_ui.typing_speed = speed

	await wait_for_dialogue_ui_entered(dialogue_ui)

	# Dialogue can still be advanced by the player, but movement is allowed.
	GameManager.player_controls_locked = false

	await DialogueManager.dialogue_finished


func start_dialogue_and_lock_player(
	dialogue: Array,
	left_texture: Texture2D,
	right_texture: Texture2D,
	speed: float
) -> void:

	GameManager.player_controls_locked = true
	player.velocity = Vector2.ZERO

	DialogueManager.start_dialogue(
		dialogue,
		left_texture,
		right_texture
	)

	var dialogue_ui = DialogueManager.dialogue_ui

	if dialogue_ui == null:
		print("ERROR: DialogueUI was not found.")
		GameManager.player_controls_locked = false
		return

	dialogue_ui.typing_speed = speed

	await wait_for_dialogue_ui_entered(dialogue_ui)

	GameManager.player_controls_locked = true
	await DialogueManager.dialogue_finished


func wait_for_dialogue_ui_entered(dialogue_ui: Control) -> void:

	while DialogueManager.is_active and dialogue_ui.is_entering:
		await get_tree().process_frame


# =========================================
# PLAYER RESTORE
# =========================================

func restore_player_animation() -> void:

	if player == null:
		return

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	sprite.speed_scale = 1.0
	sprite.play("idle_down")


func create_transparent_texture() -> Texture2D:

	var image := Image.create(
		2,
		2,
		false,
		Image.FORMAT_RGBA8
	)

	image.fill(Color(1.0, 1.0, 1.0, 0.0))

	return ImageTexture.create_from_image(image)
