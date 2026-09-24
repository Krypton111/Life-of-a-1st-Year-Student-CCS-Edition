extends Node

const COZY_CHOICE_UI = preload("res://scripts/PolishedChoiceUI.gd")

#CONTROLLER FOR THIS SCRIPT

@onready var player: CharacterBody2D = $"../Player"

@onready var kairi: CharacterBody2D = $"../Kairi"
@onready var kerwin: CharacterBody2D = $"../Kerwin"
@onready var janssen: CharacterBody2D = $"../Janssen"
@onready var nathaly: CharacterBody2D = $"../Nathaly"

@onready var ate_libro: CharacterBody2D = $"../Ate Libro"
@onready var kuya_libro: CharacterBody2D = $"../Kuya Libro"

@onready var kairi_navigation_agent: NavigationAgent2D = $"../Kairi/NavigationAgent2D"
@onready var kerwin_navigation_agent: NavigationAgent2D = null
@onready var janssen_navigation_agent: NavigationAgent2D = null
@onready var nathaly_navigation_agent: NavigationAgent2D = null
@onready var player_navigation_agent: NavigationAgent2D = null

@onready var cinematic_camera: Camera2D = $"../CinematicCamera"

@onready var top_bar: ColorRect = $"../CinematicUI/TopBar"
@onready var bottom_bar: ColorRect = $"../CinematicUI/BottomBar"

@onready var quest_ui: Control = $"../CinematicUI/QuestUI"

@onready var yellow_pad_label: Label = $"../CinematicUI/QuestUI/YellowPadLabel"
@onready var ballpens_label: Label = $"../CinematicUI/QuestUI/BallpensLabel"
@onready var correction_tape_label: Label = $"../CinematicUI/QuestUI/CorrectionTapeLabel"
@onready var discrete_math_book_label: Label = $"../CinematicUI/QuestUI/DiscreteMathBookLabel"

@onready var optional_title: Label = $"../CinematicUI/QuestUI/OptionalTitle"
@onready var quest_title: Label = $"../CinematicUI/QuestUI/QuestTitle"
@onready var required_title: Label = $"../CinematicUI/QuestUI/RequiredTitle"

@onready var talk_friends_label: Label = $"../CinematicUI/QuestUI/TalkFriends"
@onready var talk_ate_libro_label: Label = $"../CinematicUI/QuestUI/TalkAteLibro"
@onready var talk_kuya_libro_label: Label = $"../CinematicUI/QuestUI/TalkKuyaLibro"

@onready var departure_choice: Control = $"../CinematicUI/DepartureChoice"
@onready var departure_question: Label = $"../CinematicUI/DepartureChoice/Question"
@onready var check_more_button: Button = $"../CinematicUI/DepartureChoice/CheckMoreButton"
@onready var head_out_button: Button = $"../CinematicUI/DepartureChoice/HeadOutButton"

@onready var purchase_spot: Marker2D = $"../PurchaseSpot"
@onready var exit_spot: Marker2D = $"../ExitSpot"


var running: bool = false
var player_camera: Camera2D = null

var departure_choice_result: int = 0
var departure_choice_mode: int = 0

var materials_completion_prompt_started: bool = false

var kairi_return_position: Vector2 = Vector2.ZERO

var black_overlay: ColorRect = null

var player_interaction_zone: Area2D = null
var kairi_inside_player_interaction_zone: bool = false

var kuya_navigation_agent: NavigationAgent2D = null

var npc_wander_npcs: Array[CharacterBody2D] = []
var npc_wander_states: Dictionary = {}
var allow_npc_wandering_during_kairi_event: bool = false
var active_interaction_npc: CharacterBody2D = null
var allow_kuya_wandering_during_head_out: bool = false
var heading_out_animation_active: bool = false


const KAIRI_APPROACH_DISTANCE: float = 15.0
const KAIRI_WALK_SPEED: float = 75.0

const NPC_WANDER_MIN_DISTANCE: float = 180.0
const NPC_WANDER_MAX_DISTANCE: float = 420.0
const NPC_WANDER_MIN_SPEED: float = 30.0
const NPC_WANDER_MAX_SPEED: float = 36.0
const NPC_WANDER_STUCK_TIME: float = 0.60
const NPC_WANDER_MOVEMENT_THRESHOLD: float = 0.75
const NPC_WANDER_IDLE_MIN: float = 0.45
const NPC_WANDER_IDLE_MAX: float = 1.00
const NPC_WANDER_TARGET_REACHED_DISTANCE: float = 12.0


const PLAYER_HD = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const KAIRI_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kairi/Kairi.png")
const KERWIN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png")
const JANSSEN_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Janssen/Janssen.png")
const NATHALY_HD = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Nathaly/Nathaly.png")


#CHALLENGE CHECKER AND QUEST CHECKER
func _ready() -> void:

	top_bar.visible = false
	bottom_bar.visible = false

	quest_ui.visible = false
	quest_ui.modulate.a = 1.0

	departure_choice.visible = false

	cinematic_camera.enabled = false

	player_camera = player.get_node_or_null(
		"Camera2D"
	) as Camera2D

	# Make sure the normal player camera is active during scene startup.
	# This prevents a black screen if the cinematic camera has not taken over yet.
	if player_camera != null:
		player_camera.enabled = true
		player_camera.make_current()

	# PLAYER INTERACTION ZONE SETUP
	player_interaction_zone = player.find_child(
		"InteractionZone",
		true,
		false
	) as Area2D

	if player_interaction_zone != null:

		player_interaction_zone.monitoring = true

		if not player_interaction_zone.body_entered.is_connected(
			_on_player_interaction_zone_body_entered
		):
			player_interaction_zone.body_entered.connect(
				_on_player_interaction_zone_body_entered
			)

	else:

		print(
			"WARNING: Player InteractionZone was not found."
		)

	# KAIRI NAVIGATION SETUP
	setup_navigation_agent(kairi_navigation_agent)

	# OTHER NAVIGATION SETUP
	kerwin_navigation_agent = get_or_create_navigation_agent(
		kerwin,
		"NavigationAgent2D"
	)

	janssen_navigation_agent = get_or_create_navigation_agent(
		janssen,
		"NavigationAgent2D"
	)

	nathaly_navigation_agent = get_or_create_navigation_agent(
		nathaly,
		"NavigationAgent2D"
	)

	# Kuya Libro also gets navigation because he can wander around the bookstore.
	# Ate Libro is intentionally excluded from random wandering.
	kuya_navigation_agent = get_or_create_navigation_agent(
		kuya_libro,
		"NavigationAgent2D"
	)

	player_navigation_agent = get_or_create_navigation_agent(
		player,
		"NavigationAgent2D"
	)

	kairi_return_position = kairi.global_position

	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	setup_departure_choice()
	setup_black_overlay()

	setup_quest_ui_layout()
	update_quest_ui()

	if not check_more_button.pressed.is_connected(
		_on_check_more_pressed
	):
		check_more_button.pressed.connect(
			_on_check_more_pressed
		)

	if not head_out_button.pressed.is_connected(
		_on_head_out_pressed
	):
		head_out_button.pressed.connect(
			_on_head_out_pressed
		)

	await get_tree().process_frame

	await start_bookstore_event()

	start_npc_wandering()


func _process(_delta: float) -> void:

	if running:
		return

	if DialogueManager.is_active:
		return

	if GameManager.player_controls_locked:
		return

	if not Input.is_action_just_pressed("interact"):
		return

	handle_bookstore_interaction()


func _physics_process(delta: float) -> void:

	if npc_wander_npcs.is_empty():
		return

	# Scripted events and dialogue always have priority over the random NPC AI.
	# The Kairi completion cutscene is a special exception: Kairi is controlled
	# by the cutscene, while the other bookstore NPCs are still allowed to wander.
	if running or DialogueManager.is_active or GameManager.player_controls_locked:

		if allow_kuya_wandering_during_head_out:
			update_only_kuya_wandering(delta)
		elif allow_npc_wandering_during_kairi_event:
			update_npc_wandering_except_kairi(delta)
		elif active_interaction_npc != null:
			update_npc_wandering_except_active_interaction(delta)
		else:
			stop_all_npc_wandering()

		return

	for npc in npc_wander_npcs:

		if npc == null:
			continue

		if not npc.is_inside_tree() or not npc.visible:
			continue

		update_npc_wander(npc, delta)


func handle_bookstore_interaction() -> void:

	var nearest_item: Area2D = get_nearest_item()
	var nearest_npc: CharacterBody2D = get_nearest_npc()

	var item_distance: float = INF
	var npc_distance: float = INF

	if nearest_item != null:

		if nearest_item.has_method(
			"get_interaction_position"
		):

			var interaction_position: Vector2 = (
				nearest_item.get_interaction_position()
			)

			item_distance = interaction_position.distance_to(
				player.global_position
			)

		else:

			item_distance = nearest_item.global_position.distance_to(
				player.global_position
			)

	if nearest_npc != null:

		npc_distance = nearest_npc.global_position.distance_to(
			player.global_position
		)

	print(
		"F INTERACTION | ITEM: ",
		nearest_item.name if nearest_item != null else "NONE",
		" | ITEM DISTANCE: ",
		item_distance,
		" | NPC: ",
		nearest_npc.name if nearest_npc != null else "NONE",
		" | NPC DISTANCE: ",
		npc_distance
	)


	# ITEM HAS PRIORITY IF IT IS CLOSE ENOUGH.
	if nearest_item != null and item_distance <= 20.0:

		if nearest_item.has_method(
			"collect_item"
		):

			print(
				"COLLECTING ITEM: ",
				nearest_item.name
			)

			nearest_item.collect_item()

			return


	# NPC
	if nearest_npc != null and npc_distance <= 60.0:

		var npc_name: String = nearest_npc.name

		print(
			"INTERACTING WITH NPC: ",
			npc_name
		)

		# Face the NPC toward the player before starting the conversation.
		face_character_toward_character(
			nearest_npc,
			player
		)

		# Face the player toward the NPC as well so both characters
		# naturally look at each other during the interaction.
		face_character_toward_character(
			player,
			nearest_npc
		)

		start_npc_dialogue(
			npc_name
		)

		return


	print(
		"NOTHING CLOSE ENOUGH TO INTERACT WITH"
	)


