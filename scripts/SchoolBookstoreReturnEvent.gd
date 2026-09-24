extends Node

# BOOKSTORE RETURN EVENT CONTROLLER

@onready var player: CharacterBody2D = $"../Player"
@onready var kairi: CharacterBody2D = $"../Kairi"
@onready var kerwin: CharacterBody2D = $"../Kerwin"
@onready var janssen: CharacterBody2D = $"../Janssen"
@onready var nathaly: CharacterBody2D = $"../Nathaly"

@onready var lecture_room_door: Area2D = $"../Door_Room202/Area2D3"
@onready var lecture_room_collision: CollisionShape2D = $"../Door_Room202/Area2D3/CollisionShape2D"

var running: bool = false
var active_friend_walks: int = 0

const FRIEND_WALK_SPEED: float = 60.0
const FRIEND_STOP_DISTANCE: float = 8.0
const FRIEND_DOOR_ENTRY_DISTANCE: float = 18.0
const FRIEND_DEPARTURE_STAGGER: float = 1.0

const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const KAIRI_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kairi/Kairi.png")
const KERWIN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png")
const JANSSEN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Janssen/Janssen.png")
const NATHALY_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Nathaly/Nathaly.png")


func _ready() -> void:

	if not GameManager.bookstore_return_event_pending:
		return

	GameManager.bookstore_return_event_pending = false

	await get_tree().process_frame
	await get_tree().process_frame

	await start_return_event()


func start_return_event() -> void:

	if running:
		return

	running = true

	GameManager.player_controls_locked = true

	stop_player()

	show_friends()
	prepare_friends_for_lecture_walk()

	if lecture_room_door != null:
		lecture_room_door.monitoring = true

		if not lecture_room_door.body_entered.is_connected(_on_lecture_room_body_entered):
			lecture_room_door.body_entered.connect(_on_lecture_room_body_entered)

	await get_tree().create_timer(0.35).timeout

	await start_return_conversation()

	await play_bell_sound()

	await start_next_class_conversation()

	await friends_go_to_lecture_room()

	GameManager.player_controls_locked = false

	player.set_physics_process(true)

	running = false


func stop_player() -> void:

	if player == null:
		return

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


func show_friends() -> void:

	if kairi:
		kairi.visible = true

	if kerwin:
		kerwin.visible = true

	if janssen:
		janssen.visible = true

	if nathaly:
		nathaly.visible = true


func start_return_conversation() -> void:

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Well, that took longer than I expected."
		},
		{
			"speaker": "Kerwin",
			"text": "At least we got everything we needed."
		},
		{
			"speaker": "Nathaly",
			"text": "Yeah. We should have everything ready for class now."
		},
		{
			"speaker": "Janssen",
			"text": "I guess that means we're finally done shopping."
		},
		{
			"speaker": "Player",
			"text": "Good. I was starting to think we'd never leave that bookstore."
		},
		{
			"speaker": "Kairi",
			"text": "Same. I'm just glad we made it back before the next class."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


func play_bell_sound() -> void:

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

	var duration: float = 1.5
	var sample_count: int = int(44100.0 * duration)
	var buffer := PackedVector2Array()
	buffer.resize(sample_count)

	for i in range(sample_count):

		var time: float = float(i) / 44100.0
		var envelope: float = exp(-3.2 * time)

		var tone_1: float = sin(TAU * 880.0 * time)
		var tone_2: float = sin(TAU * 1320.0 * time)
		var tone_3: float = sin(TAU * 1760.0 * time)

		var sample: float = (
			(tone_1 * 0.45)
			+ (tone_2 * 0.35)
			+ (tone_3 * 0.20)
		) * envelope * 0.24

		buffer[i] = Vector2(sample, sample)

	playback.push_buffer(buffer)

	await get_tree().create_timer(duration + 0.1).timeout

	player_audio.queue_free()


func start_next_class_conversation() -> void:

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Oh! That's the bell."
		},
		{
			"speaker": "Kerwin",
			"text": "Wait, isn't our next class Discrete Mathematics?"
		},
		{
			"speaker": "Janssen",
			"text": "It is. We should get to the Lecture Room now."
		},
		{
			"speaker": "Nathaly",
			"text": "Yeah, we don't want to be late."
		},
		{
			"speaker": "Kairi",
			"text": "We're going ahead to the Lecture Room."
		},
		{
			"speaker": "Kairi",
			"text": "You can stay here for a bit. See you in class!"
		},
		{
			"speaker": "Player",
			"text": "Alright. See you guys there."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


func friends_go_to_lecture_room() -> void:

	if lecture_room_door == null:
		print("ERROR: Lecture Room door Area2D was not found in School.tscn.")
		return

	if lecture_room_collision == null:
		print("ERROR: Lecture Room door CollisionShape2D was not found in School.tscn.")
		return

	# The actual lecture-room entrance is Door_Room202/Area2D3/CollisionShape2D.
	# We use the collision shape's GLOBAL position because the Area2D itself may
	# have a different local position that does not match the visible doorway.
	lecture_room_door.monitoring = true

	var friends: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly
	]

	# Send them into the door one at a time so their CharacterBody2D collisions
	# cannot form a wall that blocks the friends behind them.
	# Each friend starts walking one second after the previous friend,
	# without waiting for the previous friend to reach the door.
	active_friend_walks = 0

	for friend in friends:

		if friend == null or not friend.is_inside_tree() or not friend.visible:
			continue

		active_friend_walks += 1
		walk_friend_into_lecture_room(friend)

		await get_tree().create_timer(
			FRIEND_DEPARTURE_STAGGER
		).timeout

	# Wait until every friend has either reached the door or safely stopped.
	while active_friend_walks > 0:
		await get_tree().physics_frame


