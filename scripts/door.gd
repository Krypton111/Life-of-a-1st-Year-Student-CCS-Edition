extends Area2D

@export var room_name: String = ""
@export_file("*.tscn") var destination_scene: String = ""

@export var lecture_bully_interruption: bool = false
@export var requires_baon: bool = false
@export var no_baon_message: String = "I need to get my baon."

var player_inside := false
var transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false


func _process(_delta: float) -> void:
	if not player_inside:
		return

	if transitioning:
		return

	if DialogueManager.is_active:
		return

	if GameManager.player_controls_locked:
		return

	if Input.is_action_just_pressed("interact"):
		enter_room()


func enter_room() -> void:
	if transitioning:
		return

	# This only applies to doors that have Requires Baon enabled.
	if requires_baon and not GameManager.has_baon:
		print(no_baon_message)
		return

	if not can_enter():
		print(room_name, " is currently locked.")
		return
		
	# This only applies to the Lecture Room door when the interruption is enabled.
	if lecture_bully_interruption and not GameManager.lecture_bully_interruption_done:
		var interruption := get_tree().current_scene.get_node_or_null(
			"LectureRoomBullyInterruption"
		)

		if interruption != null and interruption.has_method("start_interruption"):
			transitioning = true
			await interruption.start_interruption()
			transitioning = false
			return

		print("WARNING: LectureRoomBullyInterruption was not found in School.tscn.")
		return
	if destination_scene == "":
		print("ERROR: No destination scene assigned!")
		return

	var player = get_tree().get_first_node_in_group("player")

	if player and destination_scene != "res://scenes/School.tscn":
		GameManager.save_player_position(player.global_position)

	transitioning = true

	await FadeManager.change_scene_with_fade(destination_scene)


func can_enter() -> bool:
	match room_name:
		"ComLab":
			if GameManager.quiz_completed and not GameManager.bullies_encounter_done:
				return false
			return true

		"MacLab":
			return GameManager.quiz_completed

		"LectureRoom":
			return GameManager.maclab_challenge_completed

		_:
			return true