func get_nearest_item() -> Area2D:

	var nearest_item: Area2D = null
	var nearest_distance: float = INF

	var items := get_tree().get_nodes_in_group(
		"bookstore_item"
	)

	for node in items:

		var item := node as Area2D

		if item == null:
			continue

		if not item.is_inside_tree():
			continue

		if not item.visible:
			continue

		var collected_value = item.get(
			"collected"
		)

		if collected_value == true:
			continue

		var interaction_position: Vector2

		if item.has_method(
			"get_interaction_position"
		):

			interaction_position = item.get_interaction_position()

		else:

			interaction_position = item.global_position

		var distance: float = interaction_position.distance_to(
			player.global_position
		)

		if distance < nearest_distance:

			nearest_distance = distance
			nearest_item = item

	return nearest_item


func get_nearest_npc() -> CharacterBody2D:

	var nearest_npc: CharacterBody2D = null
	var nearest_distance: float = INF

	var npc_list: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly,
		ate_libro,
		kuya_libro
	]

	for npc in npc_list:

		if npc == null:
			continue

		if not npc.visible:
			continue

		var distance: float = npc.global_position.distance_to(
			player.global_position
		)

		if distance < nearest_distance:

			nearest_distance = distance
			nearest_npc = npc

	return nearest_npc


#NPC RANDOM WANDERING AI
func start_npc_wandering() -> void:

	if not npc_wander_npcs.is_empty():
		return

	randomize()

	npc_wander_npcs = [
		kairi,
		kerwin,
		janssen,
		nathaly,
		kuya_libro
	]

	for npc in npc_wander_npcs:

		if npc == null:
			continue

		var agent: NavigationAgent2D = get_or_create_navigation_agent(
			npc,
			"NavigationAgent2D"
		)

		var state: Dictionary = {
			"agent": agent,
			"target": npc.global_position,
			"speed": randf_range(
				NPC_WANDER_MIN_SPEED,
				NPC_WANDER_MAX_SPEED
			),
			"idle_time": randf_range(
				NPC_WANDER_IDLE_MIN,
				NPC_WANDER_IDLE_MAX
			),
			"stuck_time": 0.0,
			"last_position": npc.global_position,
			"has_target": false,
			"walk_time": 0.0
		}

		npc_wander_states[npc] = state

		choose_new_wander_target(npc, state)


func update_npc_wander(
	npc: CharacterBody2D,
	delta: float
) -> void:

	if not npc_wander_states.has(npc):
		return

	var state: Dictionary = npc_wander_states[npc]
	var agent: NavigationAgent2D = state["agent"] as NavigationAgent2D

	if state["idle_time"] > 0.0:

		npc.velocity = Vector2.ZERO
		pause_animation(npc)

		state["idle_time"] -= delta
		state["last_position"] = npc.global_position

		return

	var target_position: Vector2 = state["target"]

	state["walk_time"] += delta

	if npc.global_position.distance_to(target_position) <= NPC_WANDER_TARGET_REACHED_DISTANCE:
		choose_new_wander_target(npc, state)
		return

	var direction: Vector2 = Vector2.ZERO

	if agent != null:

		var navigation_map: RID = agent.get_navigation_map()

		if navigation_map.is_valid():

			if agent.is_navigation_finished():
				choose_new_wander_target(npc, state)
				return

			var next_position: Vector2 = agent.get_next_path_position()

			if next_position.distance_to(npc.global_position) > 1.0:
				direction = npc.global_position.direction_to(next_position)

	if direction == Vector2.ZERO:
		direction = npc.global_position.direction_to(target_position)

	if direction == Vector2.ZERO:
		choose_new_wander_target(npc, state)
		return

	npc.velocity = direction * float(state["speed"])

	update_walk_animation_toward(
		npc,
		npc.global_position + direction
	)

	npc.move_and_slide()

	# If the NPC physically hits a collision/asset, immediately pick a new destination.
	if npc.get_slide_collision_count() > 0:
		choose_new_wander_target(npc, state)
		return

	var moved_distance: float = npc.global_position.distance_to(
		state["last_position"]
	)

	if moved_distance <= NPC_WANDER_MOVEMENT_THRESHOLD:
		state["stuck_time"] += delta
	else:
		state["stuck_time"] = 0.0

	state["last_position"] = npc.global_position

	# If walking animation is playing but the NPC is not actually moving, retarget immediately.
	if state["walk_time"] >= 0.60 and state["stuck_time"] >= NPC_WANDER_STUCK_TIME:
		choose_new_wander_target(npc, state)


func choose_new_wander_target(
	npc: CharacterBody2D,
	state: Dictionary
) -> void:

	var agent: NavigationAgent2D = state["agent"] as NavigationAgent2D
	var navigation_map: RID

	if agent != null:
		navigation_map = agent.get_navigation_map()

	var chosen_target: Vector2 = npc.global_position
	var found_target := false

	if navigation_map.is_valid():

		for _attempt in range(16):

			var angle := randf_range(0.0, TAU)
			var distance := randf_range(
				NPC_WANDER_MIN_DISTANCE,
				NPC_WANDER_MAX_DISTANCE
			)

			var desired_target := npc.global_position + Vector2.RIGHT.rotated(angle) * distance
			var navigation_target := NavigationServer2D.map_get_closest_point(
				navigation_map,
				desired_target
			)

			if navigation_target.distance_to(npc.global_position) < NPC_WANDER_MIN_DISTANCE * 0.5:
				continue

			chosen_target = navigation_target
			found_target = true
			break

	if not found_target:
		var fallback_angle := randf_range(0.0, TAU)
		chosen_target = npc.global_position + Vector2.RIGHT.rotated(
			fallback_angle
		) * NPC_WANDER_MIN_DISTANCE

	if agent != null and navigation_map.is_valid():
		agent.target_position = chosen_target

	state["target"] = chosen_target
	state["speed"] = clamp(
		float(state["speed"]),
		NPC_WANDER_MIN_SPEED,
		NPC_WANDER_MAX_SPEED
	)
	state["stuck_time"] = 0.0
	state["last_position"] = npc.global_position
	state["has_target"] = true
	state["walk_time"] = 0.0
	state["idle_time"] = randf_range(
		NPC_WANDER_IDLE_MIN,
		NPC_WANDER_IDLE_MAX
	)


func stop_all_npc_wandering() -> void:

	for npc in npc_wander_npcs:

		if npc == null or not npc.is_inside_tree():
			continue

		npc.velocity = Vector2.ZERO
		pause_animation(npc)


func update_npc_wandering_except_kairi(delta: float) -> void:

	for npc in npc_wander_npcs:

		if npc == null or not npc.is_inside_tree():
			continue

		if npc == kairi:
			# Kairi is being controlled directly by the mini cutscene.
			# Do not pause or modify her animation here because that would freeze
			# the walking animation while kairi_walk_to_player() is moving her.
			continue

		if not npc.visible:
			continue

		update_npc_wander(npc, delta)


func update_npc_wandering_except_active_interaction(delta: float) -> void:

	for npc in npc_wander_npcs:

		if npc == null or not npc.is_inside_tree():
			continue

		if npc == active_interaction_npc:

			# Keep only the NPC being spoken to stationary.
			# Every other wandering NPC remains fully autonomous in the background.
			npc.velocity = Vector2.ZERO
			pause_animation(npc)
			continue

		if not npc.visible:
			continue

		update_npc_wander(npc, delta)


func update_only_kuya_wandering(delta: float) -> void:

	# Kuya Libro remains autonomous during the heading-out sequence.
	# The other characters are being controlled by the departure cutscene.
	if kuya_libro == null or not kuya_libro.is_inside_tree():
		return

	if not kuya_libro.visible:
		return

	# If Kuya is somehow the active interaction target, keep him stationary.
	if kuya_libro == active_interaction_npc:
		kuya_libro.velocity = Vector2.ZERO
		pause_animation(kuya_libro)
		return

	update_npc_wander(kuya_libro, delta)


#START OF BOOKSTORE EVENT
func start_bookstore_event() -> void:

	if running:
		return

	if GameManager.bookstore_started:

		GameManager.player_controls_locked = false

		# Restore the wandering NPCs when the bookstore scene is revisited.
		# Ate Libro remains stationary and is never added to the wandering AI.
		kairi.visible = true
		kerwin.visible = true
		janssen.visible = true
		nathaly.visible = true
		kuya_libro.visible = true

		quest_ui.visible = true

		cinematic_camera.enabled = false

		if player_camera:
			player_camera.enabled = true
			player_camera.make_current()

		player.visible = true
		player.set_physics_process(true)

		return

	running = true

	GameManager.bookstore_started = true
	GameManager.player_controls_locked = true

	kairi.visible = true
	kerwin.visible = true
	janssen.visible = true
	nathaly.visible = true

	player.visible = true

	stop_player()

	await show_cinematic_bars()

	await focus_on_friends()

	await start_bookstore_intro_dialogue()

	await hide_cinematic_bars()

	cinematic_camera.enabled = false

	if player_camera:
		player_camera.enabled = true
		player_camera.make_current()

	await get_tree().process_frame

	GameManager.player_controls_locked = false

	player.set_physics_process(true)

	show_quest_ui()

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


#CINEMATIC BARS
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