func prepare_friends_for_lecture_walk() -> void:

	var friends: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly
	]

	for friend in friends:

		if friend == null or not friend.is_inside_tree():
			continue

		# Disable their normal movement/controller scripts so only this event
		# controls their movement during the trip to the Lecture Room.
		friend.set_physics_process(false)
		friend.set_process(false)

		friend.velocity = Vector2.ZERO


func walk_friend_into_lecture_room(
	friend: CharacterBody2D
) -> void:

	var agent: NavigationAgent2D = get_or_create_navigation_agent(friend)

	if agent == null:
		print("ERROR: Could not create NavigationAgent2D for ", friend.name)
		active_friend_walks = max(0, active_friend_walks - 1)
		return

	# Keep the friend under this controller's exclusive movement control.
	friend.set_physics_process(false)
	friend.set_process(false)

	var door_position: Vector2 = lecture_room_collision.global_position
	var navigation_map: RID = agent.get_navigation_map()

	if not navigation_map.is_valid():
		print("ERROR: Navigation map is not valid for ", friend.name)
		active_friend_walks = max(0, active_friend_walks - 1)
		return

	# Convert the real doorway position into the nearest walkable navigation point.
	# This prevents the friend from targeting the Area2D node's unrelated position.
	var navigation_target: Vector2 = NavigationServer2D.map_get_closest_point(
		navigation_map,
		door_position
	)

	agent.target_position = navigation_target

	var last_position: Vector2 = friend.global_position
	var stuck_time: float = 0.0
	var reroute_time: float = 0.0
	var rerouting_around_player: bool = false
	var player_reroute_target: Vector2 = Vector2.ZERO

	while friend.visible:

		# The Area2D is the authoritative signal that the friend entered the room.
		if has_friend_entered_lecture_room(friend):
			break

		if reroute_time > 0.0:
			reroute_time = max(0.0, reroute_time - get_physics_process_delta_time())

		if rerouting_around_player:
			if friend.global_position.distance_to(player_reroute_target) <= FRIEND_STOP_DISTANCE + 6.0:
				rerouting_around_player = false
				agent.target_position = navigation_target

		var target_position: Vector2 = door_position

		if rerouting_around_player:
			target_position = player_reroute_target

		elif not agent.is_navigation_finished():

			var next_position: Vector2 = agent.get_next_path_position()

			if next_position.distance_to(friend.global_position) > 1.0:
				target_position = next_position

		else:

			# Navigation has reached the nearest valid point. Continue the final
			# short distance toward the actual door trigger.
			target_position = door_position

		var direction: Vector2 = target_position - friend.global_position

		if direction.length() <= 0.1:
			await get_tree().physics_frame
			continue

		direction = direction.normalized()

		friend.velocity = direction * FRIEND_WALK_SPEED

		# Explicitly play the correct directional walking animation while moving.
		# We do not pause or reset it every frame, which allows the frames to advance normally.
		update_friend_walk_animation(friend, direction)

		friend.move_and_slide()

		var hit_player: bool = false

		for collision_index in friend.get_slide_collision_count():

			var collision := friend.get_slide_collision(collision_index)

			if collision == null:
				continue

			if collision.get_collider() == player:
				hit_player = true
				break

		# If the player is physically blocking the friend's current path,
		# temporarily create a navigation target beside the player so the friend
		# can walk around them instead of repeatedly pushing into the player.
		if hit_player and not rerouting_around_player and reroute_time <= 0.0:

			route_friend_around_player(
				friend,
				agent,
				navigation_map,
				door_position
			)

			player_reroute_target = get_player_reroute_target(
				friend,
				navigation_map,
				door_position
			)

			if player_reroute_target != Vector2.ZERO:
				rerouting_around_player = true
				reroute_time = 0.8
				stuck_time = 0.0

		# If the friend physically hits something and is no longer making progress,
		# refresh the navigation target instead of letting them push into the wall forever.
		var moved_distance: float = friend.global_position.distance_to(last_position)

		if moved_distance <= 0.5:
			stuck_time += get_physics_process_delta_time()
		else:
			stuck_time = 0.0

		last_position = friend.global_position

		if stuck_time >= 0.45 and not rerouting_around_player:

			if player != null and friend.global_position.distance_to(player.global_position) <= 120.0 and reroute_time <= 0.0:

				player_reroute_target = get_player_reroute_target(
					friend,
					navigation_map,
					door_position
				)

				if player_reroute_target != Vector2.ZERO:
					agent.target_position = player_reroute_target
					rerouting_around_player = true
					reroute_time = 0.8

			else:

				navigation_target = NavigationServer2D.map_get_closest_point(
					navigation_map,
					door_position
				)

				agent.target_position = navigation_target

			stuck_time = 0.0

		# Distance fallback in case the Area2D signal arrives one physics frame later.
		if friend.global_position.distance_to(door_position) <= FRIEND_DOOR_ENTRY_DISTANCE:
			enter_lecture_room(friend)
			break

		await get_tree().physics_frame

	if friend.visible:
		friend.velocity = Vector2.ZERO
		pause_animation(friend)

	active_friend_walks = max(0, active_friend_walks - 1)


