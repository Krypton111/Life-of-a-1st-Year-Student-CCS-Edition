extends Node

const PLAYER_PORTRAIT = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const TINA_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Tina/tina.png")
const MARYA_PORTRAIT = preload("res://GAME ASSETS_/Cafe (Sus! Marya & Hosep Cafe)/Character Sprites/32-bit Character Models/Marya (Boss)/Marya.png")
const GELO_PORTRAIT = preload("res://GAME ASSETS_/Cafe (Sus! Marya & Hosep Cafe)/Character Sprites/32-bit Character Models/Gelo (Ex Lover or smth)/gelo.png")
const KAIRI_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kairi/Kairi.png")
const KERWIN_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Kerwin/Kerwin.png")
const JANSSEN_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Janssen/Janssen.png")
const NATHALY_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/32-bit Sprite Models/Friends/Nathaly/Nathaly.png")

@onready var player: CharacterBody2D = $"Player"
@onready var tina: CharacterBody2D = $"Tina"
@onready var gelo: CharacterBody2D = $"Gelo"
@onready var hosep: Node2D = $"Hosep"
@onready var marya: Node2D = $"Marya"
@onready var kairi: CharacterBody2D = $"Kairi"
@onready var kerwin: CharacterBody2D = $"Kerwin"
@onready var janssen: CharacterBody2D = $"Janssen"
@onready var nathaly: CharacterBody2D = $"Nathaly"
@onready var camera: Camera2D = $"Player/Camera2D"

var cinematic_ui: CanvasLayer
var top_bar: ColorRect
var bottom_bar: ColorRect
var entry_running := false

# Cafe ordering flow.
var coffee_order_open := false
var coffee_order_player_choice := ""
var coffee_order_tina_choice := ""
var coffee_order_current_target := "player"
var friends_order_choices: Dictionary = {}
var friends_order_current_target := "player"
var friends_order_open := false
var solo_order_open := false
var solo_order_choice := ""
var solo_gelo_order_choice := ""
var solo_order_current_target := "player"
var solo_order_talked_to_gelo := false
var solo_menu_layer: CanvasLayer = null
var solo_menu_panel: Panel = null
var coffee_menu_layer: CanvasLayer = null
var coffee_menu_panel: Panel = null
var coffee_menu_status: Label = null


func _process(_delta: float) -> void:
	# Once Tina's conversation is finished, the player must approach Marya
	# and interact with her to open the coffee menu.
	if entry_running or coffee_order_open:
		return

	if GameManager.player_controls_locked:
		return

	if DialogueManager.is_active:
		return

	# Solo route: after talking to Gelo and ordering, the player must finish
	# the short post-order conversation before the headache sequence.
	if bool(GameManager.get_meta("cafe_solo_followup_ready", false)):
		if not Input.is_action_just_pressed("interact"):
			return
		if player == null or gelo == null or not gelo.visible:
			return
		if player.global_position.distance_to(gelo.global_position) <= 90.0:
			start_solo_post_order_dialogue()
		return

	# After the friends ordering scene, the player must talk to the group.
	if bool(GameManager.get_meta("cafe_friends_followup_ready", false)):
		if not Input.is_action_just_pressed("interact"):
			return

		if player == null:
			return

		var friends_target := get_closest_visible_friend()
		if friends_target != null and player.global_position.distance_to(friends_target.global_position) <= 90.0:
			start_friends_post_order_dialogue()
		return

	# After the Tina ordering scene, Tina becomes the next interaction target.
	if bool(GameManager.get_meta("cafe_tina_followup_ready", false)):
		if not Input.is_action_just_pressed("interact"):
			return

		if player == null or tina == null or not tina.visible:
			return

		if player.global_position.distance_to(tina.global_position) <= 80.0:
			start_tina_post_order_dialogue()
		return

	if not bool(GameManager.get_meta("cafe_order_ready", false)):
		return

	if not Input.is_action_just_pressed("interact"):
		return

	if player == null or marya == null or not marya.visible:
		return

	if player.global_position.distance_to(marya.global_position) <= 80.0:
		if bool(GameManager.get_meta("cafe_friends_order_ready", false)):
			start_friends_marya_order_dialogue()
		elif bool(GameManager.get_meta("cafe_solo_order_ready", false)):
			start_solo_marya_order_dialogue()
		else:
			start_marya_order_dialogue()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# The hallway controller sets cafe_route immediately before changing
	# scenes. Do not depend on tina_hallway_encounter_done because the
	# scene transition can happen before the hallway encounter function gets
	# a chance to set that flag after its awaited call returns.
	var route := GameManager.cafe_route
	if route != "tina" and route != "friends" and route != "solo":
		return

	GameManager.set_meta("cafe_quest_route", route)
	GameManager.set_meta("cafe_quest_phase", "enter_cafe")

	GameManager.player_controls_locked = true
	entry_running = true

	# Wait one frame so every instantiated character in game.tscn is fully
	# ready before applying route-specific visibility and positions.
	await get_tree().process_frame

	if route == "tina":
		setup_cafe_cast_for_tina()
	elif route == "friends":
		setup_cafe_cast_for_friends()
	elif route == "solo":
		setup_cafe_cast_for_solo()

	# Consume the one-time route flag after reading it. This prevents a later
	# return to game.tscn from incorrectly reusing an older hallway choice.
	GameManager.cafe_route = ""

	if route == "friends":
		setup_cinematic_ui()
		set_cursor_hidden()
		await play_friends_cafe_entry()
		entry_running = false
		return

	if route == "solo":
		# Reset solo-route state every time the solo cafe scene is entered.
		# This prevents an earlier playthrough from skipping the Gelo decision
		# or reusing an old coffee-order state.
		GameManager.set_meta("cafe_solo_order_ready", false)
		GameManager.set_meta("cafe_solo_followup_ready", false)
		GameManager.set_meta("cafe_solo_order_talked_to_gelo", false)
		GameManager.set_meta("cafe_solo_order_complete", false)
		GameManager.set_meta("cafe_order_ready", false)
		GameManager.set_meta("cafe_order_phase", "enter_cafe")
		setup_cinematic_ui()
		set_cursor_hidden()
		await play_solo_cafe_entry()
		entry_running = false
		return

	setup_cinematic_ui()
	set_cursor_hidden()
	await play_cafe_entry()
	entry_running = false
	# play_cafe_entry() restores player control after the full dialogue sequence.


func setup_cafe_cast_for_tina() -> void:
	# Tina route: Tina remains, while Gelo and all friends are removed
	# from the playable cafe scene.
	tina.visible = true
	gelo.visible = false
	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	# Hidden NPCs must not remain solid or interactable.
	set_character_collisions(tina, true)
	set_character_collisions(gelo, false)
	set_character_collisions(kairi, false)
	set_character_collisions(kerwin, false)
	set_character_collisions(janssen, false)
	set_character_collisions(nathaly, false)
	set_character_collisions(hosep, true)
	set_character_collisions(marya, true)


func setup_cafe_cast_for_friends() -> void:
	# Friends route: Tina and Gelo are absent; the four friends are present.
	tina.visible = false
	gelo.visible = false

	var center := player.global_position
	kairi.global_position = center + Vector2(110.0, 35.0)
	kerwin.global_position = center + Vector2(155.0, -5.0)
	janssen.global_position = center + Vector2(200.0, 35.0)
	nathaly.global_position = center + Vector2(245.0, -5.0)

	kairi.visible = true
	kerwin.visible = true
	janssen.visible = true
	nathaly.visible = true

	set_character_collisions(tina, false)
	set_character_collisions(gelo, false)
	set_character_collisions(kairi, true)
	set_character_collisions(kerwin, true)
	set_character_collisions(janssen, true)
	set_character_collisions(nathaly, true)
	set_character_collisions(hosep, true)
	set_character_collisions(marya, true)