#CAMERA
func focus_on_friends() -> void:

	# Give the scene one physics frame before switching cameras.
	# This makes sure the bookstore characters have valid world positions first.
	await get_tree().physics_frame

	var friend_center := (
		kairi.global_position
		+ kerwin.global_position
		+ janssen.global_position
		+ nathaly.global_position
	) / 4.0

	cinematic_camera.global_position = friend_center

	if player_camera:
		cinematic_camera.zoom = player_camera.zoom

	# Switch to the cinematic camera only after it has a valid position.
	cinematic_camera.enabled = true
	cinematic_camera.make_current()

	if player_camera:
		player_camera.enabled = false

	await get_tree().process_frame

	# Safety check: if the cinematic camera did not become current,
	# immediately restore the player camera instead of leaving the screen black.
	if get_viewport().get_camera_2d() != cinematic_camera:
		print("WARNING: CinematicCamera did not become current. Restoring Player Camera.")
		cinematic_camera.enabled = false
		if player_camera:
			player_camera.enabled = true
			player_camera.make_current()

	await get_tree().create_timer(
		0.5
	).timeout


#BOOKSTORE INTRODUCTION
func start_bookstore_intro_dialogue() -> void:

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Alright, we're finally here."
		},
		{
			"speaker": "Player",
			"text": "This bookstore is bigger than I expected."
		},
		{
			"speaker": "Nathaly",
			"text": "That's why we usually come here when we need school supplies."
		},
		{
			"speaker": "Janssen",
			"text": "And today we have quite a list."
		},
		{
			"speaker": "Player",
			"text": "What exactly are you guys buying?"
		},
		{
			"speaker": "Kerwin",
			"text": "Yellow pad papers, definitely."
		},
		{
			"speaker": "Kairi",
			"text": "Three ballpens."
		},
		{
			"speaker": "Nathaly",
			"text": "Correction tape."
		},
		{
			"speaker": "Janssen",
			"text": "And a Discrete Mathematics book."
		},
		{
			"speaker": "Player",
			"text": "That's quite a list for one trip."
		},
		{
			"speaker": "Kerwin",
			"text": "We'll manage."
		},
		{
			"speaker": "Kairi",
			"text": "Let's split up and look for everything."
		},
		{
			"speaker": "Nathaly",
			"text": "Don't forget to check what you already have before buying another one."
		},
		{
			"speaker": "Player",
			"text": "Got it."
		},
		{
			"speaker": "Janssen",
			"text": "Let's meet back here when we're done."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


#QUEST UI
func setup_quest_ui_layout() -> void:

	# 1920x1080 SCREEN LAYOUT

	quest_ui.position = Vector2(
		1480.0,
		80.0
	)

	quest_ui.size = Vector2(
		380.0,
		500.0
	)

	# QUEST TITLE

	quest_title.position = Vector2(
		20.0,
		10.0
	)

	# REQUIRED TITLE

	required_title.position = Vector2(
		20.0,
		55.0
	)

	# REQUIRED ITEMS

	yellow_pad_label.position = Vector2(
		20.0,
		90.0
	)

	ballpens_label.position = Vector2(
		20.0,
		125.0
	)

	correction_tape_label.position = Vector2(
		20.0,
		160.0
	)

	discrete_math_book_label.position = Vector2(
		20.0,
		195.0
	)

	# OPTIONAL TITLE

	optional_title.position = Vector2(
		20.0,
		250.0
	)

	# OPTIONAL OBJECTIVES

	talk_friends_label.position = Vector2(
		20.0,
		285.0
	)

	talk_ate_libro_label.position = Vector2(
		20.0,
		320.0
	)

	talk_kuya_libro_label.position = Vector2(
		20.0,
		355.0
	)

	apply_polished_quest_ui_style()


func show_quest_ui() -> void:

	update_quest_ui()

	quest_ui.visible = true
	quest_ui.modulate.a = 1.0


func update_quest_ui() -> void:

	if GameManager.bookstore_yellow_pad:
		yellow_pad_label.text = "☑ Yellow Pad Paper"
	else:
		yellow_pad_label.text = "☐ Yellow Pad Paper"

	if GameManager.bookstore_ballpens >= 3:
		ballpens_label.text = "☑ Ballpens     3/3"
	else:
		ballpens_label.text = "☐ Ballpens     %d/3" % GameManager.bookstore_ballpens

	if GameManager.bookstore_correction_tape:
		correction_tape_label.text = "☑ Correction Tape"
	else:
		correction_tape_label.text = "☐ Correction Tape"

	if GameManager.bookstore_discrete_math_book:
		discrete_math_book_label.text = "☑ Discrete Math Book"
	else:
		discrete_math_book_label.text = "☐ Discrete Math Book"

	if GameManager.bookstore_talked_to_friends:
		talk_friends_label.text = "☑ Talk to the Friends"
	else:
		talk_friends_label.text = "☐ Talk to the Friends"

	if GameManager.bookstore_talked_to_ate_libro:
		talk_ate_libro_label.text = "☑ Talk to Ate Libro"
	else:
		talk_ate_libro_label.text = "☐ Talk to Ate Libro"

	if GameManager.bookstore_talked_to_kuya_libro:
		talk_kuya_libro_label.text = "☑ Talk to Kuya Libro"
	else:
		talk_kuya_libro_label.text = "☐ Talk to Kuya Libro"

	check_quest_completion()

	var progress_bar := quest_ui.get_node_or_null("PolishedQuestProgress") as ProgressBar
	var progress_text := quest_ui.get_node_or_null("PolishedQuestProgressText") as Label
	update_polished_quest_progress(progress_bar, progress_text)


func check_quest_completion() -> void:

	if (
		GameManager.bookstore_yellow_pad
		and GameManager.bookstore_ballpens >= 3
		and GameManager.bookstore_correction_tape
		and GameManager.bookstore_discrete_math_book
	):

		GameManager.bookstore_completed = true

		if not materials_completion_prompt_started:

			materials_completion_prompt_started = true

			call_deferred(
				"start_materials_complete_event"
			)


#ITEM FUNCTIONS
func collect_yellow_pad() -> void:

	if GameManager.bookstore_yellow_pad:
		return

	GameManager.bookstore_yellow_pad = true

	print("YELLOW PAD COLLECTED")

	update_quest_ui()


func collect_ballpen() -> void:

	if GameManager.bookstore_ballpens >= 3:
		return

	GameManager.bookstore_ballpens += 1

	print(
		"BALLPEN COLLECTED: ",
		GameManager.bookstore_ballpens,
		"/3"
	)

	update_quest_ui()


func collect_correction_tape() -> void:

	if GameManager.bookstore_correction_tape:
		return

	GameManager.bookstore_correction_tape = true

	print("CORRECTION TAPE COLLECTED")

	update_quest_ui()


func collect_discrete_math_book() -> void:

	if GameManager.bookstore_discrete_math_book:
		return

	GameManager.bookstore_discrete_math_book = true

	print("DISCRETE MATH BOOK COLLECTED")

	update_quest_ui()


#OPTIONAL FRIEND CHECKER
func mark_friend_talked(friend_name: String) -> void:

	match friend_name:

		"Kairi":
			GameManager.bookstore_talked_to_kairi = true

		"Kerwin":
			GameManager.bookstore_talked_to_kerwin = true

		"Janssen":
			GameManager.bookstore_talked_to_janssen = true

		"Nathaly":
			GameManager.bookstore_talked_to_nathaly = true

		"Ate Libro":
			GameManager.bookstore_talked_to_ate_libro = true

		"Kuya Libro":
			GameManager.bookstore_talked_to_kuya_libro = true

	check_all_friend_dialogues()

	update_quest_ui()


func check_all_friend_dialogues() -> void:

	if (
		GameManager.bookstore_talked_to_kairi
		and GameManager.bookstore_talked_to_kerwin
		and GameManager.bookstore_talked_to_janssen
		and GameManager.bookstore_talked_to_nathaly
	):

		GameManager.bookstore_talked_to_friends = true


#NPC DIALOGUE
func start_npc_dialogue(npc_name: String) -> void:

	if DialogueManager.is_active:
		return

	print(
		"START NPC DIALOGUE: ",
		npc_name
	)

	# FACE NPC AND PLAYER BEFORE STARTING DIALOGUE
	var interacting_npc: CharacterBody2D = null

	match npc_name:
		"Kairi":
			interacting_npc = kairi
		"Kerwin":
			interacting_npc = kerwin
		"Janssen":
			interacting_npc = janssen
		"Nathaly":
			interacting_npc = nathaly
		"Ate Libro":
			interacting_npc = ate_libro
		"Kuya Libro":
			interacting_npc = kuya_libro

	if interacting_npc != null:

		active_interaction_npc = interacting_npc
		interacting_npc.velocity = Vector2.ZERO
		pause_animation(interacting_npc)

		face_character_toward_character(
			player,
			interacting_npc
		)

		face_character_toward_character(
			interacting_npc,
			player
		)

	# When all required materials have already been collected,
	# Ate Libro becomes the person who handles the purchase question.
	if GameManager.bookstore_completed and npc_name == "Ate Libro":

		await start_ate_libro_purchase_sequence()
		active_interaction_npc = null
		return

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD,
		"Ate Libro": get_character_texture(ate_libro),
		"Kuya Libro": get_character_texture(kuya_libro)
	}

	var dialogue: Array = []

	match npc_name:

		"Kairi":

			if GameManager.bookstore_completed:

				dialogue = [
					{
						"speaker": "Player",
						"text": "I think we have everything already."
					},
					{
						"speaker": "Kairi",
						"text": "Yep, looks like we do. You know, I'm actually relieved. Whenever I make a list for school, I keep checking it over and over because I hate realizing I forgot something."
					},
					{
						"speaker": "Player",
						"text": "You really are the organized one, huh?"
					},
					{
						"speaker": "Kairi",
						"text": "Someone has to be. I'm used to it because I help out at my family's little food stall sometimes. If I don't keep track of orders and supplies, everything turns into chaos."
					},
					{
						"speaker": "Player",
						"text": "So that's where you got the habit."
					},
					{
						"speaker": "Kairi",
						"text": "Probably. It can be tiring, but I don't mind helping them. It also taught me that being dependable isn't always about doing something big. Sometimes it's just remembering the little things other people forget."
					},
					{
						"speaker": "Player",
						"text": "That actually sounds a lot like you."
					},
					{
						"speaker": "Kairi",
						"text": "I'll take that as a compliment. Anyway, let's bring everything to Ate Libro before we somehow manage to forget the entire bag."
					}
				]

			else:

				dialogue = [
					{
						"speaker": "Player",
						"text": "Did you find anything yet?"
					},
					{
						"speaker": "Kairi",
						"text": "I found the yellow pad papers. I always check the stationery section first. My family's food stall made me weirdly good at remembering where things are."
					},
					{
						"speaker": "Player",
						"text": "Wait, you help at your family's stall?"
					},
					{
						"speaker": "Kairi",
						"text": "Yeah. I've been helping whenever I have free time. It started when I was younger, mostly simple things like taking orders or counting change."
					},
					{
						"speaker": "Player",
						"text": "So you're basically used to doing five things at once."
					},
					{
						"speaker": "Kairi",
						"text": "Pretty much. School is still a different kind of busy, though. That's why I like having friends around. It makes stressful days feel a little lighter."
					},
					{
						"speaker": "Player",
						"text": "I'm glad we're doing this together, then."
					},
					{
						"speaker": "Kairi",
						"text": "Me too. Now let's finish the list before we end up wandering around here until closing time."
					}
				]

		"Kerwin":

			if GameManager.bookstore_completed:

				dialogue = [
					{
						"speaker": "Player",
						"text": "Looks like we got everything."
					},
					{
						"speaker": "Kerwin",
						"text": "Finally. I was starting to think we'd have to bring the whole bookstore back with us."
					},
					{
						"speaker": "Player",
						"text": "You always joke around when you're tired."
					},
					{
						"speaker": "Kerwin",
						"text": "It's a habit. Growing up with two older siblings taught me that if I didn't make a joke every now and then, I'd go crazy listening to them argue over everything."
					},
					{
						"speaker": "Player",
						"text": "Were you always like that?"
					},
					{
						"speaker": "Kerwin",
						"text": "Pretty much. I'm also the type who gets curious about how things work. I used to take apart old gadgets at home just to see what was inside. Sometimes I could put them back together. Sometimes... not so much."
					},
					{
						"speaker": "Player",
					"text": "So that's how you ended up liking computers?"
					},
					{
						"speaker": "Kerwin",
					"text": "I think so. There's something satisfying about figuring out why something isn't working and getting it to work again. Anyway, let's get these things to Ate Libro before I start inspecting the shelves too."
					}
				]

			else:

				dialogue = [
					{
						"speaker": "Player",
						"text": "How's the search going?"
					},
					{
						"speaker": "Kerwin",
						"text": "I found some ballpens. Three different ones, actually. I'm comparing them because apparently even buying pens has become a decision now."
					},
					{
						"speaker": "Player",
						"text": "You spend too much time thinking about little things."
					},
					{
						"speaker": "Kerwin",
						"text": "Maybe. I'm just curious about how things work. When I was younger, I used to take apart old electronics at home. My siblings hated it because I sometimes forgot how to put them back together."
					},
					{
						"speaker": "Player",
						"text": "And somehow they still let you touch their stuff?"
					},
					{
						"speaker": "Kerwin",
					"text": "Not anymore. But that curiosity is probably why I got interested in computers. I like solving problems where there's no obvious answer at first."
					},
					{
						"speaker": "Player",
						"text": "That explains why you never stop asking questions."
					},
					{
						"speaker": "Kerwin",
						"text": "Exactly. Now help me find the other two pens before I get distracted by something else."
					}
				]

		"Janssen":

			if GameManager.bookstore_completed:

				dialogue = [
					{
						"speaker": "Player",
						"text": "I finished getting everything on the list."
					},
					{
						"speaker": "Janssen",
						"text": "Good. I was getting worried we'd leave with everything except the correction tape. Somehow that's always the one thing people forget."
					},
					{
						"speaker": "Player",
						"text": "You seem pretty careful about these things."
					},
					{
						"speaker": "Janssen",
						"text": "I like keeping things in order. I'm also into drawing and making little designs when I have time, so I'm used to checking details. Even one small mistake can ruin the whole thing."
					},
					{
						"speaker": "Player",
						"text": "Were you always interested in that?"
					},
					{
						"speaker": "Janssen",
						"text": "Since I was a kid. I used to fill the corners of my notebooks with sketches instead of paying attention. My teachers weren't always happy about it, but they noticed I kept improving."
					},
					{
						"speaker": "Player",
						"text": "I guess it worked out for you."
					},
					{
						"speaker": "Janssen",
						"text": "I hope so. For now, though, let's just get the materials checked by Ate Libro. I'd rather not discover another missing item after we leave."
					}
				]

			else:

				dialogue = [
					{
						"speaker": "Player",
						"text": "Have you found the correction tape?"
					},
					{
						"speaker": "Janssen",
						"text": "Not yet. I've checked this shelf twice already. I swear correction tape likes hiding whenever someone needs it."
					},
					{
						"speaker": "Player",
						"text": "You really notice every little detail, don't you?"
					},
					{
						"speaker": "Janssen",
						"text": "I guess I do. I've always liked drawing and making small designs. When I was younger, I'd draw on practically every spare piece of paper I could find."
					},
					{
						"speaker": "Player",
						"text": "Were your parents okay with that?"
					},
					{
						"speaker": "Janssen",
						"text": "At first, they thought it was just a phase. Eventually they saw that I actually enjoyed it, so they started encouraging me. That's why I try not to rush creative work."
					},
					{
						"speaker": "Player",
						"text": "Maybe we should slow down and actually look, then."
					},
					{
						"speaker": "Janssen",
					"text": "Exactly. Let's check the shelves one more time. We'll find it eventually."
				}
				]

		"Nathaly":

			if GameManager.bookstore_completed:

				dialogue = [
					{
						"speaker": "Player",
						"text": "I think we're done with the list."
					},
					{
						"speaker": "Nathaly",
						"text": "Good. I was about to check the list for the fourth time. I can't help it. I like knowing everything is prepared before class."
					},
					{
						"speaker": "Player",
						"text": "You're the responsible one too, huh?"
					},
					{
						"speaker": "Nathaly",
						"text": "Maybe a little. I'm the oldest among my siblings, so I'm used to being the one who remembers schedules, reminds everyone about things, and fixes problems before they get bigger."
					},
					{
						"speaker": "Player",
						"text": "Doesn't that get exhausting?"
					},
					{
						"speaker": "Nathaly",
						"text": "Sometimes. That's why I appreciate quiet things like reading. Books let me slow down for a while, even when everything around me feels busy."
					},
					{
						"speaker": "Player",
						"text": "So the math book isn't the only kind of book you like."
					},
					{
						"speaker": "Nathaly",
						"text": "Definitely not. Anyway, let's get everything checked by Ate Libro. Once we're done here, I think I've earned a little reading break."
					}
				]

			else:

				dialogue = [
					{
						"speaker": "Player",
						"text": "Any luck?"
					},
					{
						"speaker": "Nathaly",
						"text": "I think I found the section for our math book. Give me a second. I want to make sure it's the right edition before we take it."
					},
					{
						"speaker": "Player",
						"text": "You're really careful about school stuff."
					},
					{
						"speaker": "Nathaly",
						"text": "I have to be. I'm the oldest at home, so I'm used to keeping track of things. My younger siblings are always asking where something is or what they're supposed to do next."
					},
					{
						"speaker": "Player",
						"text": "Sounds like you don't get much time for yourself."
					},
					{
						"speaker": "Nathaly",
						"text": "Not always. Reading helps, though. I've liked books since I was young because they're one of the few things that can make me forget about the clock for a while."
					},
					{
						"speaker": "Player",
						"text": "Maybe after this, you should buy a book you actually want to read."
					},
					{
						"speaker": "Nathaly",
						"text": "That's tempting. But first, let's finish our school list. One trip at a time."
					}
				]

		"Ate Libro":

			dialogue = [
				{
					"speaker": "Player",
					"text": "Hi, Ate. Do you work here?"
				},
				{
					"speaker": "Ate Libro",
					"text": "Yes! I've been helping out here for a while now. What are you looking for?"
				},
				{
					"speaker": "Player",
					"text": "We're looking for school supplies and a Discrete Mathematics book."
				},
				{
					"speaker": "Ate Libro",
					"text": "Then you've come to the right place. I know most of the shelves by heart at this point."
				},
				{
					"speaker": "Player",
					"text": "You seem really familiar with the store."
				},
				{
					"speaker": "Ate Libro",
					"text": "My family has been helping here for years. I started out doing small things like arranging notebooks and cleaning shelves, then I slowly learned how to handle customers and keep track of stock."
				},
				{
					"speaker": "Player",
					"text": "That actually sounds like a lot of work."
				},
				{
					"speaker": "Ate Libro",
					"text": "It can be, especially during enrollment season. But I like meeting students. You get to hear all kinds of stories, and sometimes you see the same people come back years later."
				},
				{
					"speaker": "Player",
					"text": "So you've probably seen a lot of students panic over missing supplies."
				},
				{
					"speaker": "Ate Libro",
					"text": "More times than I can count. Don't worry, though. You won't leave empty-handed."
				}
			]

		"Kuya Libro":

			if GameManager.bookstore_completed:

				dialogue = [
					{
						"speaker": "Player",
						"text": "We have everything on the list now."
					},
					{
						"speaker": "Kuya Libro",
						"text": "Good. You'd be surprised how many people come in for one book and leave with five completely different things."
					},
					{
						"speaker": "Player",
						"text": "Does that happen to you too?"
					},
					{
						"speaker": "Kuya Libro",
						"text": "Sometimes. I've been helping around this shop for years, so I've learned that people usually need more than what they first ask for."
					},
					{
						"speaker": "Player",
						"text": "You actually like working here, don't you?"
					},
					{
						"speaker": "Kuya Libro",
						"text": "I do. I started by helping my family with deliveries and inventory. Eventually I became the guy people asked when they couldn't find a particular book."
					},
					{
						"speaker": "Player",
						"text": "So you're basically the human search bar."
					},
					{
						"speaker": "Kuya Libro",
						"text": "Pretty much. Now just bring everything to Ate Libro. She'll check your items and handle the purchase before you head out."
					}
				]

			else:

				dialogue = [
					{
						"speaker": "Player",
						"text": "Hi, Kuya. Do you know where the Discrete Mathematics books are?"
					},
					{
						"speaker": "Kuya Libro",
						"text": "They're in the academic section near the back. Let me know what edition you're looking for."
					},
					{
						"speaker": "Player",
						"text": "You seem to know this place really well."
					},
					{
						"speaker": "Kuya Libro",
						"text": "I've been helping my family here for years. I started with deliveries and organizing shelves, so I had plenty of time to memorize where everything goes."
					},
					{
						"speaker": "Player",
						"text": "Did you always want to work around books?"
					},
					{
						"speaker": "Kuya Libro",
						"text": "Not really. When I was younger, I thought I'd do something completely different. But I grew to like the quiet parts of the job, especially recommending books to people who don't know what they're looking for yet."
					},
					{
						"speaker": "Player",
						"text": "So if I ask you for a book, you're going to give me a whole list, aren't you?"
					},
					{
						"speaker": "Kuya Libro",
						"text": "Absolutely. But for now, let's make sure you get that math book first. Classes aren't going to wait for us."
					}
				]

		_:

			print(
				"ERROR: Unknown NPC: ",
				npc_name
			)

			active_interaction_npc = null
			return


	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	mark_friend_talked(
		npc_name
	)


