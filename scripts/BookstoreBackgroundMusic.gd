extends AudioStreamPlayer

const BOOKSTORE_MUSIC_PATH := "res://GAME ASSETS_/Misc/Music/cutscene music.mp3"
const NORMAL_VOLUME_DB := -8.0

func _ready() -> void:
	add_to_group("bookstore_background_music")
	volume_db = NORMAL_VOLUME_DB

	var music := load(BOOKSTORE_MUSIC_PATH) as AudioStreamMP3
	if music == null:
		push_warning("Bookstore background music could not be loaded: " + BOOKSTORE_MUSIC_PATH)
		return

	music.loop = true
	stream = music
	play()
