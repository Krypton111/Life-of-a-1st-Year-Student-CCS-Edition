extends Area2D

var player_inside: bool = false
var transitioning: bool = false

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
		if not GameManager.computer_unlocked:
			print("You need to talk to Miss Joyz first.")
			return

		if GameManager.quiz_completed:
			print("You have already completed this challenge.")
			return

		start_programming_challenge()

func start_programming_challenge() -> void:
	if transitioning:
		return

	transitioning = true
	GameManager.player_controls_locked = true

	var player = get_tree().get_first_node_in_group("player")

	if player:
		GameManager.save_challenge_position(player.global_position)

	await FadeManager.change_scene_with_fade(
		"res://scenes/challenge_scenes/comlab_challenge.tscn"
	)
