extends CharacterBody2D


# ============================================================
# MOVEMENT
# ============================================================

@export var walk_speed: float = 150.0
@export var sprint_speed: float = 220.0
@export var sprint_animation_speed: float = 2.0


# ============================================================
# PLAYER NODES
# ============================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var footstep_sound = $FootstepSound


# ============================================================
# PLAYER VARIABLES
# ============================================================

var footstep_timer: float = 0.0

var walk_step_interval: float = 0.45
var run_step_interval: float = 0.28

var last_direction: Vector2 = Vector2.DOWN

var nearby_npcs: Array = []


# ============================================================
# QUEST POINTER
# ============================================================

var quest_pointer: Node2D = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# The player must obey the global SceneTree pause.
	# PROCESS_MODE_PAUSABLE means _physics_process() stops while
	# get_tree().paused is true, but resumes normally afterward.
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Player stays at normal world layer.
	z_index = 0

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Do not forcibly unlock controls here. During save loading, the scene and
	# SaveManager reconstruct the gameplay state after _ready(). Forcing this
	# flag to false here can overwrite a restored lock and cause load-state
	# controllers/dialogue sequences to become inconsistent.


	# --------------------------------------------------------
	# RETURN FROM CHALLENGE
	# --------------------------------------------------------

	if GameManager.has_challenge_return_position:

		global_position = (
			GameManager.get_challenge_return_position()
		)

		GameManager.clear_challenge_position()


	# --------------------------------------------------------
	# INTERACTION ZONE
	# --------------------------------------------------------

	if interaction_zone != null:

		interaction_zone.body_entered.connect(
			_on_zone_body_entered
		)

		interaction_zone.body_exited.connect(
			_on_zone_body_exited
		)


	# --------------------------------------------------------
	# NORMAL RETURN POSITION
	# --------------------------------------------------------

	if GameManager.has_return_position:

		global_position = (
			GameManager.get_player_return_position()
		)

		GameManager.clear_return_position()


	# --------------------------------------------------------
	# QUEST POINTER
	# --------------------------------------------------------

	_create_quest_pointer()


# ============================================================
# CREATE QUEST POINTER
# ============================================================

func _create_quest_pointer() -> void:

	# Prevent duplicate pointer creation.
	if is_instance_valid(quest_pointer):
		return


	var pointer_script: Script = load(
		"res://scripts/QuestPointer.gd"
	)


	if pointer_script == null:

		push_error(
			"QuestPointer.gd could not be found at "
			+ "res://scripts/QuestPointer.gd"
		)

		return


	# Create the pointer entirely through code.
	var pointer := Node2D.new()

	pointer.name = "QuestPointer"

	pointer.set_script(pointer_script)

	pointer.z_index = 1000

	add_child(pointer)

	quest_pointer = pointer


# ============================================================
# PHYSICS
# ============================================================

func _physics_process(delta: float) -> void:

	# --------------------------------------------------------
	# CONTROLS LOCKED
	# --------------------------------------------------------

	if GameManager.player_controls_locked:

		velocity = Vector2.ZERO

		animated_sprite.pause()

		footstep_timer = 0.0

		if footstep_sound.playing:

			footstep_sound.stop()

		return


	# --------------------------------------------------------
	# MOVEMENT INPUT
	# --------------------------------------------------------

	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)


	# --------------------------------------------------------
	# SPRINT
	# --------------------------------------------------------

	var is_sprinting: bool = (
		Input.is_action_pressed("sprint")
		and direction != Vector2.ZERO
	)


	var current_speed: float = (
		sprint_speed
		if is_sprinting
		else walk_speed
	)


	velocity = direction * current_speed

	move_and_slide()


	# --------------------------------------------------------
	# ANIMATION
	# --------------------------------------------------------

	play_animation(direction)


	if is_sprinting:

		animated_sprite.speed_scale = (
			sprint_animation_speed
		)

	else:

		animated_sprite.speed_scale = 1.0


	# --------------------------------------------------------
	# FOOTSTEPS
	# --------------------------------------------------------

	if direction != Vector2.ZERO:

		footstep_timer -= delta

		if footstep_timer <= 0.0:

			footstep_sound.play()

			if is_sprinting:

				footstep_timer = (
					run_step_interval
				)

			else:

				footstep_timer = (
					walk_step_interval
				)

	else:

		footstep_timer = 0.0


# ============================================================
# PLAYER ANIMATION
# ============================================================

