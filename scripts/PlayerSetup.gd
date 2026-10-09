extends Node

# Temporary profile selection storage.
# Gameplay scripts can read these values when player identity is implemented.
var player_name: String = ""
var player_gender: String = ""

const MALE_PORTRAIT_PATH := "res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Male-MC.png"
const FEMALE_PORTRAIT_PATH := "res://GAME ASSETS_/House+MC Room (inside only)/Character Sprites/32-bit Character Models/MC/Female-MC.png"

func get_player_portrait() -> Texture2D:
	var portrait_path := MALE_PORTRAIT_PATH if player_gender.to_lower() == "male" else FEMALE_PORTRAIT_PATH
	if not ResourceLoader.exists(portrait_path):
		push_warning("Player portrait could not be found: " + portrait_path)
		return null
	return load(portrait_path) as Texture2D

func get_display_name() -> String:
	var cleaned_name := player_name.strip_edges()
	return cleaned_name if not cleaned_name.is_empty() else "Player"

func clear_profile() -> void:
	player_name = ""
	player_gender = ""
