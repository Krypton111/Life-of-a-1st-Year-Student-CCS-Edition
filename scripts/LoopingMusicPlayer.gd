extends AudioStreamPlayer

func _ready() -> void:
	if stream is AudioStreamMP3:
		var music := stream as AudioStreamMP3
		music.loop = true

	play()
