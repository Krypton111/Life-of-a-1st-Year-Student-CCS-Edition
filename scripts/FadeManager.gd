extends Node

var fade_layer: CanvasLayer
var fade_rect: ColorRect


func _ready():
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 1000
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.modulate.a = 0.0

	fade_layer.add_child(fade_rect)

func fade_out(duration: float = 1.0):
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

func fade_in(duration: float = 1.0):
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


func fade_music_out(duration: float = 1.0):
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	var music := current_scene.get_node_or_null("BackgroundMusic") as AudioStreamPlayer

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

func change_scene_with_fade(scene_path: String):
	var current_scene := get_tree().current_scene
	var music: AudioStreamPlayer = null

	if current_scene != null:
		music = current_scene.get_node_or_null(
			"BackgroundMusic"
		) as AudioStreamPlayer

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

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

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in(1.0)