func setup_cafe_cast_for_solo() -> void:
	# Solo route: Gelo is present. Tina and the four friends are absent.
	tina.visible = false
	gelo.visible = true
	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false

	set_character_collisions(tina, false)
	set_character_collisions(gelo, true)
	set_character_collisions(kairi, false)
	set_character_collisions(kerwin, false)
	set_character_collisions(janssen, false)
	set_character_collisions(nathaly, false)
	set_character_collisions(hosep, true)
	set_character_collisions(marya, true)


func set_character_collisions(character: Node, enabled: bool) -> void:
	if character == null:
		return

	for child in character.find_children("*", "CollisionShape2D", true, false):
		(child as CollisionShape2D).set_deferred("disabled", not enabled)

	for child in character.find_children("*", "CollisionPolygon2D", true, false):
		(child as CollisionPolygon2D).set_deferred("disabled", not enabled)

	for child in character.find_children("*", "Area2D", true, false):
		var area := child as Area2D
		area.set_deferred("monitoring", enabled)
		area.set_deferred("monitorable", enabled)


func setup_cinematic_ui() -> void:
	# DialogueUI.tscn is a Control. Its parent UI node is the actual CanvasLayer.
	# Put the dialogue layer above the cinematic black bars.
	var dialogue_layer := get_node_or_null("UI") as CanvasLayer
	if dialogue_layer != null:
		dialogue_layer.layer = 4000

	cinematic_ui = CanvasLayer.new()
	cinematic_ui.name = "CinematicUI"
	cinematic_ui.layer = 3000
	get_tree().root.add_child(cinematic_ui)

	top_bar = ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.color = Color.BLACK
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(0, 115)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_ui.add_child(top_bar)

	bottom_bar = ColorRect.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.color = Color.BLACK
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.position = Vector2(0, -115)
	bottom_bar.size = Vector2(0, 115)
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_ui.add_child(bottom_bar)

	top_bar.modulate.a = 0.0
	bottom_bar.modulate.a = 0.0