func route_friend_around_player(
	friend: CharacterBody2D,
	agent: NavigationAgent2D,
	navigation_map: RID,
	door_position: Vector2
) -> void:

	if friend == null or agent == null:
		return

	var reroute_target: Vector2 = get_player_reroute_target(
		friend,
		navigation_map,
		door_position
	)

	if reroute_target != Vector2.ZERO:
		agent.target_position = reroute_target


func get_player_reroute_target(
	friend: CharacterBody2D,
	navigation_map: RID,
	door_position: Vector2
) -> Vector2:

	if friend == null or player == null or not navigation_map.is_valid():
		return Vector2.ZERO

	var door_direction: Vector2 = door_position - player.global_position

	if door_direction.length() <= 0.1:
		return Vector2.ZERO

	door_direction = door_direction.normalized()

	var side_direction := Vector2(-door_direction.y, door_direction.x)

	var friend_side: float = (friend.global_position - player.global_position).dot(side_direction)

	if friend_side < 0.0:
		side_direction = -side_direction

	var clearance: float = 60.0

	var player_collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if player_collision != null and player_collision.shape is RectangleShape2D:
		var player_shape := player_collision.shape as RectangleShape2D
		clearance = max(clearance, max(player_shape.size.x, player_shape.size.y) * 0.5 + 32.0)

	var desired_target: Vector2 = player.global_position + side_direction * clearance

	var navigation_target: Vector2 = NavigationServer2D.map_get_closest_point(
		navigation_map,
		desired_target
	)

	if navigation_target.distance_to(friend.global_position) <= 4.0:
		return Vector2.ZERO

	return navigation_target


func has_friend_entered_lecture_room(
	friend: CharacterBody2D
) -> bool:

	if lecture_room_door == null or friend == null:
		return false

	if lecture_room_door.has_method("has_overlapping_bodies"):
		var overlapping_bodies: Array[Node2D] = lecture_room_door.get_overlapping_bodies()

		if overlapping_bodies.has(friend):
			enter_lecture_room(friend)
			return true

	return false


func _on_lecture_room_body_entered(body: Node2D) -> void:

	if body == kairi or body == kerwin or body == janssen or body == nathaly:
		enter_lecture_room(body as CharacterBody2D)


func enter_lecture_room(
	friend: CharacterBody2D
) -> void:

	if friend == null:
		return

	friend.velocity = Vector2.ZERO

	# Disable every CollisionShape2D belonging to the friend before hiding them.
	# This prevents their invisible character collision from blocking the other
	# friends while they continue walking toward the lecture room.
	var collision_shapes := friend.find_children(
		"CollisionShape2D",
		"CollisionShape2D",
		true,
		false
	)

	for collision_node in collision_shapes:

		var collision_shape := collision_node as CollisionShape2D

		if collision_shape:
			collision_shape.set_deferred("disabled", true)

	# Also remove the CharacterBody2D from collision queries so there is no
	# invisible body left behind after the friend enters the room.
	friend.collision_layer = 0
	friend.collision_mask = 0

	var sprite := friend.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.stop()

	# The friend has reached the lecture-room entrance, so hide them as if
	# they have entered the room.
	friend.visible = false

func get_or_create_navigation_agent(
	friend: CharacterBody2D
) -> NavigationAgent2D:

	if friend == null:
		return null

	var agent := friend.get_node_or_null(
		"NavigationAgent2D"
	) as NavigationAgent2D

	if agent == null:
		agent = NavigationAgent2D.new()
		agent.name = "NavigationAgent2D"
		friend.add_child(agent)

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 5.0
	agent.path_max_distance = 1000.0
	agent.radius = 16.0
	agent.neighbor_distance = 100.0
	agent.avoidance_enabled = true

	return agent


func update_friend_walk_animation(
	friend: CharacterBody2D,
	direction: Vector2
) -> void:

	var sprite := friend.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null or direction.length() <= 0.01:
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
		sprite.speed_scale = 1.0

		if sprite.animation != animation_name:
			sprite.play(animation_name)
		elif not sprite.is_playing():
			sprite.play(animation_name)


func pause_animation(
	friend: CharacterBody2D
) -> void:

	var sprite := friend.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()
