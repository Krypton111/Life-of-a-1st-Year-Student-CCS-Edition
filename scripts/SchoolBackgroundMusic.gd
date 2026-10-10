extends AudioStreamPlayer

const SCHOOL_MUSIC_PATH := "res://GAME ASSETS_/Misc/Music/school hallway.mp3"
const NORMAL_VOLUME_DB := -8.0
const FADE_DURATION := 0.6

var music_tween: Tween
var special_music_active := false


func _ready() -> void:
	add_to_group("school_background_music")
	volume_db = NORMAL_VOLUME_DB

	var music := load(SCHOOL_MUSIC_PATH) as AudioStreamMP3
	if music == null:
		push_warning("School hallway music could not be loaded: " + SCHOOL_MUSIC_PATH)
		return

	music.loop = true
	stream = music
	play()


func _process(_delta: float) -> void:
	var special_is_playing := false
	for node in get_tree().get_nodes_in_group("school_special_music"):
		var special_player := node as AudioStreamPlayer
		if special_player != null and special_player.playing:
			special_is_playing = true
			break

	if special_is_playing == special_music_active:
		return

	special_music_active = special_is_playing
	_fade_music_to(-80.0 if special_music_active else NORMAL_VOLUME_DB)


func _fade_music_to(target_db: float) -> void:
	if music_tween != null and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(self, "volume_db", target_db, FADE_DURATION)
