extends Node

var has_baon := false
var house_opening_completed := false
var lecture_bully_interruption_done := false

var quiz_completed := false
var maclab_challenge_completed := false
var lecture_challenge_completed := false
var tina_hallway_encounter_done := false

# Challenge performance percentages. These are stored as 0.0-100.0 so each
# challenge can have a different maximum score.
var comlab_performance_score: float = -1.0
var maclab_performance_score: float = -1.0
var lecture_performance_score: float = -1.0

var friends_encounter_done := false
var friends_bookstore_choice := 0

var miss_joyz_first_dialogue_done := false
var miss_joyz_second_dialogue_done := false

var sir_mico_dialogue_done := false
var sir_mico_second_dialogue_done := false

var sir_charles_dialogue_done := false
var sir_charles_second_dialogue_done := false

var computer_unlocked := false
var mac_computer_unlocked := false
var lecture_computer_unlocked := false

var player_controls_locked := false

var room_return_position := Vector2.ZERO
var has_room_return_position := false

var challenge_return_position := Vector2.ZERO
var has_challenge_return_position := false


func save_room_position(position: Vector2) -> void:
	room_return_position = position
	has_room_return_position = true


func get_room_return_position() -> Vector2:
	return room_return_position


func clear_room_position() -> void:
	has_room_return_position = false


func save_challenge_position(position: Vector2) -> void:
	challenge_return_position = position
	has_challenge_return_position = true


func get_challenge_return_position() -> Vector2:
	return challenge_return_position


func clear_challenge_position() -> void:
	has_challenge_return_position = false


var has_return_position := false
var return_position := Vector2.ZERO


func save_player_position(position: Vector2) -> void:
	return_position = position
	has_return_position = true


func get_player_return_position() -> Vector2:
	return return_position


func clear_return_position() -> void:
	has_return_position = false

#BULLY ENCOUNTER
var bullies_encounter_done := false

#BOOKSTORE
var bookstore_started := false

var bookstore_yellow_pad := false
var bookstore_ballpens := 0
var bookstore_correction_tape := false
var bookstore_discrete_math_book := false

var bookstore_talked_to_kairi := false
var bookstore_talked_to_kerwin := false
var bookstore_talked_to_janssen := false
var bookstore_talked_to_nathaly := false

var bookstore_talked_to_ate_libro := false
var bookstore_talked_to_kuya_libro := false

var bookstore_talked_to_friends := false
var bookstore_completed := false

var bookstore_return_event_pending := false
