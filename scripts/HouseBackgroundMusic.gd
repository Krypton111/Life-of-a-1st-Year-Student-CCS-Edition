extends AudioStreamPlayer

const HOUSE_MUSIC_PATH := "res://GAME ASSETS_/Misc/Music/house.mp3"
const NORMAL_VOLUME_DB := -8.0

func _ready() -> void:
	add_to_group("house_background_music")
	volume_db = NORMAL_VOLUME_DB
	var music := load(HOUSE_MUSIC_PATH) as AudioStreamMP3
	if music == null:
		push_warning("House background music could not be loaded: " + HOUSE_MUSIC_PATH)
		return
	music.loop = true
	stream = music
	play()
