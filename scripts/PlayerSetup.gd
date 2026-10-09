extends Node

# Temporary profile selection storage.
# Gameplay scripts can read these values when player identity is implemented.
var player_name: String = ""
var player_gender: String = ""

func clear_profile() -> void:
	player_name = ""
	player_gender = ""
