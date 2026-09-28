extends Node

const PLAYER_PORTRAIT = preload("res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png")
const TINA_PORTRAIT = preload("res://GAME ASSETS_/School (University of Continuous Help System Prime)/Character Sprites/8-bit Sprite Models/Tina (dating binubully ni mc na ngayon bespren)/tina.png")

@onready var player: CharacterBody2D = $"../Player"
@onready var tina: CharacterBody2D = $"../Tina"
@onready var gelo: CharacterBody2D = $"../NPC"
@onready var kairi: CharacterBody2D = $"../Kairi"
@onready var kerwin: CharacterBody2D = $"../Kerwin"
@onready var janssen: CharacterBody2D = $"../Janssen"
@onready var nathaly: CharacterBody2D = $"../Nathaly"
@onready var camera: Camera2D = $"../Player/Camera2D"

var cinematic_ui: CanvasLayer
var top_bar: ColorRect
var bottom_bar: ColorRect
var entry_running := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# The hallway controller sets cafe_route immediately before changing
	# scenes. Do not depend on tina_hallway_encounter_done here because the
	# scene transition can happen before the hallway encounter function gets
	# a chance to set that flag after its awaited call returns.
	if GameManager.cafe_route != "tina" and GameManager.cafe_route != "friends":
		return

	if GameManager.cafe_route == "tina":
		setup_cafe_cast_for_tina()
	elif GameManager.cafe_route == "friends":
		setup_cafe_cast_for_friends()

	GameManager.player_controls_locked = true
	entry_running = true

	# The friends route currently only needs the group to be present.
	# Leave the existing Tina cinematic untouched for the Tina route.
	if GameManager.cafe_route == "friends":
		entry_running = false
		GameManager.player_controls_locked = false
		return

	setup_cinematic_ui()
	set_cursor_hidden()
	await get_tree().process_frame
	await play_cafe_entry()
	entry_running = false
	GameManager.player_controls_locked = true


func setup_cafe_cast_for_tina() -> void:
	# Tina route: Tina remains, while Gelo and all friends are removed
	# from the playable cafe scene.
	tina.visible = true
	gelo.visible = false
	kairi.visible = false
	kerwin.visible = false
	janssen.visible = false
	nathaly.visible = false


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


func setup_cinematic_ui() -> void:
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
	cinematic_ui.add_child(top_bar)

	bottom_bar = ColorRect.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.color = Color.BLACK
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.position = Vector2(0, -115)
	bottom_bar.size = Vector2(0, 115)
	cinematic_ui.add_child(bottom_bar)

	top_bar.modulate.a = 0.0
	bottom_bar.modulate.a = 0.0


func play_cafe_entry() -> void:
	# The two arrive together from the left side of the cafe entrance.
	# The target is intentionally modest so the camera frames both characters
	# without becoming excessively zoomed in.
	var target_player := player.global_position + Vector2(150.0, 0.0)
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

	await hide_cinematic_bars()
	camera.zoom = Vector2.ONE


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
