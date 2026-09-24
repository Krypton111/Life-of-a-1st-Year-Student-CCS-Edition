extends CharacterBody2D

@export var walk_speed: float = 150.0
@export var sprint_speed: float = 220.0
@export var sprint_animation_speed: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var footstep_sound = $FootstepSound

var footstep_timer := 0.0

var walk_step_interval := 0.45
var run_step_interval := 0.28

var last_direction: Vector2 = Vector2.DOWN
var nearby_npcs: Array = []

func _ready() -> void:
	# Normal gameplay does not use the mouse cursor. Interactive UI systems
	# (dialogue, challenges, choices, and pause menu) explicitly show it.
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameManager.player_controls_locked = false

	if GameManager.has_challenge_return_position:
		global_position = GameManager.get_challenge_return_position()
		GameManager.clear_challenge_position()

	interaction_zone.body_entered.connect(_on_zone_body_entered)
	interaction_zone.body_exited.connect(_on_zone_body_exited)

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	if GameManager.has_return_position:
		global_position = GameManager.get_player_return_position()
		GameManager.clear_return_position()

func _physics_process(_delta: float) -> void:
	if GameManager.player_controls_locked:
		velocity = Vector2.ZERO
		animated_sprite.pause()
		footstep_timer = 0.0
		if footstep_sound.playing:
			footstep_sound.stop()
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	var is_sprinting = Input.is_action_pressed("sprint") and direction != Vector2.ZERO
	var current_speed = sprint_speed if is_sprinting else walk_speed

	velocity = direction * current_speed
	move_and_slide()

	play_animation(direction)

	if is_sprinting:
		animated_sprite.speed_scale = sprint_animation_speed
	else:
		animated_sprite.speed_scale = 1.0

	if direction != Vector2.ZERO:
		footstep_timer -= _delta

		if footstep_timer <= 0:
			footstep_sound.play()

			if is_sprinting:
				footstep_timer = run_step_interval
			else:
				footstep_timer = walk_step_interval
	else:
		footstep_timer = 0.0

func play_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		var idle_name = "idle_" + _get_direction_name(last_direction)
		animated_sprite.play(idle_name)
	else:
		last_direction = dir.normalized()

		var walk_name = "walk_" + _get_direction_name(last_direction)
		animated_sprite.play(walk_name)


func _get_direction_name(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "right" if vec.x > 0 else "left"
	else:
		return "down" if vec.y > 0 else "up"


func _input(event):
	if GameManager.player_controls_locked:
		return

	if DialogueManager.is_active:
		return

	if event.is_action_pressed("interact"):
		_try_interact()


func _try_interact():
	if GameManager.player_controls_locked:
		return

	if DialogueManager.is_active:
		return

	# HOUSE / OBJECT INTERACTABLES
	# These are checked first so objects such as the baon can still be picked up.
	var interactable := get_nearest_house_interactable()

	if interactable != null:
		if interactable.has_method("interact"):
			interactable.interact()
			return

	if nearby_npcs.size() > 0:
		var npc = nearby_npcs[0]

		# Face both characters toward each other before starting any NPC interaction.
		face_character_toward_character(npc, self)
		face_character_toward_character(self, npc)

		if npc.has_method("interact"):
			npc.interact()


func get_nearest_house_interactable() -> Node2D:
	var nearest_interactable: Node2D = null
	var nearest_distance: float = INF

	for node in get_tree().get_nodes_in_group("house_interactable"):
		var interactable := node as Node2D

		if interactable == null:
			continue

		if not interactable.is_inside_tree():
			continue

		if not interactable.visible:
			continue

		var distance := interactable.global_position.distance_to(global_position)

		if interactable.has_method("can_interact"):
			if not interactable.can_interact(self):
				continue
		elif distance > 50.0:
			continue

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_interactable = interactable

	return nearest_interactable


func _on_zone_body_entered(body):
	if body.is_in_group("npc"):
		if not nearby_npcs.has(body):
			nearby_npcs.append(body)


func _on_zone_body_exited(body):
	if body.is_in_group("npc"):
		nearby_npcs.erase(body)


func lock_controls() -> void:
	GameManager.player_controls_locked = true
	velocity = Vector2.ZERO
	animated_sprite.pause()

	if footstep_sound.playing:
		footstep_sound.stop()


func unlock_controls() -> void:
	GameManager.player_controls_locked = false


func face_character_toward_character(character: CharacterBody2D, target_character: CharacterBody2D) -> void:
	if character == null or target_character == null:
		return

	var difference := target_character.global_position - character.global_position
	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var animation_name := "idle_down"
	if abs(difference.x) > abs(difference.y):
		animation_name = "idle_right" if difference.x > 0.0 else "idle_left"
	else:
		animation_name = "idle_down" if difference.y > 0.0 else "idle_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
		sprite.pause()
