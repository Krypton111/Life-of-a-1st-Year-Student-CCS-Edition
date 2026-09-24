extends Node


func start_challenge(challenge_type):

	match challenge_type:

		"programming":
			get_tree().change_scene_to_file(
				"res://scenes/challenges_scenes/ProgrammingChallenge.tscn"
			)

		"drawing":
			get_tree().change_scene_to_file(
				"res://scenes/challenges_scenes/DrawingChallenge.tscn"
			)

		"math":
			get_tree().change_scene_to_file(
				"res://scenes/challenges_scenes/MathChallenge.tscn"
			)