func play_animation(dir: Vector2) -> void:

	if dir == Vector2.ZERO:

		var idle_name: String = (
			"idle_"
			+ _get_direction_name(last_direction)
		)

		if animated_sprite.sprite_frames.has_animation(
			idle_name
		):

			animated_sprite.play(idle_name)

	else:

		last_direction = dir.normalized()

		var walk_name: String = (
			"walk_"
			+ _get_direction_name(last_direction)
		)

		if animated_sprite.sprite_frames.has_animation(
			walk_name
		):

			animated_sprite.play(walk_name)


# ============================================================
# GET DIRECTION NAME
# ============================================================

func _get_direction_name(vec: Vector2) -> String:

	if abs(vec.x) > abs(vec.y):

		return (
			"right"
			if vec.x > 0.0
			else "left"
		)

	else:

		return (
			"down"
			if vec.y > 0.0
			else "up"
		)


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:

	if GameManager.player_controls_locked:
		return

	if DialogueManager.is_active:
		return

	if event.is_action_pressed("interact"):

		_try_interact()


# ============================================================
# TRY INTERACT
# ============================================================

func _try_interact() -> void:

	if GameManager.player_controls_locked:
		return

	if DialogueManager.is_active:
		return


	# --------------------------------------------------------
	# HOUSE / OBJECT INTERACTABLES
	# --------------------------------------------------------

	var interactable: Node2D = (
		get_nearest_house_interactable()
	)


	if interactable != null:

		if interactable.has_method("interact"):

			interactable.interact()

			return


	# --------------------------------------------------------
	# NPC INTERACTION
	# --------------------------------------------------------

	if nearby_npcs.size() > 0:

		var npc: Node = nearby_npcs[0]


		# Face NPC toward player.
		face_character_toward_character(
			npc,
			self
		)


		# Face player toward NPC.
		face_character_toward_character(
			self,
			npc
		)


		if npc.has_method("interact"):

			npc.interact()


# ============================================================
# HOUSE INTERACTABLE SEARCH
# ============================================================

func get_nearest_house_interactable() -> Node2D:

	var nearest_interactable: Node2D = null

	var nearest_distance: float = INF


	for node in get_tree().get_nodes_in_group(
		"house_interactable"
	):

		var interactable: Node2D = (
			node as Node2D
		)


		if interactable == null:
			continue


		if not interactable.is_inside_tree():
			continue


		if not interactable.visible:
			continue


		var distance: float = (
			interactable.global_position.distance_to(
				global_position
			)
		)


		if interactable.has_method(
			"can_interact"
		):

			if not interactable.can_interact(self):

				continue

		elif distance > 50.0:

			continue


		if distance < nearest_distance:

			nearest_distance = distance

			nearest_interactable = (
				interactable
			)


	return nearest_interactable


# ============================================================
# NPC DETECTION
# ============================================================

func _on_zone_body_entered(body: Node) -> void:

	if body.is_in_group("npc"):

		if not nearby_npcs.has(body):

			nearby_npcs.append(body)


# ============================================================

func _on_zone_body_exited(body: Node) -> void:

	if body.is_in_group("npc"):

		nearby_npcs.erase(body)


# ============================================================
# PLAYER CONTROL
# ============================================================

func lock_controls() -> void:

	GameManager.player_controls_locked = true

	velocity = Vector2.ZERO

	animated_sprite.pause()


	if footstep_sound.playing:

		footstep_sound.stop()


# ============================================================

func unlock_controls() -> void:

	GameManager.player_controls_locked = false


# ============================================================
# CHARACTER FACING
# ============================================================

func face_character_toward_character(
	character: CharacterBody2D,
	target_character: CharacterBody2D
) -> void:

	if character == null:
		return

	if target_character == null:
		return


	var difference: Vector2 = (
		target_character.global_position
		- character.global_position
	)


	if difference.length() <= 0.1:
		return


	var sprite: AnimatedSprite2D = (
		character.get_node_or_null(
			"AnimatedSprite2D"
		)
		as AnimatedSprite2D
	)


	if sprite == null:
		return


	var animation_name: String = (
		"idle_down"
	)


	if abs(difference.x) > abs(difference.y):

		animation_name = (
			"idle_right"
			if difference.x > 0.0
			else "idle_left"
		)

	else:

		animation_name = (
			"idle_down"
			if difference.y > 0.0
			else "idle_up"
		)


	if sprite.sprite_frames.has_animation(
		animation_name
	):

		sprite.play(animation_name)

		sprite.pause()
