extends Node

var fade_layer: CanvasLayer
var fade_rect: ColorRect


func _ready() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 1000
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.modulate.a = 0.0
	fade_rect.visible = false

	fade_layer.add_child(fade_rect)


# --------------------------------------------------
# FADE OUT: SCREEN BECOMES BLACK
# --------------------------------------------------
func fade_out(duration: float = 1.0) -> void:
	if not is_instance_valid(fade_rect):
		return

	fade_layer.layer = 11000
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		duration
	)

	await tween.finished


# --------------------------------------------------
# FADE IN: BLACK SCREEN DISAPPEARS
# --------------------------------------------------
func fade_in(duration: float = 1.0) -> void:
	if not is_instance_valid(fade_rect):
		return

	fade_layer.layer = 11000
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		0.0,
		duration
	)

	await tween.finished

	fade_rect.visible = false
	fade_layer.layer = 1000


# --------------------------------------------------
# FADE OUT MUSIC
# --------------------------------------------------
func fade_music_out(duration: float = 1.0) -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	var music := current_scene.get_node_or_null(
        "BackgroundMusic"
	) as AudioStreamPlayer

	if music == null or not music.playing:
		return

	var original_volume := music.volume_db

	var tween := create_tween()
	tween.tween_property(
		music,
		"volume_db",
		-80.0,
		duration
	)

	await tween.finished

	if is_instance_valid(music):
		music.stop()
		music.volume_db = original_volume


# --------------------------------------------------
# CHANGE SCENE WITH FADE
# --------------------------------------------------
func change_scene_with_fade(scene_path: String) -> void:
	if not is_instance_valid(fade_rect):
		get_tree().change_scene_to_file(scene_path)
		return

	fade_layer.layer = 11000
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var current_scene := get_tree().current_scene
	var music: AudioStreamPlayer = null

	if current_scene != null:
		music = current_scene.get_node_or_null(
            "BackgroundMusic"
		) as AudioStreamPlayer

	var screen_tween := create_tween()
	screen_tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		1.0
	)

	var music_tween: Tween = null

	if music != null and music.playing:
		music_tween = create_tween()
		music_tween.tween_property(
			music,
			"volume_db",
			-80.0,
			1.0
		)

	await screen_tween.finished

	if music_tween != null:
		await music_tween.finished

	if is_instance_valid(music):
		music.stop()

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Failed to change scene: " + scene_path)
		fade_rect.modulate.a = 0.0
		fade_rect.visible = false
		fade_layer.layer = 1000
		return

	await get_tree().scene_changed

	await fade_in(1.0)

	# Recover player controls when returning from classroom challenges.
	var challenge_return_scenes := [
		"res://scenes/main_level_scenes/comlab202.tscn",
		"res://scenes/main_level_scenes/mac_lab.tscn",
        "res://scenes/main_level_scenes/Lecture Room.tscn"
	]

	if scene_path in challenge_return_scenes:
		await restore_player_after_challenge_return()


# --------------------------------------------------
# RESTORE PLAYER AFTER CHALLENGE
# --------------------------------------------------
func restore_player_after_challenge_return() -> void:
	var player: CharacterBody2D = null

	for _attempt in range(5):
		await get_tree().process_frame

		player = get_tree().get_first_node_in_group(
            "player"
		) as CharacterBody2D

		if player != null:
			break

	if player == null:
		push_error(
            "Challenge return recovery failed: Player not found in group 'player'."
		)
		return

	GameManager.player_controls_locked = false

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.set_process(true)
	player.set_physics_process(true)
	player.velocity = Vector2.ZERO

	if player.has_method("unlock_controls"):
		player.unlock_controls()

	print(
		"Challenge return recovery completed for: ",
		get_tree().current_scene.scene_file_path
	)