#ATE LIBRO PURCHASE CHECK
func start_ate_libro_purchase_sequence() -> void:

	running = true
	GameManager.player_controls_locked = true

	stop_player()

	var portraits: Dictionary = {
		"Ate Libro": get_character_texture(ate_libro)
	}

	var dialogue = [
		{
			"speaker": "Player",
			"text": "Hi, Ate. We have everything we needed from the list."
		},
		{
			"speaker": "Ate Libro",
			"text": "Oh, nice! Is that all you're getting today?"
		},
		{
			"speaker": "Player",
			"text": "I think so."
		},
		{
			"speaker": "Ate Libro",
			"text": "Would you like to purchase everything now, or check for more first?"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	GameManager.bookstore_talked_to_ate_libro = true
	update_quest_ui()

	await show_ate_purchase_choice()

	if departure_choice_result == 3:

		await head_out_route()

	else:

		GameManager.player_controls_locked = false

		player.set_physics_process(true)

		running = false


func show_ate_purchase_choice() -> void:

	departure_choice_mode = 1
	departure_choice_result = 0

	var choice_ui := COZY_CHOICE_UI.new()
	get_tree().current_scene.add_child(choice_ui)

	departure_choice_result = await choice_ui.show_choice(
		"WHAT WOULD YOU LIKE TO DO?",
		"Everything on the list is ready. Would you like to purchase the items now or look around for more?",
		"PURCHASE ITEMS",
		"LOOK AROUND",
		3,
		4,
		Color("#D8A15D")
	)

	departure_choice_mode = 0

func _on_player_interaction_zone_body_entered(body: Node2D) -> void:

	if body == kairi:

		kairi_inside_player_interaction_zone = true

		# Face both characters as soon as Kairi enters the player's interaction zone.
		face_character_toward_character(
			player,
			kairi
		)

		face_character_toward_character(
			kairi,
			player
		)


func _on_player_interaction_zone_body_exited(body: Node2D) -> void:

	if body == kairi:

		kairi_inside_player_interaction_zone = false


func is_kairi_inside_player_interaction_zone() -> bool:

	if kairi_inside_player_interaction_zone:
		return true

	if player_interaction_zone == null:
		return false

	if player_interaction_zone.has_method("has_overlapping_bodies"):

		var overlapping_bodies: Array[Node2D] = (
			player_interaction_zone.get_overlapping_bodies()
		)

		if overlapping_bodies.has(kairi):
			return true

	return false


#ALL REQUIRED MATERIALS HAVE BEEN COLLECTED
func start_materials_complete_event() -> void:

	if running:
		return

	running = true

	GameManager.player_controls_locked = true

	# Keep the other bookstore NPCs alive and wandering during Kairi's mini cutscene.
	# Kairi herself remains excluded because she is being controlled by the cinematic.
	allow_npc_wandering_during_kairi_event = true

	stop_player()

	await show_cinematic_bars()

	await focus_on_kairi_and_player()

	await kairi_walk_to_player()

	await start_materials_complete_dialogue()

	await show_departure_choice()

	if departure_choice_result == 1:

		# Keep the other NPCs wandering while Kairi gives her "check more" response.
		# Kairi herself remains under scripted control until this route finishes.
		await check_more_route()

	else:

		# Stop the free-wandering exception before the heading-out route begins.
		allow_npc_wandering_during_kairi_event = false

		await head_out_route()


func focus_on_kairi_and_player() -> void:

	var midpoint: Vector2 = (
		kairi.global_position
		+ player.global_position
	) / 2.0

	cinematic_camera.global_position = midpoint

	if player_camera:
		cinematic_camera.zoom = player_camera.zoom

	cinematic_camera.enabled = true

	if player_camera:
		player_camera.enabled = false

	await get_tree().create_timer(
		0.3
	).timeout


#KAIRI WALKS TO PLAYER
func kairi_walk_to_player() -> void:

	await get_tree().physics_frame

	# Reset the zone state before Kairi starts approaching.
	kairi_inside_player_interaction_zone = false

	var navigation_map: RID = kairi_navigation_agent.get_navigation_map()

	if not navigation_map.is_valid():

		print(
			"ERROR: Kairi NavigationAgent2D does not have a valid navigation map."
		)

		return

	# Kairi no longer tries to walk to the front of the player.
	# She simply navigates toward the player's actual position and stops
	# as soon as she enters the player's InteractionZone.
	kairi_navigation_agent.target_position = get_safe_navigation_target(
		kairi_navigation_agent,
		player.global_position
	)

	while true:

		# The InteractionZone is now the exact trigger for the conversation.
		# As soon as Kairi enters it, stop her and let the dialogue begin.
		if is_kairi_inside_player_interaction_zone():
			break

		var distance_to_player: float = kairi.global_position.distance_to(
			player.global_position
		)

		if distance_to_player <= 30.0:

			face_character_toward_character(
				player,
				kairi
			)

		if kairi_navigation_agent.is_navigation_finished():

			# Navigation may finish at the edge of an obstacle.
			# Keep checking the InteractionZone for one more frame instead of
			# starting the dialogue early.
			await get_tree().physics_frame

			if is_kairi_inside_player_interaction_zone():
				break

			continue

		var next_position: Vector2 = (
			kairi_navigation_agent.get_next_path_position()
		)

		var direction: Vector2 = (
			next_position
			- kairi.global_position
		)

		if direction.length() <= 2.0:
			await get_tree().physics_frame
			continue

		direction = direction.normalized()

		kairi.velocity = (
			direction
			* KAIRI_WALK_SPEED
		)

		play_kairi_walk_animation(
			direction
		)

		kairi.move_and_slide()

		# Turn the player toward Kairi naturally as she gets close.
		if kairi.global_position.distance_to(
			player.global_position
		) <= 30.0:

			face_character_toward_character(
				player,
				kairi
			)

		await get_tree().physics_frame

	kairi.velocity = Vector2.ZERO

	# Make both characters face each other immediately before the dialogue starts.
	face_character_toward_character(
		player,
		kairi
	)

	face_character_toward_character(
		kairi,
		player
	)

	await get_tree().create_timer(
		0.05
	).timeout


func move_kairi_directly(
	target_position: Vector2
) -> void:

	# Navigation is required for the bookstore cinematic movement.
	# This function is kept only for compatibility with older calls.
	await kairi_walk_to_navigation_target(
		kairi,
		kairi_navigation_agent,
		target_position,
		KAIRI_WALK_SPEED
	)


func get_safe_navigation_target(
	agent: NavigationAgent2D,
	target_position: Vector2
) -> Vector2:

	var navigation_map: RID = agent.get_navigation_map()

	if not navigation_map.is_valid():
		return target_position

	return NavigationServer2D.map_get_closest_point(
		navigation_map,
		target_position
	)


func setup_navigation_agent(
	agent: NavigationAgent2D
) -> void:

	if agent == null:
		return

	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 5.0
	agent.path_max_distance = 1000.0
	agent.radius = 16.0
	agent.neighbor_distance = 100.0
	agent.avoidance_enabled = true


func get_or_create_navigation_agent(
	character: CharacterBody2D,
	agent_name: String
) -> NavigationAgent2D:

	if character == null:
		return null

	var agent := character.get_node_or_null(
		agent_name
	) as NavigationAgent2D

	if agent == null:

		agent = NavigationAgent2D.new()
		agent.name = agent_name
		character.add_child(agent)

	setup_navigation_agent(agent)

	return agent


func kairi_walk_to_navigation_target(
	character: CharacterBody2D,
	agent: NavigationAgent2D,
	target_position: Vector2,
	walk_speed: float
) -> void:

	if character == null or agent == null:
		return

	await get_tree().physics_frame

	var navigation_map: RID = agent.get_navigation_map()

	if not navigation_map.is_valid():

		print(
			"ERROR: NavigationAgent2D does not have a valid navigation map for ",
			character.name
		)

		character.velocity = Vector2.ZERO
		return

	agent.target_position = get_safe_navigation_target(
		agent,
		target_position
	)

	while not agent.is_navigation_finished():

		var next_position: Vector2 = (
			agent.get_next_path_position()
		)

		var direction: Vector2 = (
			next_position
			- character.global_position
		)

		if direction.length() <= 2.0:
			character.velocity = Vector2.ZERO
			await get_tree().physics_frame
			continue

		direction = direction.normalized()

		character.velocity = (
			direction
			* walk_speed
		)

		update_walk_animation_toward(
			character,
			next_position
		)

		character.move_and_slide()

		await get_tree().physics_frame

	character.velocity = Vector2.ZERO


func get_player_facing_direction() -> Vector2:

	var sprite := player.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		var animation_name: String = str(
			sprite.animation
		)

		if animation_name.ends_with(
			"_up"
		):

			return Vector2.UP

		if animation_name.ends_with(
			"_down"
		):

			return Vector2.DOWN

		if animation_name.ends_with(
			"_left"
		):

			return Vector2.LEFT

		if animation_name.ends_with(
			"_right"
		):

			return Vector2.RIGHT

	return Vector2.DOWN


func play_kairi_walk_animation(
	direction: Vector2
) -> void:

	var sprite := kairi.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
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

	if sprite.sprite_frames.has_animation(
		animation_name
	):

		# Keep Kairi's AnimatedSprite2D running at normal playback speed during the cinematic.
		sprite.speed_scale = 1.0

		# Explicitly keep Kairi's walking animation playing while the cutscene moves her.
		# The global NPC pause routine is excluded during this cutscene, so the frames
		# can advance normally instead of getting frozen on the first walking frame.
		sprite.play(
			animation_name
		)


#MATERIALS COMPLETE DIALOGUE
func start_materials_complete_dialogue() -> void:

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Oh, you got all the things we need! That's great!"
		},
		{
			"speaker": "Kairi",
			"text": "Do you want to check for more stuff or do you want us to head on out already?"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


#DEPARTURE CHOICE
func setup_departure_choice() -> void:

	departure_choice.position = Vector2(
		600.0,
		330.0
	)

	departure_choice.size = Vector2(
		720.0,
		360.0
	)

	departure_question.position = Vector2(
		40.0,
		65.0
	)

	departure_question.size = Vector2(
		640.0,
		115.0
	)

	departure_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	departure_question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	departure_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	check_more_button.position = Vector2(
		60.0,
		250.0
	)

	check_more_button.size = Vector2(
		280.0,
		70.0
	)

	head_out_button.position = Vector2(
		380.0,
		250.0
	)

	head_out_button.size = Vector2(
		280.0,
		70.0
	)

	departure_question.text = (
		"Do you want to check for more stuff or head out?"
	)

	check_more_button.text = "Check for More"

	head_out_button.text = "Head Out"

	apply_polished_choice_style()

func show_departure_choice() -> void:

	departure_choice_mode = 0
	departure_choice_result = 0

	var choice_ui := COZY_CHOICE_UI.new()
	get_tree().current_scene.add_child(choice_ui)

	departure_choice_result = await choice_ui.show_choice(
		"READY TO MOVE ON?",
		"Would you like to check for more stuff or head out with the group?",
		"CHECK FOR MORE",
		"HEAD OUT",
		1,
		2,
		Color("#D8A15D")
	)

func _on_check_more_pressed() -> void:

	if departure_choice_mode == 1:

		departure_choice_result = 3

	else:

		departure_choice_result = 1

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_head_out_pressed() -> void:

	if departure_choice_mode == 1:

		departure_choice_result = 4

	else:

		departure_choice_result = 2

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


#CHECK MORE ROUTE
func check_more_route() -> void:

	# The other NPCs are intentionally allowed to keep wandering during this route.
	allow_npc_wandering_during_kairi_event = true

	var portraits: Dictionary = {
		"Kairi": KAIRI_HD
	}

	var dialogue = [
		{
			"speaker": "Kairi",
			"text": "Oh okay, take your time! We're not really in a rush anyway."
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished

	# Kairi no longer walks back to her original position here.
	# She simply stays where the mini cutscene ended, which prevents the other NPCs
	# from accidentally blocking her route back.
	kairi.velocity = Vector2.ZERO
	play_idle_animation_for_character(
		kairi,
		get_facing_direction_for_character(kairi)
	)

	await hide_cinematic_bars()

	cinematic_camera.enabled = false

	if player_camera:

		player_camera.enabled = true
		player_camera.make_current()

	await get_tree().process_frame

	# Return the AI to its normal state and immediately give every wandering NPC
	# a fresh destination. This prevents the NPCs from remaining paused after the choice.
	allow_npc_wandering_during_kairi_event = false
	resume_npc_wandering_immediately()

	GameManager.player_controls_locked = false

	player.set_physics_process(true)

	running = false


#RESUME NPC WANDERING AFTER THE KAIRI MINI CUTSCENE
func resume_npc_wandering_immediately() -> void:

	for npc in npc_wander_npcs:

		if npc == null or not npc.is_inside_tree() or not npc.visible:
			continue

		if not npc_wander_states.has(npc):
			continue

		var state: Dictionary = npc_wander_states[npc]

		# Give the NPC a completely fresh destination so it does not continue from
		# an old paused target from before the mini cutscene.
		choose_new_wander_target(npc, state)
		state["idle_time"] = 0.0
		state["stuck_time"] = 0.0
		state["walk_time"] = 0.0

		npc.velocity = Vector2.ZERO

	# Kairi is allowed to resume the same normal wandering AI as everyone else
	# after the scripted mini cutscene has completely finished.
	if npc_wander_states.has(kairi):

		var kairi_state: Dictionary = npc_wander_states[kairi]
		kairi_state["idle_time"] = 0.0
		kairi_state["stuck_time"] = 0.0
		kairi_state["walk_time"] = 0.0


func get_facing_direction_for_character(
	character: CharacterBody2D
) -> Vector2:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return Vector2.DOWN

	var animation_name: String = str(sprite.animation)

	if animation_name.ends_with("_up"):
		return Vector2.UP

	if animation_name.ends_with("_left"):
		return Vector2.LEFT

	if animation_name.ends_with("_right"):
		return Vector2.RIGHT

	return Vector2.DOWN


func play_idle_animation_for_character(
	character: CharacterBody2D,
	direction: Vector2
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null:
		return

	var animation_name := "idle_down"

	if abs(direction.x) > abs(direction.y):

		if direction.x > 0.0:
			animation_name = "idle_right"
		else:
			animation_name = "idle_left"

	else:

		if direction.y < 0.0:
			animation_name = "idle_up"
		else:
			animation_name = "idle_down"

	if sprite.sprite_frames.has_animation(animation_name):

		sprite.speed_scale = 1.0
		sprite.play(animation_name)


#KAIRI RETURNS TO HER ORIGINAL POSITION
func kairi_return_to_original_position() -> void:

	await kairi_walk_to_navigation_target(
		kairi,
		kairi_navigation_agent,
		kairi_return_position,
		KAIRI_WALK_SPEED
	)


#HEAD OUT ROUTE
func head_out_route() -> void:

	GameManager.player_controls_locked = true

	# Kuya Libro continues his autonomous wandering throughout the heading-out scene.
	# The departing group remains under scripted control.
	allow_kuya_wandering_during_head_out = true

	quest_ui.visible = false

	await fade_to_black()

	reposition_group_at_purchase_counter()

	await get_tree().create_timer(
		0.3
	).timeout

	await fade_from_black()

	await show_cinematic_bars()

	# Prepare the scripted group so their own NPC movement scripts cannot pause
	# or override the walking animations during the departure sequence.
	prepare_heading_out_characters()

	await start_purchase_dialogue()

	await hide_cinematic_bars()

	await walk_group_to_exit()

	allow_kuya_wandering_during_head_out = false
	active_interaction_npc = null

	GameManager.bookstore_return_event_pending = true

	await FadeManager.change_scene_with_fade(
		"res://scenes/main_level_scenes/School.tscn"
	)


#PURCHASE COUNTER POSITION
func reposition_group_at_purchase_counter() -> void:

	var center := purchase_spot.global_position

	# Keep everyone closer together and move the group slightly to the right.
	player.global_position = center + Vector2(
		30.0,
		65.0
	)

	kairi.global_position = center + Vector2(
		-30.0,
		15.0
	)

	kerwin.global_position = center + Vector2(
		30.0,
		15.0
	)

	janssen.global_position = center + Vector2(
		-30.0,
		55.0
	)

	nathaly.global_position = center + Vector2(
		30.0,
		55.0
	)

	player.rotation_degrees = 0.0

	kairi.visible = true
	kerwin.visible = true
	janssen.visible = true
	nathaly.visible = true
	player.visible = true

	stop_player()

	face_character_down(
		kairi
	)

	face_character_down(
		kerwin
	)

	face_character_down(
		janssen
	)

	face_character_down(
		nathaly
	)


#PURCHASE DIALOGUE
func start_purchase_dialogue() -> void:

	var portraits: Dictionary = {
		"Kuya Libro": get_character_texture(kuya_libro),
		"Ate Libro": get_character_texture(ate_libro),
		"Kairi": KAIRI_HD,
		"Kerwin": KERWIN_HD,
		"Janssen": JANSSEN_HD,
		"Nathaly": NATHALY_HD
	}

	var dialogue = [
		{
			"speaker": "Kuya Libro",
			"text": "Alright, let's get everything checked out."
		},
		{
			"speaker": "Ate Libro",
			"text": "Looks like you kids got everything you needed."
		},
		{
			"speaker": "Kuya Libro",
			"text": "Thank you for stopping by! Come back anytime you kids need."
		},
		{
			"speaker": "Ate Libro",
			"text": "Take care, and good luck with your classes!"
		},
		{
			"speaker": "Kairi",
			"text": "Thank you!"
		},
		{
			"speaker": "Kerwin",
			"text": "Yeah, thanks for helping us out!"
		},
		{
			"speaker": "Janssen",
			"text": "We'll definitely come back."
		},
		{
			"speaker": "Nathaly",
			"text": "See you next time!"
		},
		{
			"speaker": "Player",
			"text": "Thank you!"
		}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		portraits,
		PLAYER_HD
	)

	await DialogueManager.dialogue_finished


#HEADING OUT ANIMATION CONTROL
func prepare_heading_out_characters() -> void:

	heading_out_animation_active = true

	var scripted_characters: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly
	]

	for character in scripted_characters:

		if character == null or not character.is_inside_tree():
			continue

		# Their movement and animation are controlled directly by this controller
		# during the departure sequence, so their own scripts must not override it.
		character.set_physics_process(false)
		character.set_process(false)

		var sprite := character.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

		if sprite != null:
			sprite.speed_scale = 1.0
			sprite.stop()


func restore_heading_out_characters() -> void:

	var scripted_characters: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly
	]

	for character in scripted_characters:

		if character == null or not character.is_inside_tree():
			continue

		character.set_physics_process(true)
		character.set_process(true)


func play_heading_out_walk_animation(
	character: CharacterBody2D,
	direction: Vector2
) -> void:

	if character == null:
		return

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite == null or direction.length() <= 0.01:
		return

	var animation_name := "walk_down"

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

	if not sprite.sprite_frames.has_animation(animation_name):
		return

	# Make absolutely sure the animation is allowed to advance.
	sprite.speed_scale = 1.0

	if sprite.animation != animation_name:
		sprite.play(animation_name)
	elif not sprite.is_playing():
		sprite.play(animation_name)

	# Keep the animation playing; AnimatedSprite2D does not use a writable `playing` property here.
	if not sprite.is_playing():
		sprite.play(animation_name)


#GROUP WALKS TO DOOR
func walk_group_to_exit() -> void:

	await get_tree().physics_frame

	var exit_center := exit_spot.global_position

	var characters: Array[CharacterBody2D] = [
		kairi,
		kerwin,
		janssen,
		nathaly,
		player
	]

	var agents: Array[NavigationAgent2D] = [
		kairi_navigation_agent,
		kerwin_navigation_agent,
		janssen_navigation_agent,
		nathaly_navigation_agent,
		player_navigation_agent
	]

	var exit_targets: Array[Vector2] = [
		exit_center + Vector2(0.0, -24.0),
		exit_center + Vector2(0.0, 8.0),
		exit_center + Vector2(0.0, 32.0),
		exit_center + Vector2(0.0, 56.0),
		exit_center + Vector2(0.0, 60.0)
	]

	var walk_speed: float = 60.0

	# Start the characters one after another instead of making everyone
	# walk at the exact same time. This creates a more natural line
	# and greatly reduces characters getting stuck on each other's collisions.
	var departure_stagger: float = 0.75
	var scene_start_time: float = Time.get_ticks_msec() / 1000.0
	var start_times: Array[float] = []

	for i in range(characters.size()):

		start_times.append(
			scene_start_time + (float(i) * departure_stagger)
		)

		var character: CharacterBody2D = characters[i]
		var agent: NavigationAgent2D = agents[i]

		if character == null or agent == null:
			continue

		var navigation_map: RID = agent.get_navigation_map()

		if not navigation_map.is_valid():

			print(
				"ERROR: NavigationAgent2D does not have a valid navigation map for ",
				character.name
			)

			continue

		agent.target_position = get_safe_navigation_target(
			agent,
			exit_targets[i]
		)

	await get_tree().physics_frame

	while true:

		var someone_reached_exit := false
		var current_time: float = Time.get_ticks_msec() / 1000.0

		for i in range(characters.size()):

			var character: CharacterBody2D = characters[i]
			var agent: NavigationAgent2D = agents[i]

			if character == null or agent == null:
				continue

			# Release each character one at a time.
			# Kairi goes first, then Kerwin, Janssen, Nathaly, and finally the player.
			if current_time < start_times[i]:
				character.velocity = Vector2.ZERO
				pause_animation(character)
				continue

			var target_position: Vector2 = agent.target_position
			var distance_to_target: float = character.global_position.distance_to(
				target_position
			)
			var distance_to_exit: float = character.global_position.distance_to(
				exit_center
			)

			# TRANSITION AS SOON AS ONE CHARACTER REACHES THE EXIT AREA.
			if distance_to_exit <= 18.0 or distance_to_target <= 10.0:

				character.velocity = Vector2.ZERO
				pause_animation(character)
				someone_reached_exit = true
				break

			if agent.is_navigation_finished():

				if distance_to_target <= 18.0:

					character.velocity = Vector2.ZERO
					pause_animation(character)
					someone_reached_exit = true
					break

				continue

			var next_position: Vector2 = (
				agent.get_next_path_position()
			)

			var direction: Vector2 = (
				next_position
				- character.global_position
			)

			if direction.length() <= 2.0:
				character.velocity = Vector2.ZERO
				continue

			direction = direction.normalized()

			character.velocity = (
				direction
				* walk_speed
			)

			# Explicitly keep the walking animation active during the heading-out cutscene.
			# This also resumes the animation if it was previously paused by the dialogue.
			play_heading_out_walk_animation(
				character,
				direction
			)

			character.move_and_slide()

			# Re-assert the walking animation after movement so another script or
			# a previous pause cannot leave the sprite frozen on one frame.
			play_heading_out_walk_animation(
				character,
				direction
			)

		if cinematic_camera.enabled:

			var group_center: Vector2 = Vector2.ZERO
			var visible_count: int = 0

			for character in characters:

				if character != null and character.visible:
					group_center += character.global_position
					visible_count += 1

			if visible_count > 0:

				group_center /= float(visible_count)

				cinematic_camera.global_position = cinematic_camera.global_position.lerp(
					group_center,
					0.12
				)

		# Only ONE character needs to reach the exit area.
		if someone_reached_exit:
			break

		await get_tree().physics_frame

	for character in characters:

		if character != null:
			character.velocity = Vector2.ZERO
			pause_animation(character)

	heading_out_animation_active = false
	restore_heading_out_characters()


#BLACK TRANSITION
func setup_black_overlay() -> void:

	black_overlay = ColorRect.new()

	black_overlay.color = Color.BLACK

	black_overlay.position = Vector2.ZERO

	black_overlay.size = get_viewport().get_visible_rect().size

	black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	black_overlay.z_index = 100

	black_overlay.modulate.a = 0.0
	black_overlay.visible = false

	$"../CinematicUI".add_child(
		black_overlay
	)


func fade_to_black() -> void:

	if black_overlay == null:
		return

	black_overlay.visible = true
	black_overlay.modulate.a = 0.0

	var tween := create_tween()

	tween.tween_property(
		black_overlay,
		"modulate:a",
		1.0,
		0.6
	)

	await tween.finished


func fade_from_black() -> void:

	if black_overlay == null:
		return

	black_overlay.visible = true
	black_overlay.modulate.a = 1.0

	var tween := create_tween()

	tween.tween_property(
		black_overlay,
		"modulate:a",
		0.0,
		0.6
	)

	await tween.finished

	black_overlay.visible = false


#CHARACTER MOVEMENT
func move_character_step(
	character: CharacterBody2D,
	target_position: Vector2,
	speed: float,
	delta: float
) -> void:

	character.global_position = character.global_position.move_toward(
		target_position,
		speed * delta
	)


func update_walk_animation_toward(
	character: CharacterBody2D,
	target_position: Vector2
) -> void:

	var difference: Vector2 = (
		target_position
		- character.global_position
	)

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

	play_animation(
		character,
		"walk_" + direction_name
	)


func play_animation(
	character: CharacterBody2D,
	animation_name: String
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		if sprite.sprite_frames.has_animation(
			animation_name
		):

			# Always restore normal animation playback speed after cinematic/dialogue pauses.
			sprite.speed_scale = 1.0

			# Explicitly play every movement update so a previously paused sprite
			# cannot remain frozen on a single walking frame.
			sprite.play(
				animation_name
			)


func pause_animation(
	character: CharacterBody2D
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:
		sprite.pause()


func face_character_toward_character(
	character: CharacterBody2D,
	target_character: CharacterBody2D
) -> void:

	if character == null or target_character == null:
		return

	var difference: Vector2 = (
		target_character.global_position
		- character.global_position
	)

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


#FACING
func face_character_toward_player(
	character: CharacterBody2D
) -> void:

	var difference: Vector2 = (
		player.global_position
		- character.global_position
	)

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


func face_character_right(
	character: CharacterBody2D
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		sprite.flip_h = false

		if sprite.sprite_frames.has_animation(
			"idle_right"
		):

			sprite.play(
				"idle_right"
			)

			sprite.frame = 0
			sprite.pause()


func face_character_left(
	character: CharacterBody2D
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		if sprite.sprite_frames.has_animation(
			"idle_left"
		):

			sprite.flip_h = false

			sprite.play(
				"idle_left"
			)

			sprite.frame = 0
			sprite.pause()

		elif sprite.sprite_frames.has_animation(
			"idle_right"
		):

			sprite.flip_h = true

			sprite.play(
				"idle_right"
			)

			sprite.frame = 0
			sprite.pause()


func face_character_up(
	character: CharacterBody2D
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		sprite.flip_h = false

		if sprite.sprite_frames.has_animation(
			"idle_up"
		):

			sprite.play(
				"idle_up"
			)

			sprite.frame = 0
			sprite.pause()


func face_character_down(
	character: CharacterBody2D
) -> void:

	var sprite := character.get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if sprite:

		sprite.flip_h = false

		if sprite.sprite_frames.has_animation(
			"idle_down"
		):

			sprite.play(
				"idle_down"
			)

			sprite.frame = 0
			sprite.pause()


func get_character_texture(
	character: Node
) -> Texture2D:

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

		if animated_sprite.sprite_frames.has_animation(
			animation_name
		):

			var frame_count: int = (
				animated_sprite.sprite_frames.get_frame_count(
					animation_name
				)
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


# POLISHED BOOKSTORE UI
func make_ui_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int = 2,
	corner_radius: int = 12,
	shadow_size: int = 12
) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 5.0)
	style.anti_aliasing = true

	return style


func apply_button_style(
	button: Button,
	accent: Color,
	base_color: Color
) -> void:

	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)

	var normal := make_ui_panel_style(
		base_color,
		Color(1.0, 1.0, 1.0, 0.14),
		1,
		10,
		5
	)

	var hover := normal.duplicate()
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.bg_color = Color(
		min(base_color.r + 0.06, 1.0),
		min(base_color.g + 0.06, 1.0),
		min(base_color.b + 0.06, 1.0),
		1.0
	)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(
		max(base_color.r - 0.05, 0.0),
		max(base_color.g - 0.05, 0.0),
		max(base_color.b - 0.05, 0.0),
		1.0
	)

	var focus := hover.duplicate()
	focus.shadow_color = Color(
		accent.r,
		accent.g,
		accent.b,
		0.30
	)
	focus.shadow_size = 8

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)


func apply_polished_choice_style() -> void:

	if departure_choice == null:
		return

	var existing_background := departure_choice.get_node_or_null("PolishedBackground") as Panel

	if existing_background == null:

		existing_background = Panel.new()
		existing_background.name = "PolishedBackground"
		existing_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		existing_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		existing_background.z_index = -10
		departure_choice.add_child(existing_background)

	var existing_accent := departure_choice.get_node_or_null("PolishedAccent") as ColorRect

	if existing_accent == null:

		existing_accent = ColorRect.new()
		existing_accent.name = "PolishedAccent"
		existing_accent.position = Vector2(0.0, 0.0)
		existing_accent.size = Vector2(departure_choice.size.x, 8.0)
		existing_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		departure_choice.add_child(existing_accent)

	var existing_header := departure_choice.get_node_or_null("PolishedHeader") as Label

	if existing_header == null:

		existing_header = Label.new()
		existing_header.name = "PolishedHeader"
		existing_header.position = Vector2(30.0, 22.0)
		existing_header.size = Vector2(departure_choice.size.x - 60.0, 28.0)
		existing_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		departure_choice.add_child(existing_header)

	var existing_divider := departure_choice.get_node_or_null("PolishedDivider") as ColorRect

	if existing_divider == null:

		existing_divider = ColorRect.new()
		existing_divider.name = "PolishedDivider"
		existing_divider.position = Vector2(60.0, 210.0)
		existing_divider.size = Vector2(departure_choice.size.x - 120.0, 2.0)
		existing_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		departure_choice.add_child(existing_divider)

	var accent := Color("#D8A15D")

	if departure_choice_mode == 1:
		accent = Color("#C89255")

	existing_background.add_theme_stylebox_override(
		"panel",
		make_ui_panel_style(
			Color("#3A281E"),
			Color(accent.r, accent.g, accent.b, 0.80),
			3,
			16,
			18
		)
	)

	existing_accent.color = accent
	existing_header.text = "BOOKSTORE • A COZY LITTLE DECISION"
	existing_header.add_theme_font_size_override("font_size", 15)
	existing_header.add_theme_color_override("font_color", accent)

	existing_divider.color = Color(accent.r, accent.g, accent.b, 0.28)

	departure_question.add_theme_font_size_override("font_size", 23)
	departure_question.add_theme_color_override(
		"font_color",
		Color("#F6E7D2")
	)
	departure_question.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.40)
	)
	departure_question.add_theme_constant_override("shadow_offset_x", 1)
	departure_question.add_theme_constant_override("shadow_offset_y", 2)

	apply_button_style(
		check_more_button,
		accent,
		Color("#5B3E2C")
	)

	apply_button_style(
		head_out_button,
		accent,
		Color("#4A3325")
	)

	departure_choice.move_child(existing_background, 0)
	departure_choice.move_child(existing_accent, 1)
	departure_choice.move_child(existing_header, 2)
	departure_choice.move_child(existing_divider, 3)


func apply_polished_quest_ui_style() -> void:

	if quest_ui == null:
		return

	var background := quest_ui.get_node_or_null("PolishedQuestBackground") as Panel

	if background == null:

		background = Panel.new()
		background.name = "PolishedQuestBackground"
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.z_index = -10
		quest_ui.add_child(background)

	var accent_bar := quest_ui.get_node_or_null("PolishedQuestAccent") as ColorRect

	if accent_bar == null:

		accent_bar = ColorRect.new()
		accent_bar.name = "PolishedQuestAccent"
		accent_bar.position = Vector2(0.0, 0.0)
		accent_bar.size = Vector2(quest_ui.size.x, 7.0)
		accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(accent_bar)

	var small_header := quest_ui.get_node_or_null("PolishedQuestHeader") as Label

	if small_header == null:

		small_header = Label.new()
		small_header.name = "PolishedQuestHeader"
		small_header.position = Vector2(20.0, 15.0)
		small_header.size = Vector2(340.0, 20.0)
		small_header.text = "TODAY'S SHOPPING LIST"
		small_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(small_header)

	var progress_bar := quest_ui.get_node_or_null("PolishedQuestProgress") as ProgressBar

	if progress_bar == null:

		progress_bar = ProgressBar.new()
		progress_bar.name = "PolishedQuestProgress"
		progress_bar.position = Vector2(20.0, 82.0)
		progress_bar.size = Vector2(340.0, 14.0)
		progress_bar.show_percentage = false
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(progress_bar)

	var progress_text := quest_ui.get_node_or_null("PolishedQuestProgressText") as Label

	if progress_text == null:

		progress_text = Label.new()
		progress_text.name = "PolishedQuestProgressText"
		progress_text.position = Vector2(20.0, 55.0)
		progress_text.size = Vector2(340.0, 24.0)
		progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(progress_text)

	var required_divider := quest_ui.get_node_or_null("PolishedRequiredDivider") as ColorRect

	if required_divider == null:

		required_divider = ColorRect.new()
		required_divider.name = "PolishedRequiredDivider"
		required_divider.position = Vector2(20.0, 127.0)
		required_divider.size = Vector2(340.0, 2.0)
		required_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(required_divider)

	var optional_divider := quest_ui.get_node_or_null("PolishedOptionalDivider") as ColorRect

	if optional_divider == null:

		optional_divider = ColorRect.new()
		optional_divider.name = "PolishedOptionalDivider"
		optional_divider.position = Vector2(20.0, 330.0)
		optional_divider.size = Vector2(340.0, 2.0)
		optional_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_ui.add_child(optional_divider)

	var accent := Color("#D8A15D")

	background.add_theme_stylebox_override(
		"panel",
		make_ui_panel_style(
			Color("#3A281E"),
			Color(accent.r, accent.g, accent.b, 0.72),
			2,
			15,
			14
		)
	)

	accent_bar.color = accent
	small_header.add_theme_font_size_override("font_size", 14)
	small_header.add_theme_color_override("font_color", accent)
	progress_text.add_theme_font_size_override("font_size", 15)
	progress_text.add_theme_color_override("font_color", Color("#D9C1A7"))

	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color("#6A4A35")
	progress_bg.set_corner_radius_all(7)
	progress_bar.add_theme_stylebox_override("background", progress_bg)

	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = accent
	progress_fill.set_corner_radius_all(7)
	progress_bar.add_theme_stylebox_override("fill", progress_fill)

	required_divider.color = Color(accent.r, accent.g, accent.b, 0.25)
	optional_divider.color = Color(accent.r, accent.g, accent.b, 0.25)

	quest_title.add_theme_font_size_override("font_size", 25)
	quest_title.add_theme_color_override("font_color", Color.WHITE)
	required_title.add_theme_font_size_override("font_size", 16)
	required_title.add_theme_color_override("font_color", accent)
	optional_title.add_theme_font_size_override("font_size", 16)
	optional_title.add_theme_color_override("font_color", accent)

	var required_labels: Array[Label] = [
		yellow_pad_label,
		ballpens_label,
		correction_tape_label,
		discrete_math_book_label
	]

	var optional_labels: Array[Label] = [
		talk_friends_label,
		talk_ate_libro_label,
		talk_kuya_libro_label
	]

	for label in required_labels:
		style_quest_label(label)

	for label in optional_labels:
		style_quest_label(label)

	# Reposition the existing labels into the new panel hierarchy.
	quest_title.position = Vector2(20.0, 35.0)
	quest_title.size = Vector2(220.0, 32.0)

	required_title.position = Vector2(20.0, 138.0)
	required_title.size = Vector2(340.0, 24.0)

	yellow_pad_label.position = Vector2(20.0, 170.0)
	ballpens_label.position = Vector2(20.0, 207.0)
	correction_tape_label.position = Vector2(20.0, 244.0)
	discrete_math_book_label.position = Vector2(20.0, 281.0)

	optional_title.position = Vector2(20.0, 341.0)
	optional_title.size = Vector2(340.0, 24.0)

	talk_friends_label.position = Vector2(20.0, 370.0)
	talk_ate_libro_label.position = Vector2(20.0, 405.0)
	talk_kuya_libro_label.position = Vector2(20.0, 440.0)

	quest_ui.move_child(background, 0)
	quest_ui.move_child(accent_bar, 1)
	quest_ui.move_child(small_header, 2)
	quest_ui.move_child(progress_text, 3)
	quest_ui.move_child(progress_bar, 4)
	quest_ui.move_child(required_divider, 5)
	quest_ui.move_child(optional_divider, 6)

	update_polished_quest_progress(progress_bar, progress_text)


func style_quest_label(label: Label) -> void:

	if label == null:
		return

	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override(
		"font_color",
		Color("#E8D2B6")
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_polished_quest_progress(
	progress_bar: ProgressBar,
	progress_text: Label
) -> void:

	if progress_bar == null or progress_text == null:
		return

	var completed_required: int = 0

	if GameManager.bookstore_yellow_pad:
		completed_required += 1
	if GameManager.bookstore_ballpens >= 3:
		completed_required += 1
	if GameManager.bookstore_correction_tape:
		completed_required += 1
	if GameManager.bookstore_discrete_math_book:
		completed_required += 1

	progress_bar.max_value = 4.0
	progress_bar.value = float(completed_required)
	progress_text.text = "SHOPPING PROGRESS   %d / 4" % completed_required


func show_friend_bookstore_choice() -> int:

	var choice_ui := COZY_CHOICE_UI.new()
	get_tree().current_scene.add_child(choice_ui)

	return await choice_ui.show_choice(
		"COME WITH THE GROUP?",
		"Kairi and the others are heading outside the school to buy supplies for Discrete Mathematics.",
		"YES — I'LL COME",
		"NO — MAYBE LATER",
		1,
		2,
		Color("#D8A15D")
	)