func play_cafe_entry() -> void:
	# The two arrive together from the left side of the cafe entrance.
	# The target is intentionally modest so the camera frames both characters
	# without becoming excessively zoomed in.
	var target_player := player.global_position + Vector2(150.0, 70.0)
	var target_tina := target_player + Vector2(-54.0, 0.0)

	player.set_physics_process(false)
	tina.set_physics_process(false)

	play_character_animation(player, "walk_right")
	play_character_animation(tina, "walk_right")

	camera.zoom = Vector2(1.22, 1.22)
	await show_cinematic_bars()

	var duration := 2.4
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", target_player, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(tina, "global_position", target_tina, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	stop_character_animation(player, "idle_right")
	stop_character_animation(tina, "idle_right")

	await get_tree().create_timer(0.35).timeout

	var entry_dialogue := [
		{"speaker": "Tina", "text": "Okay... this is the place. Sus! Marya & Hosep Cafe."},
		{"speaker": "Player", "text": "I've actually never been here before."},
		{"speaker": "Tina", "text": "Really? I thought you would have discovered every cafe around campus by now."},
		{"speaker": "Player", "text": "I barely have enough time to figure out where my classrooms are."},
		{"speaker": "Tina", "text": "Fair point."},
		{"speaker": "Player", "text": "It's kind of nice, though. It's quieter than I expected."},
		{"speaker": "Tina", "text": "That's why I like it. Sometimes I just want somewhere I can sit down without thinking about deadlines for a while."},
		{"speaker": "Player", "text": "I get that. Lately it feels like everything is moving at once."},
		{"speaker": "Tina", "text": "Classes, assignments, people, expectations... yeah."},
		{"speaker": "Player", "text": "And seeing you again today made me think about a lot of things I haven't really dealt with."},
		{"speaker": "Tina", "text": "I know. But I'm glad you called me."},
		{"speaker": "Player", "text": "I'm glad I did too."},
		{"speaker": "Tina", "text": "Then let's not make today too heavy. We already talked about the past."},
		{"speaker": "Player", "text": "Agreed. Today can just be two old classmates catching up."},
		{"speaker": "Tina", "text": "Two old classmates who desperately need coffee."},
		{"speaker": "Player", "text": "Now that sounds like a plan."}
	]

	DialogueManager.start_multi_dialogue(
		entry_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	# Tina has explained what both of them want. The actual ordering is now
	# handled by Marya so the player has to walk over and place the order.
	var order_setup_dialogue := [
		{"speaker": "Tina", "text": "Alright, enough reminiscing. I think we're ready to order."},
		{"speaker": "Player", "text": "I'll keep it simple. Just a latte."},
		{"speaker": "Tina", "text": "A latte? That's it?"},
		{"speaker": "Player", "text": "Yep. Simple, warm, and I know what I'm getting."},
		{"speaker": "Tina", "text": "For me, I already know exactly what I want."},
		{"speaker": "Tina", "text": "A grande iced caramel macchiato, oat milk, extra vanilla, two pumps of caramel, one pump of hazelnut, extra caramel drizzle, cold foam, cinnamon powder, light ice, and an extra espresso shot."},
		{"speaker": "Player", "text": "...That's a lot of coffee."},
		{"speaker": "Tina", "text": "It's called having standards."},
		{"speaker": "Player", "text": "I'll go tell Marya."},
		{"speaker": "Tina", "text": "Go ahead. I'll wait here."}
	]

	DialogueManager.start_multi_dialogue(
		order_setup_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	await hide_cinematic_bars()
	camera.zoom = Vector2.ONE

	# Enable the Marya ordering phase.
	GameManager.set_meta("cafe_order_ready", true)
	GameManager.set_meta("cafe_order_phase", "talk_to_marya")
	GameManager.set_meta("cafe_quest_phase", "order_drinks")

	player.set_physics_process(true)
	GameManager.player_controls_locked = false
	entry_running = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



func play_solo_cafe_entry() -> void:
	# Solo entrance intentionally mirrors the Tina route's player movement:
	# same travel distance, timing, camera zoom, and cinematic bars.
	var target_player := player.global_position + Vector2(150.0, 70.0)

	player.set_physics_process(false)
	play_character_animation(player, "walk_right")

	camera.zoom = Vector2(1.22, 1.22)
	await show_cinematic_bars()

	var duration := 2.4
	var tween := create_tween()
	tween.tween_property(player, "global_position", target_player, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	stop_character_animation(player, "idle_right")
	await get_tree().create_timer(0.35).timeout

	var monologue := [
		{"speaker": "Player", "text": "...Wait."},
		{"speaker": "Player", "text": "Is that Gelo?"},
		{"speaker": "Player", "text": "Gelo... my ex-lover."},
		{"speaker": "Player", "text": "I really didn't expect to see him here."},
		{"speaker": "Player", "text": "Do I really want to talk to him?"}
	]

	DialogueManager.start_multi_dialogue(monologue, {}, PLAYER_PORTRAIT)
	await DialogueManager.dialogue_finished

	await hide_cinematic_bars()
	camera.zoom = Vector2.ONE
	await show_solo_gelo_decision()


func show_solo_gelo_decision() -> void:
	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_quest_phase", "decide_about_gelo")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var layer := CanvasLayer.new()
	layer.name = "GeloDecisionMenu"
	layer.layer = 5000
	get_tree().root.add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.025, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-430, -190)
	panel.size = Vector2(860, 380)
	layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F6E7D2")
	style.border_color = Color("#B9824A")
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "A FAMILIAR FACE"
	title.position = Vector2(40, 35)
	title.size = Vector2(780, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#3A281E"))
	panel.add_child(title)

	var prompt := Label.new()
	prompt.text = "Do you want to talk to Gelo?"
	prompt.position = Vector2(40, 92)
	prompt.size = Vector2(780, 50)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color("#5B3B28"))
	panel.add_child(prompt)

	var talk := Button.new()
	talk.text = "TALK TO GELO"
	talk.position = Vector2(90, 205)
	talk.size = Vector2(310, 70)
	talk.add_theme_font_size_override("font_size", 16)
	talk.pressed.connect(func():
		layer.queue_free()
		start_solo_gelo_conversation()
	)
	panel.add_child(talk)

	var avoid := Button.new()
	avoid.text = "DON'T TALK"
	avoid.position = Vector2(460, 205)
	avoid.size = Vector2(310, 70)
	avoid.add_theme_font_size_override("font_size", 16)
	avoid.pressed.connect(func():
		layer.queue_free()
		start_solo_direct_order()
	)
	panel.add_child(avoid)


func start_solo_gelo_conversation() -> void:
	GameManager.set_meta("cafe_quest_phase", "talk_to_gelo")
	GameManager.player_controls_locked = true

	# Gelo stays exactly where he is. Only the player moves.
	player.set_physics_process(false)
	gelo.set_physics_process(false)
	gelo.velocity = Vector2.ZERO

	var player_start: Vector2 = player.global_position
	var gelo_position: Vector2 = gelo.global_position
	const TALK_DISTANCE: float = 72.0

	# NavigationAgent2D calculates the route; it does not have a global_position.
	var navigation_agent := NavigationAgent2D.new()
	navigation_agent.name = "SoloGeloApproachAgent"
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 8.0
	navigation_agent.radius = 10.0
	navigation_agent.avoidance_enabled = false
	player.add_child(navigation_agent)
	navigation_agent.target_position = gelo_position

	# Give the navigation map one physics frame to synchronize.
	await get_tree().physics_frame

	var speed: float = 75.0
	var reached_target := false
	var safety_time: float = maxf(player_start.distance_to(gelo_position) / speed * 3.0, 4.0)
	var elapsed: float = 0.0

	while not reached_target and elapsed < safety_time:
		await get_tree().physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second

		if not is_instance_valid(navigation_agent):
			break

		# Start the dialogue as soon as the player is within 15px of Gelo,
		# regardless of whether they approach from the left, right, above, or below.
		var distance_to_gelo: float = player.global_position.distance_to(gelo.global_position)
		if distance_to_gelo <= TALK_DISTANCE:
			reached_target = true
			break

		var next_position: Vector2 = navigation_agent.get_next_path_position()
		var direction: Vector2 = player.global_position.direction_to(next_position)

		if direction.length_squared() <= 0.001:
			continue

		play_character_animation(player, get_walk_animation_name(direction))
		player.velocity = direction * speed
		player.move_and_slide()

	# Stop at the interaction radius. The player does not need to overlap Gelo;
	# character collision shapes and sprite sizes can make a visual "beside"
	# position considerably farther than a few pixels apart.
	player.velocity = Vector2.ZERO
	if is_instance_valid(navigation_agent):
		navigation_agent.queue_free()

	# If the navigation agent stopped slightly outside the radius because of
	# collision geometry, still allow the conversation when the player is
	# visually close to Gelo. Never require the player to overlap him.
	var final_distance: float = player.global_position.distance_to(gelo.global_position)
	if final_distance > TALK_DISTANCE:
		var close_direction: Vector2 = player.global_position.direction_to(gelo.global_position)
		if close_direction.length_squared() > 0.001:
			play_character_animation(player, get_walk_animation_name(close_direction))
			player.velocity = close_direction * speed
			player.move_and_slide()
			player.velocity = Vector2.ZERO

	# The conversation is intentionally triggered even if collision geometry
	# prevents the player body from getting closer than the interaction radius.

	# Keep Gelo completely stationary while they talk.
	gelo.velocity = Vector2.ZERO
	gelo.set_physics_process(false)
	stop_character_animation(gelo, get_idle_animation_name(player.global_position.direction_to(gelo.global_position)))
	stop_character_animation(player, get_idle_animation_name(player.global_position.direction_to(gelo.global_position)))
	face_character_toward_character(player, gelo)
	face_character_toward_character(gelo, player)

	var dialogue := [
		{"speaker": "Player", "text": "Gelo... hey."},
		{"speaker": "Gelo", "text": "Hey. I didn't expect to see you here."},
		{"speaker": "Player", "text": "Yeah. I wasn't expecting to see you either."},
		{"speaker": "Gelo", "text": "How have you been?"},
		{"speaker": "Player", "text": "I've been okay. First year has been keeping me busy."},
		{"speaker": "Gelo", "text": "I can imagine. You always had a lot going on."},
		{"speaker": "Player", "text": "Things are different now, but I'm getting used to it."},
		{"speaker": "Gelo", "text": "That's good. I'm glad you're doing alright."},
		{"speaker": "Player", "text": "Thanks. What are you doing here?"},
		{"speaker": "Gelo", "text": "Just grabbing something to drink. I come here sometimes when I want a quiet place."},
		{"speaker": "Player", "text": "I was about to order something too."},
		{"speaker": "Gelo", "text": "Then... do you want to get a drink together?"},
		{"speaker": "Player", "text": "Sure. We can do that."},
		{"speaker": "Gelo", "text": "Alright. Let's go order."}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Gelo": GELO_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	# Gelo remains completely stationary after the conversation.
	gelo.velocity = Vector2.ZERO
	gelo.set_physics_process(false)
	stop_character_animation(gelo, get_idle_animation_name(player.global_position.direction_to(gelo.global_position)))

	player.set_physics_process(true)
	GameManager.player_controls_locked = false
	GameManager.set_meta("cafe_solo_order_ready", true)
	GameManager.set_meta("cafe_order_ready", true)
	GameManager.set_meta("cafe_solo_order_talked_to_gelo", true)
	GameManager.set_meta("cafe_quest_phase", "order_drinks")


func start_solo_direct_order() -> void:
	# The entrance cinematic disabled player physics. Re-enable it before
	# sending the player to Marya for the one-person coffee order.
	player.set_physics_process(true)
	GameManager.set_meta("cafe_solo_order_talked_to_gelo", false)
	GameManager.set_meta("cafe_solo_order_ready", true)
	GameManager.set_meta("cafe_order_ready", true)
	GameManager.set_meta("cafe_order_phase", "solo_talk_to_marya")
	GameManager.set_meta("cafe_quest_phase", "order_drinks")
	GameManager.player_controls_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func play_friends_cafe_entry() -> void:
	# The player and the four friends enter the cafe together from the left.
	var start_center := player.global_position
	var target_player := start_center + Vector2(145.0, 70.0)
	var target_kairi := target_player + Vector2(-135.0, 0.0)
	var target_kerwin := target_player + Vector2(-75.0, 0.0)
	var target_janssen := target_player + Vector2(60.0, 0.0)
	var target_nathaly := target_player + Vector2(125.0, 0.0)

	player.set_physics_process(false)
	for friend in [kairi, kerwin, janssen, nathaly]:
		friend.set_physics_process(false)
		play_character_animation(friend, "walk_right")
	play_character_animation(player, "walk_right")

	camera.zoom = Vector2(1.08, 1.08)
	await show_cinematic_bars()

	var duration := 2.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", target_player, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(kairi, "global_position", target_kairi, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(kerwin, "global_position", target_kerwin, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(janssen, "global_position", target_janssen, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(nathaly, "global_position", target_nathaly, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	for friend in [player, kairi, kerwin, janssen, nathaly]:
		stop_character_animation(friend, "idle_right")

	await get_tree().create_timer(0.35).timeout

	var entry_dialogue := [
		{"speaker": "Kerwin", "text": "Okay, everyone made it. Sus! Marya & Hosep Cafe."},
		{"speaker": "Kairi", "text": "I've been meaning to try this place for a while."},
		{"speaker": "Janssen", "text": "Same. After that challenge, I definitely need something to drink."},
		{"speaker": "Nathaly", "text": "At least we can relax for a bit before going back to our work."},
		{"speaker": "Player", "text": "Yeah. It's nice having everyone here without having to worry about the next class."},
		{"speaker": "Kerwin", "text": "That's exactly what I was thinking. No quizzes, no deadlines, just coffee."},
		{"speaker": "Kairi", "text": "And we can finally talk about something other than school for five minutes."},
		{"speaker": "Janssen", "text": "Five minutes? You know us better than that."},
		{"speaker": "Nathaly", "text": "We'll probably end up talking about school anyway."},
		{"speaker": "Player", "text": "Probably. But at least we'll have coffee while we do it."},
		{"speaker": "Kerwin", "text": "Now that's a plan."}
	]

	DialogueManager.start_multi_dialogue(
		entry_dialogue,
		{"Kairi": KAIRI_PORTRAIT, "Kerwin": KERWIN_PORTRAIT, "Janssen": JANSSEN_PORTRAIT, "Nathaly": NATHALY_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	var order_setup_dialogue := [
		{"speaker": "Kerwin", "text": "Alright, let's order before we start another three-hour conversation."},
		{"speaker": "Player", "text": "I'll keep mine simple. Just a latte."},
		{"speaker": "Kairi", "text": "I'll go with a matcha latte."},
		{"speaker": "Kerwin", "text": "Cold brew for me."},
		{"speaker": "Janssen", "text": "I'll take a cappuccino."},
		{"speaker": "Nathaly", "text": "Strawberry cream frappé for me."},
		{"speaker": "Player", "text": "Okay. Five drinks. I think I can remember that."},
		{"speaker": "Kerwin", "text": "Famous last words."},
		{"speaker": "Player", "text": "I'll tell Marya."}
	]

	DialogueManager.start_multi_dialogue(
		order_setup_dialogue,
		{"Kairi": KAIRI_PORTRAIT, "Kerwin": KERWIN_PORTRAIT, "Janssen": JANSSEN_PORTRAIT, "Nathaly": NATHALY_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	await hide_cinematic_bars()
	camera.zoom = Vector2.ONE

	GameManager.set_meta("cafe_order_ready", true)
	GameManager.set_meta("cafe_order_phase", "talk_to_marya_friends")
	GameManager.set_meta("cafe_friends_order_ready", true)
	GameManager.set_meta("cafe_quest_phase", "order_drinks")
	GameManager.player_controls_locked = false
	player.set_physics_process(true)
	entry_running = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func get_closest_visible_friend() -> CharacterBody2D:
	var closest: CharacterBody2D = null
	var closest_distance := INF
	for friend in [kairi, kerwin, janssen, nathaly]:
		if friend != null and friend.visible:
			var distance := player.global_position.distance_to(friend.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = friend
	return closest


func start_marya_order_dialogue() -> void:
	if coffee_order_open or DialogueManager.is_active:
		return

	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_order_phase", "marya_dialogue")
	GameManager.set_meta("cafe_quest_phase", "order_drinks")

	var marya_dialogue := [
		{"speaker": "Marya", "text": "Hi! Welcome to Sus! Marya & Hosep Cafe. What can I get for you two?"},
		{"speaker": "Player", "text": "We're ready to order. Tina already told me what she wants."},
		{"speaker": "Marya", "text": "Perfect. Take a look at the menu and choose both drinks."}
	]

	DialogueManager.start_multi_dialogue(
		marya_dialogue,
		{"Marya": MARYA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	open_coffee_menu()


func start_solo_marya_order_dialogue() -> void:
	if solo_order_open or coffee_order_open or friends_order_open or DialogueManager.is_active:
		return

	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_order_phase", "solo_marya_dialogue")
	GameManager.set_meta("cafe_quest_phase", "order_drinks")

	var dialogue: Array[Dictionary]
	if bool(GameManager.get_meta("cafe_solo_order_talked_to_gelo", false)):
		dialogue = [
			{"speaker": "Marya", "text": "Hi! What can I get for you two?"},
			{"speaker": "Player", "text": "We'll have two drinks. I'll place the order."},
			{"speaker": "Marya", "text": "Perfect. Choose both drinks when you're ready."}
		]
	else:
		dialogue = [
			{"speaker": "Marya", "text": "Hi! Welcome to Sus! Marya & Hosep Cafe. What can I get for you?"},
			{"speaker": "Player", "text": "Just one drink for me, please."},
			{"speaker": "Marya", "text": "Of course. Take a look at the menu."}
		]

	DialogueManager.start_multi_dialogue(dialogue, {"Marya": MARYA_PORTRAIT}, PLAYER_PORTRAIT)
	await DialogueManager.dialogue_finished

	if bool(GameManager.get_meta("cafe_solo_order_talked_to_gelo", false)):
		open_solo_two_person_coffee_menu()
	else:
		open_solo_one_person_coffee_menu()


func open_solo_one_person_coffee_menu() -> void:
	solo_order_open = true
	solo_order_choice = ""
	GameManager.player_controls_locked = true
	build_solo_coffee_menu(false)


func open_solo_two_person_coffee_menu() -> void:
	solo_order_open = true
	solo_order_choice = ""
	GameManager.player_controls_locked = true
	build_solo_coffee_menu(true)


func build_solo_coffee_menu(two_people: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	solo_menu_layer = CanvasLayer.new()
	solo_menu_layer.name = "SoloCoffeeMenu"
	solo_menu_layer.layer = 5000
	get_tree().root.add_child(solo_menu_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	solo_menu_layer.add_child(dim)

	solo_menu_panel = Panel.new()
	solo_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	solo_menu_panel.position = Vector2(-570, -390)
	solo_menu_panel.size = Vector2(1140, 780)
	solo_menu_layer.add_child(solo_menu_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F6E7D2")
	style.border_color = Color("#B9824A")
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 20
	solo_menu_panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "MARYA & HOSEP CAFE"
	title.position = Vector2(45, 28)
	title.size = Vector2(1050, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#3A281E"))
	solo_menu_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "COFFEE MENU"
	subtitle.position = Vector2(45, 70)
	subtitle.size = Vector2(1050, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#806956"))
	solo_menu_panel.add_child(subtitle)

	var target := Label.new()
	target.name = "SoloOrderTargetLabel"
	target.text = "CHOOSE YOUR DRINK" if not two_people else "ORDERING FOR: PLAYER"
	target.position = Vector2(45, 105)
	target.size = Vector2(1050, 28)
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_theme_font_size_override("font_size", 16)
	target.add_theme_color_override("font_color", Color("#5B3B28"))
	solo_menu_panel.add_child(target)

	if two_people:
		var player_target := Button.new()
		player_target.text = "PLAYER'S COFFEE"
		player_target.position = Vector2(330, 135)
		player_target.size = Vector2(220, 38)
		player_target.pressed.connect(_set_solo_order_target.bind("player"))
		solo_menu_panel.add_child(player_target)

		var gelo_target := Button.new()
		gelo_target.text = "GELO'S COFFEE"
		gelo_target.position = Vector2(590, 135)
		gelo_target.size = Vector2(220, 38)
		gelo_target.pressed.connect(_set_solo_order_target.bind("gelo"))
		solo_menu_panel.add_child(gelo_target)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(45, 185) if two_people else Vector2(45, 150)
	grid.size = Vector2(1050, 520)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 8)
	solo_menu_panel.add_child(grid)

	var drinks := ["Latte", "Cappuccino", "Americano", "Espresso", "Caffe Mocha", "Vanilla Latte", "Caramel Latte", "Hazelnut Latte", "Flat White", "Cold Brew", "Iced Americano", "Matcha Latte", "Hot Chocolate", "Chai Latte", "Iced Vanilla Latte", "Strawberry Cream Frappé", "Iced Caramel Macchiato", "Mocha Frappuccino", "Cinnamon Dolce Latte", "White Chocolate Mocha"]
	for drink in drinks:
		var button := Button.new()
		button.text = drink
		button.custom_minimum_size = Vector2(516, 45)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("#3A281E"))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_solo_coffee_selected.bind(drink, two_people))
		grid.add_child(button)


func _set_solo_order_target(target: String) -> void:
	if not solo_order_open:
		return
	if target == "player" and not solo_order_choice.is_empty():
		return
	if target == "gelo" and not solo_gelo_order_choice.is_empty():
		return
	solo_order_current_target = target
	var label := solo_menu_panel.get_node_or_null("SoloOrderTargetLabel") as Label
	if label != null:
		label.text = "ORDERING FOR: " + target.to_upper()


func _on_solo_coffee_selected(drink: String, two_people: bool) -> void:
	if not solo_order_open:
		return

	if not two_people:
		solo_order_choice = drink
		await finish_solo_coffee_order(false)
		return

	if solo_order_current_target == "player":
		solo_order_choice = drink
		solo_order_current_target = "gelo" if solo_gelo_order_choice.is_empty() else "player"
	else:
		solo_gelo_order_choice = drink
		solo_order_current_target = "player" if solo_order_choice.is_empty() else "gelo"

	if not solo_order_choice.is_empty() and not solo_gelo_order_choice.is_empty():
		await finish_solo_coffee_order(true)
	else:
		var label := solo_menu_panel.get_node_or_null("SoloOrderTargetLabel") as Label
		if label != null:
			label.text = "ORDERING FOR: " + solo_order_current_target.to_upper()


func finish_solo_coffee_order(two_people: bool) -> void:
	if is_instance_valid(solo_menu_layer):
		solo_menu_layer.queue_free()
	solo_menu_layer = null
	solo_menu_panel = null
	solo_order_open = false

	GameManager.set_meta("cafe_solo_order_complete", true)
	GameManager.set_meta("cafe_solo_order_ready", false)
	GameManager.set_meta("cafe_order_ready", false)
	GameManager.set_meta("cafe_order_phase", "solo_order_complete")
	GameManager.set_meta("cafe_quest_phase", "coffee_ordered")
	GameManager.player_controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var dialogue: Array[Dictionary]
	if two_people:
		dialogue = [
			{"speaker": "Marya", "text": "Alright. One " + solo_order_choice + " for you."},
			{"speaker": "Player", "text": "And one iced caramel macchiato for Gelo."},
			{"speaker": "Marya", "text": "Got it. I'll get those started."},
			{"speaker": "Gelo", "text": "Thanks."}
		]
	else:
		dialogue = [
			{"speaker": "Marya", "text": "Alright. One " + solo_order_choice + "."},
			{"speaker": "Player", "text": "Thank you."},
			{"speaker": "Marya", "text": "You're welcome. I'll get that started."}
		]

	DialogueManager.start_multi_dialogue(dialogue, {"Marya": MARYA_PORTRAIT, "Gelo": GELO_PORTRAIT}, PLAYER_PORTRAIT)
	await DialogueManager.dialogue_finished

	if two_people:
		GameManager.set_meta("cafe_solo_followup_ready", true)
		GameManager.set_meta("cafe_quest_phase", "talk_to_gelo_after_order")
		GameManager.player_controls_locked = false
	else:
		await start_solo_headache_sequence()


func start_solo_post_order_dialogue() -> void:
	if DialogueManager.is_active or not bool(GameManager.get_meta("cafe_solo_followup_ready", false)):
		return

	GameManager.set_meta("cafe_solo_followup_ready", false)
	GameManager.set_meta("cafe_quest_phase", "talk_to_gelo_after_order")
	GameManager.player_controls_locked = true

	var dialogue := [
		{"speaker": "Player", "text": "The drinks should be ready soon."},
		{"speaker": "Gelo", "text": "Thanks for getting mine."},
		{"speaker": "Player", "text": "It's okay. It was nice talking to you, even if it was unexpected."},
		{"speaker": "Gelo", "text": "Yeah. I guess I wasn't expecting this either."},
		{"speaker": "Player", "text": "Maybe that's enough for today."},
		{"speaker": "Gelo", "text": "Yeah. Take care."}
	]
	DialogueManager.start_multi_dialogue(dialogue, {"Gelo": GELO_PORTRAIT}, PLAYER_PORTRAIT)
	await DialogueManager.dialogue_finished
	await start_solo_headache_sequence()


func start_solo_headache_sequence() -> void:
	GameManager.set_meta("cafe_quest_phase", "headache")
	GameManager.player_controls_locked = true
	await get_tree().create_timer(5.0).timeout

	var dialogue := [
		{"speaker": "Player", "text": "Yeah... I think so. It's just..."},
		{"speaker": "Player", "text": "My head is starting to hurt."}
	]
	DialogueManager.start_multi_dialogue(dialogue, {}, PLAYER_PORTRAIT)
	await DialogueManager.dialogue_finished

	await play_tina_alarm()
	GameManager.returning_from_tina_dream = true
	GameManager.set_meta("cafe_quest_phase", "returned_home")
	GameManager.set_meta("cafe_order_phase", "returned_home")
	GameManager.player_controls_locked = true
	await FadeManager.change_scene_with_fade("res://scenes/main_level_scenes/house_game_level.tscn")


func start_friends_marya_order_dialogue() -> void:
	if friends_order_open or coffee_order_open or DialogueManager.is_active:
		return

	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_order_phase", "friends_marya_dialogue")
	GameManager.set_meta("cafe_quest_phase", "order_drinks")

	var dialogue := [
		{"speaker": "Marya", "text": "Welcome, everyone! What can I get for the group?"},
		{"speaker": "Player", "text": "We've all decided what we want. I'll place the order for everyone."},
		{"speaker": "Marya", "text": "Perfect. Take your time and choose each person's drink."}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Marya": MARYA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished
	open_friends_coffee_menu()


func open_friends_coffee_menu() -> void:
	friends_order_open = true
	friends_order_choices.clear()
	friends_order_current_target = "player"
	GameManager.set_meta("cafe_friends_order_result_recorded", false)
	GameManager.set_meta("cafe_friends_wrong_count", 0)
	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_order_phase", "choose_friends_drinks")
	build_friends_coffee_menu()


func build_friends_coffee_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	coffee_menu_layer = CanvasLayer.new()
	coffee_menu_layer.name = "FriendsCoffeeMenu"
	coffee_menu_layer.layer = 5000
	get_tree().root.add_child(coffee_menu_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	coffee_menu_layer.add_child(dim)

	coffee_menu_panel = Panel.new()
	coffee_menu_panel.name = "FriendsCoffeeMenuBook"
	coffee_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	coffee_menu_panel.position = Vector2(-570, -390)
	coffee_menu_panel.size = Vector2(1140, 780)
	coffee_menu_layer.add_child(coffee_menu_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F6E7D2")
	style.border_color = Color("#B9824A")
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 20
	coffee_menu_panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "MARYA & HOSEP CAFE"
	title.position = Vector2(45, 25)
	title.size = Vector2(1050, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#3A281E"))
	coffee_menu_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "GROUP COFFEE ORDER"
	subtitle.position = Vector2(45, 62)
	subtitle.size = Vector2(1050, 25)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#806956"))
	coffee_menu_panel.add_child(subtitle)

	var target_label := Label.new()
	target_label.name = "OrderTargetLabel"
	target_label.text = "ORDERING FOR: PLAYER"
	target_label.position = Vector2(45, 94)
	target_label.size = Vector2(1050, 27)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 16)
	target_label.add_theme_color_override("font_color", Color("#5B3B28"))
	coffee_menu_panel.add_child(target_label)

	var target_names := ["player", "kairi", "kerwin", "janssen", "nathaly"]
	var target_labels := ["PLAYER", "KAIRI", "KERWIN", "JANSSEN", "NATHALY"]
	for i in target_names.size():
		var b := Button.new()
		b.text = target_labels[i]
		b.position = Vector2(45 + (i % 3) * 350, 125 + (i / 3) * 40)
		b.size = Vector2(325, 34)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color("#3A281E"))
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(_set_friends_order_target.bind(target_names[i]))
		coffee_menu_panel.add_child(b)

	var grid := GridContainer.new()
	grid.name = "DrinkGrid"
	grid.columns = 2
	grid.position = Vector2(45, 220)
	grid.size = Vector2(1050, 470)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 7)
	coffee_menu_panel.add_child(grid)

	var drinks := [
		"Latte", "Cappuccino", "Americano", "Espresso", "Caffe Mocha",
		"Vanilla Latte", "Caramel Latte", "Hazelnut Latte", "Flat White", "Cold Brew",
		"Iced Americano", "Matcha Latte", "Hot Chocolate", "Chai Latte", "Iced Vanilla Latte",
		"Strawberry Cream Frappé", "Iced Caramel Macchiato", "Mocha Frappuccino",
		"Cinnamon Dolce Latte", "White Chocolate Mocha"
	]

	for drink in drinks:
		var button := Button.new()
		button.text = drink
		button.custom_minimum_size = Vector2(516, 42)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", Color("#3A281E"))
		button.add_theme_color_override("font_hover_color", Color("#251913"))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_friends_coffee_selected.bind(drink))
		grid.add_child(button)

	var exit_button := Button.new()
	exit_button.text = "EXIT"
	exit_button.position = Vector2(480, 716)
	exit_button.size = Vector2(180, 40)
	exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	exit_button.pressed.connect(close_friends_coffee_menu_and_review)
	coffee_menu_panel.add_child(exit_button)


func _set_friends_order_target(target: String) -> void:
	if not friends_order_open or friends_order_choices.has(target):
		return
	friends_order_current_target = target
	var label := coffee_menu_panel.get_node_or_null("OrderTargetLabel") as Label
	if label != null:
		label.text = "ORDERING FOR: " + target.to_upper()


func _on_friends_coffee_selected(drink: String) -> void:
	if not friends_order_open or friends_order_choices.has(friends_order_current_target):
		return

	friends_order_choices[friends_order_current_target] = drink

	if friends_order_choices.size() >= 5:
		await get_tree().create_timer(0.35).timeout
		finish_friends_coffee_order()
		return

	var next_targets := ["player", "kairi", "kerwin", "janssen", "nathaly"]
	for target in next_targets:
		if not friends_order_choices.has(target):
			friends_order_current_target = target
			var label := coffee_menu_panel.get_node_or_null("OrderTargetLabel") as Label
			if label != null:
				label.text = "ORDERING FOR: " + target.to_upper()
			break


func finish_friends_coffee_order() -> void:
	var correct := {
		"player": "Latte",
		"kairi": "Matcha Latte",
		"kerwin": "Cold Brew",
		"janssen": "Cappuccino",
		"nathaly": "Strawberry Cream Frappé"
	}
	var all_correct := true
	var wrong_count: int = 0
	for key in correct:
		if str(friends_order_choices.get(key, "")) != correct[key]:
			all_correct = false
			wrong_count += 1

	GameManager.set_meta("cafe_friends_wrong_count", wrong_count)
	GameManager.set_meta("cafe_friends_order_result_recorded", true)
	GameManager.set_meta("cafe_order_ready", false)
	GameManager.set_meta("cafe_friends_order_ready", false)
	GameManager.set_meta("cafe_friends_followup_ready", true)
	GameManager.set_meta("cafe_order_complete", true)
	GameManager.set_meta("cafe_order_phase", "friends_order_complete")

	if is_instance_valid(coffee_menu_layer):
		coffee_menu_layer.queue_free()
	coffee_menu_layer = null
	coffee_menu_panel = null
	friends_order_open = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.player_controls_locked = true

	var dialogue: Array[Dictionary]
	if all_correct:
		dialogue = [
			{"speaker": "Marya", "text": "Alright! One latte, one matcha latte, one cold brew, one cappuccino, and one strawberry cream frappé."},
			{"speaker": "Player", "text": "That's everything. Hopefully I remembered everyone's order."},
			{"speaker": "Kerwin", "text": "You actually did."},
			{"speaker": "Kairi", "text": "Nice. Now we can relax."},
			{"speaker": "Marya", "text": "Perfect. I'll get those started."}
		]
	else:
		dialogue = [
			{"speaker": "Player", "text": "Okay... I think I mixed up some of the drinks."},
			{"speaker": "Kerwin", "text": "You had one job."},
			{"speaker": "Janssen", "text": "It's fine. We'll survive."},
			{"speaker": "Marya", "text": "I'll sort out the order from here."}
		]

	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Marya": MARYA_PORTRAIT, "Kairi": KAIRI_PORTRAIT, "Kerwin": KERWIN_PORTRAIT, "Janssen": JANSSEN_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished
	GameManager.player_controls_locked = false


func close_friends_coffee_menu_and_review() -> void:
	if not friends_order_open:
		return
	if is_instance_valid(coffee_menu_layer):
		coffee_menu_layer.queue_free()
	coffee_menu_layer = null
	coffee_menu_panel = null
	friends_order_open = false
	friends_order_choices.clear()
	friends_order_current_target = "player"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.set_meta("cafe_order_phase", "friends_ask_again")
	GameManager.set_meta("cafe_friends_order_ready", true)
	GameManager.player_controls_locked = true

	var dialogue := [
		{"speaker": "Player", "text": "Wait, let me make sure I got everyone's order right."},
		{"speaker": "Kairi", "text": "Mine is a matcha latte."},
		{"speaker": "Kerwin", "text": "Cold brew."},
		{"speaker": "Janssen", "text": "Cappuccino."},
		{"speaker": "Nathaly", "text": "Strawberry cream frappé."},
		{"speaker": "Player", "text": "Right. Got it. I'll ask Marya again."}
	]
	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Kairi": KAIRI_PORTRAIT, "Kerwin": KERWIN_PORTRAIT, "Janssen": JANSSEN_PORTRAIT, "Nathaly": NATHALY_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished
	GameManager.player_controls_locked = false


func open_coffee_menu() -> void:
	if coffee_order_open:
		return

	coffee_order_open = true
	coffee_order_player_choice = ""
	coffee_order_tina_choice = ""
	coffee_order_current_target = "player"
	GameManager.set_meta("cafe_tina_order_result_recorded", false)
	GameManager.set_meta("cafe_tina_player_correct", false)
	GameManager.set_meta("cafe_tina_correct", false)
	GameManager.player_controls_locked = true
	GameManager.set_meta("cafe_order_phase", "choose_drinks")

	build_coffee_menu()


func build_coffee_menu() -> void:
	# Keep the normal mouse cursor available while the drink menu is open.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	coffee_menu_layer = CanvasLayer.new()
	coffee_menu_layer.name = "CoffeeMenu"
	coffee_menu_layer.layer = 5000
	get_tree().root.add_child(coffee_menu_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	coffee_menu_layer.add_child(dim)

	coffee_menu_panel = Panel.new()
	coffee_menu_panel.name = "CoffeeMenuBook"
	coffee_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	coffee_menu_panel.position = Vector2(-570, -390)
	coffee_menu_panel.size = Vector2(1140, 780)
	coffee_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	coffee_menu_layer.add_child(coffee_menu_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F6E7D2")
	style.border_color = Color("#B9824A")
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 20
	coffee_menu_panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "MARYA & HOSEP CAFE"
	title.position = Vector2(45, 28)
	title.size = Vector2(1050, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#3A281E"))
	coffee_menu_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "COFFEE MENU"
	subtitle.position = Vector2(45, 70)
	subtitle.size = Vector2(1050, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#806956"))
	coffee_menu_panel.add_child(subtitle)

	# The player can decide whose drink to enter first. After a drink is
	# chosen, the target automatically switches to the other person.
	var target_label := Label.new()
	target_label.name = "OrderTargetLabel"
	target_label.text = "ORDERING FOR: PLAYER"
	target_label.position = Vector2(45, 103)
	target_label.size = Vector2(1050, 28)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 16)
	target_label.add_theme_color_override("font_color", Color("#5B3B28"))
	coffee_menu_panel.add_child(target_label)

	var player_first := Button.new()
	player_first.name = "PlayerFirstButton"
	player_first.text = "PLAYER'S COFFEE"
	player_first.position = Vector2(330, 135)
	player_first.size = Vector2(220, 38)
	player_first.add_theme_font_size_override("font_size", 13)
	player_first.add_theme_color_override("font_color", Color("#3A281E"))
	player_first.pressed.connect(_set_coffee_order_target.bind("player"))
	coffee_menu_panel.add_child(player_first)

	var tina_first := Button.new()
	tina_first.name = "TinaFirstButton"
	tina_first.text = "TINA'S COFFEE"
	tina_first.position = Vector2(590, 135)
	tina_first.size = Vector2(220, 38)
	tina_first.add_theme_font_size_override("font_size", 13)
	tina_first.add_theme_color_override("font_color", Color("#3A281E"))
	tina_first.pressed.connect(_set_coffee_order_target.bind("tina"))
	coffee_menu_panel.add_child(tina_first)

	var grid := GridContainer.new()
	grid.name = "DrinkGrid"
	grid.columns = 2
	grid.position = Vector2(45, 185)
	grid.size = Vector2(1050, 515)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 8)
	coffee_menu_panel.add_child(grid)

	var drinks := [
		"Latte",
		"Cappuccino",
		"Americano",
		"Espresso",
		"Caffe Mocha",
		"Vanilla Latte",
		"Caramel Latte",
		"Hazelnut Latte",
		"Flat White",
		"Cold Brew",
		"Iced Americano",
		"Matcha Latte",
		"Hot Chocolate",
		"Chai Latte",
		"Iced Vanilla Latte",
		"Strawberry Cream Frappé",
		"Iced Caramel Macchiato",
		"Mocha Frappuccino",
		"Cinnamon Dolce Latte",
        "White Chocolate Mocha"
	]

	for drink in drinks:
		var button := Button.new()
		button.text = drink
		button.custom_minimum_size = Vector2(516, 45)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("#3A281E"))
		button.add_theme_color_override("font_hover_color", Color("#251913"))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_coffee_selected.bind(drink))
		grid.add_child(button)

	var exit_button := Button.new()
	exit_button.text = "EXIT"
	exit_button.position = Vector2(480, 720)
	exit_button.size = Vector2(180, 42)
	exit_button.add_theme_font_size_override("font_size", 15)
	exit_button.add_theme_color_override("font_color", Color("#3A281E"))
	exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	exit_button.pressed.connect(close_coffee_menu_and_ask_tina)
	coffee_menu_panel.add_child(exit_button)


func _set_coffee_order_target(target: String) -> void:
	if not coffee_order_open:
		return

	# Do not allow changing the target after that person's drink has already
	# been chosen. This keeps the order to exactly one choice per person.
	if target == "player" and not coffee_order_player_choice.is_empty():
		return
	if target == "tina" and not coffee_order_tina_choice.is_empty():
		return

	coffee_order_current_target = target
	update_coffee_order_target_label()


func update_coffee_order_target_label() -> void:
	if not is_instance_valid(coffee_menu_panel):
		return

	var label := coffee_menu_panel.get_node_or_null("OrderTargetLabel") as Label
	if label == null:
		return

	if coffee_order_current_target == "tina":
		label.text = "ORDERING FOR: TINA"
	else:
		label.text = "ORDERING FOR: PLAYER"


func _on_coffee_selected(drink: String) -> void:
	if not coffee_order_open:
		return

	# The order can be entered in either order, but each person gets exactly
	# one drink selection.
	if coffee_order_current_target == "player":
		if not coffee_order_player_choice.is_empty():
			return
		coffee_order_player_choice = drink

		if coffee_order_tina_choice.is_empty():
			coffee_order_current_target = "tina"
			update_coffee_order_target_label()
		else:
			await get_tree().create_timer(0.35).timeout
			finish_coffee_order()
		return

	if not coffee_order_tina_choice.is_empty():
		return

	coffee_order_tina_choice = drink

	if coffee_order_player_choice.is_empty():
		coffee_order_current_target = "player"
		update_coffee_order_target_label()
	else:
		await get_tree().create_timer(0.35).timeout
		finish_coffee_order()


func finish_coffee_order() -> void:
	var player_correct := coffee_order_player_choice == "Latte"
	var tina_correct := coffee_order_tina_choice == "Iced Caramel Macchiato"
	GameManager.set_meta("cafe_tina_player_correct", player_correct)
	GameManager.set_meta("cafe_tina_correct", tina_correct)
	GameManager.set_meta("cafe_tina_order_result_recorded", true)

	# The player gets exactly one attempt. Any wrong choice ends the order
	# immediately and produces the matching dialogue with Tina.
	if not player_correct or not tina_correct:
		await finish_wrong_coffee_order(player_correct, tina_correct)
		return

	GameManager.set_meta("cafe_order_complete", true)
	GameManager.set_meta("cafe_order_ready", false)
	GameManager.set_meta("cafe_order_phase", "complete")
	GameManager.set_meta("cafe_quest_phase", "coffee_ordered")
	GameManager.set_meta("cafe_tina_followup_ready", true)

	if is_instance_valid(coffee_menu_layer):
		coffee_menu_layer.queue_free()

	coffee_menu_layer = null
	coffee_menu_panel = null
	coffee_menu_status = null
	coffee_order_open = false

	GameManager.player_controls_locked = true

	var final_dialogue := [
		{"speaker": "Marya", "text": "Alright! One simple latte and one very, very specific iced caramel macchiato."},
		{"speaker": "Player", "text": "That's exactly what we wanted."},
		{"speaker": "Tina", "text": "See? I knew you could handle the order."},
		{"speaker": "Marya", "text": "Perfect. I'll get those started."}
	]

	DialogueManager.start_multi_dialogue(
		final_dialogue,
		{"Marya": MARYA_PORTRAIT, "Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	GameManager.player_controls_locked = false


func finish_wrong_coffee_order(player_correct: bool, tina_correct: bool) -> void:
	GameManager.set_meta("cafe_order_complete", true)
	GameManager.set_meta("cafe_order_ready", false)
	GameManager.set_meta("cafe_order_phase", "complete")
	GameManager.set_meta("cafe_tina_followup_ready", true)

	if is_instance_valid(coffee_menu_layer):
		coffee_menu_layer.queue_free()

	coffee_menu_layer = null
	coffee_menu_panel = null
	coffee_menu_status = null
	coffee_order_open = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.player_controls_locked = true

	var wrong_dialogue: Array[Dictionary]

	if not player_correct and tina_correct:
		wrong_dialogue = [
			{"speaker": "Player", "text": "Oh I changed my mind the last second hehe."},
			{"speaker": "Tina", "text": "Oh... okay?"},
			{"speaker": "Marya", "text": "Alright. I'll get those drinks ready."}
		]
	elif player_correct and not tina_correct:
		wrong_dialogue = [
			{"speaker": "Player", "text": "Oh woops, sorry. I might've misheard what you said."},
			{"speaker": "Tina", "text": "You might have. I was pretty specific."},
			{"speaker": "Marya", "text": "Alright. I'll get those drinks ready."}
		]
	else:
		wrong_dialogue = [
			{"speaker": "Player", "text": "I think the sleepless nights because of projects are getting to me hehe my bad"},
			{"speaker": "Tina", "text": "...Let's just get the drinks."},
			{"speaker": "Marya", "text": "Alright. I'll get those drinks ready."}
		]

	DialogueManager.start_multi_dialogue(
		wrong_dialogue,
		{"Tina": TINA_PORTRAIT, "Marya": MARYA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	GameManager.player_controls_locked = false


func start_friends_post_order_dialogue() -> void:
	if DialogueManager.is_active or bool(GameManager.get_meta("cafe_friends_followup_running", false)):
		return

	GameManager.set_meta("cafe_friends_followup_running", true)
	GameManager.set_meta("cafe_friends_followup_ready", false)
	GameManager.set_meta("cafe_order_phase", "friends_followup")
	GameManager.set_meta("cafe_quest_phase", "post_order_conversation")
	GameManager.player_controls_locked = true

	var dialogue := [
		{"speaker": "Player", "text": "Alright, the drinks should be ready soon."},
		{"speaker": "Kerwin", "text": "This was a good idea. I needed a break after that challenge."},
		{"speaker": "Kairi", "text": "Same. It's nice just sitting around with everyone."},
		{"speaker": "Janssen", "text": "We should do this more often. Not every conversation has to be about assignments."},
		{"speaker": "Nathaly", "text": "Although knowing us, we'll probably start talking about projects again."},
		{"speaker": "Player", "text": "You guys really do make it hard to forget about school."},
		{"speaker": "Kerwin", "text": "Are you okay, though? You look a little off."},
		{"speaker": "Player", "text": "Yeah... I think so. It's just..."},
		{"speaker": "Player", "text": "My head is starting to hurt."},
		{"speaker": "Kairi", "text": "Maybe you really should get some rest."}
	]

	DialogueManager.start_multi_dialogue(
		dialogue,
		{"Kairi": KAIRI_PORTRAIT, "Kerwin": KERWIN_PORTRAIT, "Janssen": JANSSEN_PORTRAIT, "Nathaly": NATHALY_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	await play_tina_alarm()
	GameManager.returning_from_tina_dream = true
	GameManager.set_meta("cafe_quest_phase", "returned_home")
	GameManager.set_meta("cafe_friends_followup_running", false)
	GameManager.set_meta("cafe_order_phase", "returned_home")
	GameManager.player_controls_locked = true
	await FadeManager.change_scene_with_fade("res://scenes/main_level_scenes/house_game_level.tscn")


func start_tina_post_order_dialogue() -> void:
	if DialogueManager.is_active or bool(GameManager.get_meta("cafe_tina_followup_running", false)):
		return

	GameManager.set_meta("cafe_tina_followup_running", true)
	GameManager.set_meta("cafe_tina_followup_ready", false)
	GameManager.set_meta("cafe_order_phase", "tina_followup")
	GameManager.set_meta("cafe_quest_phase", "post_order_conversation")
	GameManager.player_controls_locked = true

	var tina_dialogue := [
		{"speaker": "Player", "text": "Hey Tina, the drinks should be ready soon."},
		{"speaker": "Tina", "text": "Nice. Honestly, I'm glad we got to sit down and catch up like this."},
		{"speaker": "Player", "text": "Yeah. It's been a while since we actually had time to talk."},
		{"speaker": "Tina", "text": "Maybe we should do this again sometime, without having to rush between classes."},
		{"speaker": "Player", "text": "I'd like that."},
		{"speaker": "Tina", "text": "Are you okay? You look a little distracted."},
		{"speaker": "Player", "text": "Yeah... I think so. It's just..."},
		{"speaker": "Player", "text": "My head is starting to hurt."}
	]

	DialogueManager.start_multi_dialogue(
		tina_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	await play_tina_alarm()

	GameManager.set_meta("cafe_quest_phase", "returned_home")
	# Match the school hallway "go home" route: return to the house scene
	# and let the existing GameManager dream-return sequence continue there.
	GameManager.returning_from_tina_dream = true
	GameManager.set_meta("cafe_tina_followup_running", false)
	GameManager.set_meta("cafe_order_phase", "returned_home")
	GameManager.player_controls_locked = true

	await FadeManager.change_scene_with_fade(
        "res://scenes/main_level_scenes/house_game_level.tscn"
	)


func play_tina_alarm() -> void:
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


func close_coffee_menu_and_ask_tina() -> void:
	if not coffee_order_open:
		return

	if is_instance_valid(coffee_menu_layer):
		coffee_menu_layer.queue_free()

	coffee_menu_layer = null
	coffee_menu_panel = null
	coffee_menu_status = null
	coffee_order_open = false
	coffee_order_player_choice = ""
	coffee_order_tina_choice = ""
	coffee_order_current_target = "player"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	GameManager.set_meta("cafe_order_phase", "ask_tina_again")
	GameManager.set_meta("cafe_order_ready", true)
	GameManager.player_controls_locked = true

	var ask_tina_dialogue := [
		{"speaker": "Player", "text": "Wait, I should make sure I got your order right. What did you want again?"},
		{"speaker": "Tina", "text": "I told you. A grande iced caramel macchiato, oat milk, extra vanilla, two pumps of caramel, one pump of hazelnut, extra caramel drizzle, cold foam, cinnamon powder, light ice, and an extra espresso shot."},
		{"speaker": "Player", "text": "Right. Got it. I'll ask Marya again."},
		{"speaker": "Tina", "text": "Take your time."}
	]

	DialogueManager.start_multi_dialogue(
		ask_tina_dialogue,
		{"Tina": TINA_PORTRAIT},
		PLAYER_PORTRAIT
	)
	await DialogueManager.dialogue_finished

	GameManager.player_controls_locked = false


func coffee_order_status_reset() -> void:
	coffee_order_player_choice = ""
	coffee_order_tina_choice = ""
	coffee_order_current_target = "player"
	GameManager.set_meta("cafe_order_phase", "choose_drinks")


func show_cinematic_bars() -> void:
	if not is_instance_valid(top_bar):
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(top_bar, "modulate:a", 1.0, 0.35)
	tween.tween_property(bottom_bar, "modulate:a", 1.0, 0.35)
	await tween.finished


func hide_cinematic_bars() -> void:
	if not is_instance_valid(top_bar):
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(top_bar, "modulate:a", 0.0, 0.35)
	tween.tween_property(bottom_bar, "modulate:a", 0.0, 0.35)
	await tween.finished

	if is_instance_valid(cinematic_ui):
		cinematic_ui.queue_free()


func face_character_toward_character(character: Node, target: Node) -> void:
	if character == null or target == null:
		return

	var direction: Vector2 = target.global_position - character.global_position
	if direction.length_squared() <= 0.01:
		return

	var animation_name := get_idle_animation_name(direction.normalized())
	stop_character_animation(character, animation_name)


func get_walk_animation_name(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "walk_right" if direction.x >= 0.0 else "walk_left"
	return "walk_down" if direction.y >= 0.0 else "walk_up"


func get_idle_animation_name(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "idle_right" if direction.x >= 0.0 else "idle_left"
	return "idle_down" if direction.y >= 0.0 else "idle_up"


func play_character_animation(character: Node, animation_name: String) -> void:
	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.animation = StringName(animation_name)
		sprite.speed_scale = 1.0
		sprite.play()


func stop_character_animation(character: Node, animation_name: String) -> void:
	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	sprite.stop()
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.animation = StringName(animation_name)


func set_cursor_hidden() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
